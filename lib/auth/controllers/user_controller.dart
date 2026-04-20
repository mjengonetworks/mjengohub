// lib/auth/controllers/user_controller.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' show Platform;

import '../../services/base_service.dart';
import '../models/user_model.dart';

class UserController extends BaseService {
  // Reactive variables
  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);
  final RxBool _isLoading = false.obs;
  final RxBool _isAuthenticated = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxBool _isInitialized = false.obs;

  // Phone authentication variables
  final RxString _verificationId = ''.obs;
  final RxInt _resendToken = 0.obs;
  final RxBool _codeSent = false.obs;

  final RxBool _isNewRegistration = false.obs;

  // ── 2FA / MFA state ──────────────────────────────────────────────────────────
  final RxBool _mfaChallengeActive = false.obs;
  final Rx<MultiFactorResolver?> _mfaResolver = Rx<MultiFactorResolver?>(null);
  final RxString _mfaChallengeVerificationId = ''.obs;
  final RxBool _mfaEnrolled = false.obs;
  final RxString _mfaEnrollVerificationId = ''.obs;
  final RxList<MultiFactorInfo> _enrolledFactors = <MultiFactorInfo>[].obs;

  // Getters – existing
  UserModel? get currentUser => _currentUser.value;
  bool get isLoading => _isLoading.value;
  bool get isAuthenticated => _isAuthenticated.value;
  bool get isInitialized => _isInitialized.value;
  String get errorMessage => _errorMessage.value;
  String get verificationId => _verificationId.value;
  bool get codeSent => _codeSent.value;
  bool get isNewRegistration => _isNewRegistration.value;
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Getters – MFA
  bool get mfaChallengeActive => _mfaChallengeActive.value;
  MultiFactorResolver? get mfaResolver => _mfaResolver.value;
  String get mfaChallengeVerificationId => _mfaChallengeVerificationId.value;
  bool get mfaEnrolled => _mfaEnrolled.value;
  String get mfaEnrollVerificationId => _mfaEnrollVerificationId.value;
  List<MultiFactorInfo> get enrolledMfaFactors => _enrolledFactors.toList();

  // Firebase Auth instance
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // Google Sign In instance

  @override
  void onInit() {
    super.onInit();
    _initializeAuth();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _initializeAuth() async {
    try {
      _setLoading(true);

      _auth.authStateChanges().listen((User? user) async {
        if (user != null) {
          _isAuthenticated.value = true;
          fetchUserProfile(user.uid);
          await _refreshMfaEnrollmentStatus();
        } else {
          _isAuthenticated.value = false;
          _currentUser.value = null;
          _mfaEnrolled.value = false;
        }
      });

      final currentUser = _auth.currentUser;
      if (currentUser != null && !_isAuthenticated.value) {
        _isAuthenticated.value = true;
        fetchUserProfile(currentUser.uid);
        await _refreshMfaEnrollmentStatus();
      }
    } catch (e) {
      print('❌ Error initializing auth: $e');
    } finally {
      _isInitialized.value = true;
      _setLoading(false);
    }
  }

  bool _isSessionValid(DateTime? lastLoginTime) {
    if (lastLoginTime == null) return false;
    final sessionDuration = DateTime.now().difference(lastLoginTime);
    const maxSessionDuration = Duration(days: 30);
    return sessionDuration < maxSessionDuration;
  }

  Future<void> _handlePostAuthNavigation({bool isNewUser = false}) async {
    Get.offAllNamed('/home');
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // EMAIL AUTHENTICATION
  // ─────────────────────────────────────────────────────────────────────────────

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? displayName,
    String? phone,
    String country = 'KE',
  }) async {
    try {
      _setLoading(true);
      _setError('');

      final emailError = UserValidator.validateEmail(email);
      if (emailError != null) { _setError(emailError); return false; }

      if (password.length < 8) {
        _setError('Password must be at least 8 characters');
        return false;
      }

      if (firstName.trim().isEmpty) { _setError('First name is required'); return false; }
      if (lastName.trim().isEmpty)  { _setError('Last name is required');  return false; }

      print('🚀 Attempting signup with email: $email');

      final response = await postRequestNoAuth(
        'auth/register',
        {
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'country': country,
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        },
      );

      print('📝 Signup response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.body;
        final userId = body is Map<String, dynamic> ? body['userId'] as String? : null;

        // Stop loading BEFORE navigating so the OTP screen doesn't inherit the loading state
        _setLoading(false);

        Get.snackbar(
          'Account Created',
          'Welcome to Bridge Africa! Check your email for the verification code.',
          backgroundColor: const Color(0xFF22C55E),
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 10,
        );

        Get.toNamed('/verify-otp', arguments: {'userId': userId, 'email': email});
        return true;
      } else {
        final body = response.body;
        final message = body is Map<String, dynamic>
            ? body['message'] ?? body['error'] ?? 'Sign up failed'
            : response.statusText ?? 'Sign up failed';
        _setError(message);
      }
    } catch (e) {
      print('❌ Unexpected signup error: $e');
      _setError('An unexpected error occurred: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<bool> verifyEmailOtp({
    required String userId,
    required String otp,
  }) async {
    try {
      _setLoading(true);
      _setError('');

      final response = await postRequestNoAuth(
        'auth/verify-otp',
        {'userId': userId, 'otp': otp},
      );

      if (response.statusCode == 200) {
        _setLoading(false);
        Get.snackbar(
          'Email Verified!',
          'Your account is verified. You can now log in.',
          backgroundColor: const Color(0xFF22C55E),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 10,
        );
        Get.offAllNamed('/login');
        return true;
      } else {
        final body = response.body;
        _setError(body is Map<String, dynamic>
            ? body['message'] ?? 'Verification failed'
            : 'Verification failed');
      }
    } catch (e) {
      print('❌ OTP verification error: $e');
      _setError('An unexpected error occurred: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<bool> resendEmailOtp({required String userId}) async {
    try {
      _setLoading(true);
      _setError('');

      final response = await postRequestNoAuth(
        'auth/resend-otp',
        {'userId': userId},
      );

      if (response.statusCode == 200) {
        Get.snackbar(
          'Code Sent',
          'A new verification code has been sent to your email.',
          backgroundColor: const Color(0xFF22C55E),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 10,
        );
        return true;
      } else {
        final body = response.body;
        _setError(body is Map<String, dynamic>
            ? body['message'] ?? 'Failed to resend code'
            : 'Failed to resend code');
      }
    } catch (e) {
      print('❌ Resend OTP error: $e');
      _setError('An unexpected error occurred: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  /// Sign in with email – handles the MFA challenge transparently.
  Future<bool> signInWithEmail({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      _setLoading(true);
      _setError('');

      final emailError = UserValidator.validateEmail(email);
      if (emailError != null) { _setError(emailError); return false; }

      print('🚀 Attempting signin with email: $email');

      UserCredential credential;
      try {
        credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password,
        );
      } on FirebaseAuthMultiFactorException catch (e) {
        // ── MFA challenge ──────────────────────────────────────────────────
        print('🔐 MFA required – starting challenge...');
        final resolver = e.resolver;
        _mfaResolver.value = resolver;
        _mfaChallengeActive.value = true;

        // Automatically send SMS to the first enrolled factor
        final hint = resolver.hints
            .whereType<PhoneMultiFactorInfo>()
            .firstOrNull;

        if (hint == null) {
          _setError('No phone factor enrolled for MFA.');
          _mfaChallengeActive.value = false;
          return false;
        }

        await _sendMfaChallengeCode(resolver: resolver, hint: hint);
        _setLoading(false);
        // Navigate to MFA verification screen
        Get.toNamed('/mfa-verify');
        return false; // not yet complete – MFA screen will call completeMfaSignIn
      } on FirebaseAuthException catch (e) {
        rethrow;
      }

      // ── Normal (no MFA) sign-in ────────────────────────────────────────────
      if (credential.user != null) {
        print('✅ Firebase signin successful, calling backend login...');

        // Validate account status and fetch profile from backend
        final loginResponse = await postRequest('auth/login', {});

        if (loginResponse.statusCode == 403) {
          final body = loginResponse.body;
          final errorCode = body is Map<String, dynamic> ? body['error'] : null;

          if (errorCode == 'ACCOUNT_NOT_VERIFIED') {
            // Sign out from Firebase — unverified users must not stay signed in
            await _auth.signOut();
            final userId = body['userId'] as String?;
            Get.snackbar(
              'Email Not Verified',
              'Please verify your email before logging in.',
              backgroundColor: Colors.orange.shade600,
              colorText: Colors.white,
              duration: const Duration(seconds: 4),
              snackPosition: SnackPosition.BOTTOM,
              margin: const EdgeInsets.all(16),
              borderRadius: 10,
            );
            if (userId != null) {
              Get.toNamed('/verify-otp', arguments: {'userId': userId, 'email': email});
            }
            return false;
          }

          if (errorCode == 'ACCOUNT_SUSPENDED') {
            await _auth.signOut();
            _setError('Your account has been suspended. Please contact support.');
            return false;
          }

          await _auth.signOut();
          _setError('Login failed. Please try again.');
          return false;
        }

        if (loginResponse.statusCode != 200) {
          final body = loginResponse.body;
          final errorCode = body is Map<String, dynamic> ? body['error'] : null;

          // Network / server errors (Render cold-start, etc.) – Firebase auth
          // already succeeded so don't sign the user out. Let them in and show
          // a soft warning; profile will be fetched lazily by authStateChanges.
          final isNetworkOrServerError =
              loginResponse.statusCode == 500 ||
              loginResponse.statusCode == 503 ||
              errorCode == 'NETWORK_ERROR' ||
              errorCode == 'CONNECTION_ERROR';

          if (isNetworkOrServerError) {
            print('⚠️ Backend unreachable during login (cold-start?), proceeding with Firebase auth.');
            Get.snackbar(
              'Connected',
              'Signed in. Server is warming up – some data may load shortly.',
              backgroundColor: Colors.orange.shade600,
              colorText: Colors.white,
              duration: const Duration(seconds: 4),
              snackPosition: SnackPosition.BOTTOM,
              margin: const EdgeInsets.all(16),
              borderRadius: 10,
            );
            await _saveAuthState(credential.user!);
            await _handlePostAuthNavigation(isNewUser: false);
            return true;
          }

          await _auth.signOut();
          _setError(body is Map<String, dynamic>
              ? body['message'] ?? 'Login failed'
              : 'Login failed');
          return false;
        }

        // Parse user profile from backend response
        final loginBody = loginResponse.body;
        if (loginBody is Map<String, dynamic> && loginBody['user'] is Map<String, dynamic>) {
          _currentUser.value = UserModel.fromJson(loginBody['user'] as Map<String, dynamic>);
        }

        await _saveAuthState(credential.user!);
        await _refreshMfaEnrollmentStatus();

        Get.snackbar('Welcome Back', 'Signed in successfully!',
            backgroundColor: Get.theme.colorScheme.primaryContainer,
            colorText: Get.theme.colorScheme.onPrimaryContainer);

        await _handlePostAuthNavigation(isNewUser: false);
        return true;
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth signin error: ${e.code} - ${e.message}');
      _setError(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      print('❌ Unexpected signin error: $e');
      _setError('An unexpected error occurred: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // GOOGLE AUTHENTICATION
  // ─────────────────────────────────────────────────────────────────────────────

  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError('');

      if (!kIsWeb) {
        try {
          if (Platform.isWindows || Platform.isLinux) {
            _setError('Google sign-in is not available on this platform.');
            return false;
          }
        } catch (_) {}
      }

      UserCredential userCredential;

      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        try {
          userCredential = await _auth.signInWithPopup(googleProvider);
        } on FirebaseAuthMultiFactorException catch (e) {
          await _handleGoogleMfaChallenge(e);
          return false;
        } on FirebaseAuthException catch (e) {
          rethrow;
        }
      } else {
        _setError('Google sign-in is only supported on web for this platform.');
        return false;
      }

      return await _handleGoogleCredential(userCredential);
    } on FirebaseAuthException catch (e) {
      print('❌ Google Firebase Auth error: ${e.code} - ${e.message}');
      _setError(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      print('❌ Google sign-in error: $e');
      _setError('Google sign-in failed. Please try again.');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<void> _handleGoogleMfaChallenge(FirebaseAuthMultiFactorException e) async {
    print('🔐 MFA required for Google sign-in – starting challenge...');
    final resolver = e.resolver;
    _mfaResolver.value = resolver;
    _mfaChallengeActive.value = true;

    final hint = resolver.hints.whereType<PhoneMultiFactorInfo>().firstOrNull;
    if (hint == null) {
      _setError('No phone factor enrolled for MFA.');
      _mfaChallengeActive.value = false;
      return;
    }

    await _sendMfaChallengeCode(resolver: resolver, hint: hint);
    _setLoading(false);
    Get.toNamed('/mfa-verify');
  }

  Future<bool> _handleGoogleCredential(UserCredential userCredential) async {
    final user = userCredential.user;
    if (user == null) return false;

    final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

    if (isNewUser) {
      final nameParts = (user.displayName ?? '').split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      final idToken = await user.getIdToken();

      final response = await postRequestNoAuth(
        '/users/auth/signup/google',
        {
          'uid': user.uid,
          'email': user.email ?? '',
          'firstName': firstName,
          'lastName': lastName,
          'displayName': user.displayName ?? '',
          'photoURL': user.photoURL ?? '',
          'idToken': idToken,
        },
        contentType: 'application/json',
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        try { await user.delete(); } catch (_) {}
        final message = response.body is Map<String, dynamic>
            ? response.body['message'] ?? 'Registration failed'
            : 'Google registration failed';
        _setError(message);
        return false;
      }
    }

    await _saveAuthState(user);
    await fetchUserProfile(user.uid);
    await _refreshMfaEnrollmentStatus();

    Get.snackbar(
      isNewUser ? 'Welcome!' : 'Welcome Back',
      isNewUser ? 'Account created with Google successfully!' : 'Signed in with Google!',
      backgroundColor: Get.theme.colorScheme.primaryContainer,
      colorText: Get.theme.colorScheme.onPrimaryContainer,
    );

    await _handlePostAuthNavigation(isNewUser: isNewUser);
    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MFA – CHALLENGE (during sign-in)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Sends the SMS code for the active MFA challenge.
  Future<void> _sendMfaChallengeCode({
    required MultiFactorResolver resolver,
    required PhoneMultiFactorInfo hint,
  }) async {
    try {
      final session = resolver.session;

      await FirebaseAuth.instance.verifyPhoneNumber(
        multiFactorSession: session,
        multiFactorInfo: hint,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolved on Android – complete sign-in immediately
          await _completeMfaWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ MFA verification failed: ${e.code} - ${e.message}');
          _setError('Failed to send MFA code: ${e.message}');
          _mfaChallengeActive.value = false;
        },
        codeSent: (String verificationId, int? resendToken) {
          print('📤 MFA SMS sent. Verification ID: $verificationId');
          _mfaChallengeVerificationId.value = verificationId;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _mfaChallengeVerificationId.value = verificationId;
        },
      );
    } catch (e) {
      print('❌ Error sending MFA challenge code: $e');
      _setError('Failed to send MFA code: ${e.toString()}');
      _mfaChallengeActive.value = false;
    }
  }

  /// Call this from the MFA screen when the user enters the SMS code.
  Future<bool> completeMfaSignIn(String smsCode) async {
    try {
      _setLoading(true);
      _setError('');

      final resolver = _mfaResolver.value;
      if (resolver == null) {
        _setError('MFA session expired. Please sign in again.');
        return false;
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _mfaChallengeVerificationId.value,
        smsCode: smsCode,
      );

      return await _completeMfaWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      print('❌ MFA completion error: ${e.code}');
      if (e.code == 'invalid-verification-code') {
        _setError('Invalid code. Please try again.');
      } else if (e.code == 'session-expired') {
        _setError('Session expired. Please sign in again.');
      } else {
        _setError(_getFirebaseAuthErrorMessage(e));
      }
      return false;
    } catch (e) {
      print('❌ Unexpected MFA completion error: $e');
      _setError('MFA verification failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _completeMfaWithCredential(PhoneAuthCredential credential) async {
    final resolver = _mfaResolver.value;
    if (resolver == null) return false;

    final multiFactorAssertion = PhoneMultiFactorGenerator.getAssertion(credential);
    final userCredential = await resolver.resolveSignIn(multiFactorAssertion);

    if (userCredential.user != null) {
      print('✅ MFA sign-in complete');

      _mfaChallengeActive.value = false;
      _mfaResolver.value = null;
      _mfaChallengeVerificationId.value = '';

      await _saveAuthState(userCredential.user!);
      await fetchUserProfile(userCredential.user!.uid);
      await _refreshMfaEnrollmentStatus();

      Get.snackbar(
        'Welcome Back',
        'Signed in with 2FA successfully!',
        backgroundColor: Get.theme.colorScheme.primaryContainer,
        colorText: Get.theme.colorScheme.onPrimaryContainer,
      );

      await _handlePostAuthNavigation(isNewUser: false);
      return true;
    }
    return false;
  }

  /// Resend the MFA challenge SMS.
  Future<bool> resendMfaChallengeCode() async {
    final resolver = _mfaResolver.value;
    if (resolver == null) return false;

    final hint = resolver.hints.whereType<PhoneMultiFactorInfo>().firstOrNull;
    if (hint == null) return false;

    _setError('');
    await _sendMfaChallengeCode(resolver: resolver, hint: hint);
    return true;
  }

  void cancelMfaChallenge() {
    _mfaChallengeActive.value = false;
    _mfaResolver.value = null;
    _mfaChallengeVerificationId.value = '';
    _setError('');
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MFA – ENROLLMENT (after sign-in, from Security settings)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Checks whether the current user has any MFA factors enrolled.
  Future<void> _refreshMfaEnrollmentStatus() async {
    final user = _auth.currentUser;
    if (user == null) { 
      _mfaEnrolled.value = false; 
      return; 
    }
    final factors = await user.multiFactor.getEnrolledFactors();
    _mfaEnrolled.value = factors.isNotEmpty;
    _enrolledFactors.assignAll(factors);
    print('🔐 MFA enrolled: ${_mfaEnrolled.value} (${factors.length} factor(s))');
  }

  /// Returns the list of enrolled MFA factors for the current user.
  Future<List<MultiFactorInfo>> getEnrolledMfaFactors() async =>
      _auth.currentUser != null 
          ? await _auth.currentUser!.multiFactor.getEnrolledFactors() 
          : [];

  /// Step 1 of enrollment: send SMS code to [phoneNumber].
  Future<bool> startMfaEnrollment(String phoneNumber) async {
    try {
      _setLoading(true);
      _setError('');

      final user = _auth.currentUser;
      if (user == null) { _setError('No user signed in.'); return false; }

      final phoneError = UserValidator.validatePhoneNumber(phoneNumber);
      if (phoneError != null) { _setError(phoneError); return false; }

      print('📲 Starting MFA enrollment for: $phoneNumber');

      final session = await user.multiFactor.getSession();

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        multiFactorSession: session,
        verificationCompleted: (_) {}, // not used during enrollment
        verificationFailed: (FirebaseAuthException e) {
          print('❌ Enrollment verification failed: ${e.code}');
          _setError('Failed to send code: ${e.message}');
          _setLoading(false);
        },
        codeSent: (String verificationId, int? resendToken) {
          print('📤 Enrollment SMS sent. Verification ID: $verificationId');
          _mfaEnrollVerificationId.value = verificationId;
          _setLoading(false);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _mfaEnrollVerificationId.value = verificationId;
          _setLoading(false);
        },
      );
      return true;
    } catch (e) {
      print('❌ startMfaEnrollment error: $e');
      _setError('Failed to start enrollment: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Step 2 of enrollment: verify the SMS [code] and finalize enrollment.
  Future<bool> completeMfaEnrollment({
    required String smsCode,
    String displayName = 'Phone',
  }) async {
    try {
      _setLoading(true);
      _setError('');

      final user = _auth.currentUser;
      if (user == null) { _setError('No user signed in.'); return false; }

      if (_mfaEnrollVerificationId.value.isEmpty) {
        _setError('No enrollment session found. Please request a new code.');
        return false;
      }

      print('🔐 Completing MFA enrollment...');

      final credential = PhoneAuthProvider.credential(
        verificationId: _mfaEnrollVerificationId.value,
        smsCode: smsCode,
      );

      final assertion = PhoneMultiFactorGenerator.getAssertion(credential);
      await user.multiFactor.enroll(assertion, displayName: displayName);

      await _refreshMfaEnrollmentStatus();
      _mfaEnrollVerificationId.value = '';

      Get.snackbar(
        '2FA Enabled',
        'Two-factor authentication has been enabled for your account.',
        backgroundColor: const Color(0xFF22C55E),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 10,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      print('❌ MFA enrollment error: ${e.code}');
      if (e.code == 'invalid-verification-code') {
        _setError('Invalid code. Please try again.');
      } else if (e.code == 'session-expired') {
        _setError('Session expired. Please request a new code.');
      } else {
        _setError(_getFirebaseAuthErrorMessage(e));
      }
      return false;
    } catch (e) {
      print('❌ Unexpected enrollment error: $e');
      _setError('Failed to enable 2FA: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Unenroll (remove) a specific MFA factor.
  Future<bool> unenrollMfaFactor(MultiFactorInfo factor) async {
    try {
      _setLoading(true);
      _setError('');

      final user = _auth.currentUser;
      if (user == null) { _setError('No user signed in.'); return false; }

      print('🗑️ Unenrolling MFA factor: ${factor.displayName}');
      await user.multiFactor.unenroll(multiFactorInfo: factor);
      await _refreshMfaEnrollmentStatus();

      Get.snackbar(
        '2FA Disabled',
        'Two-factor authentication has been removed from your account.',
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 10,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      print('❌ MFA unenroll error: ${e.code}');
      _setError(_getFirebaseAuthErrorMessage(e));
      return false;
    } catch (e) {
      print('❌ Unexpected unenroll error: $e');
      _setError('Failed to disable 2FA: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // EMAIL VERIFICATION
  // ─────────────────────────────────────────────────────────────────────────────

  Future<bool> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) { _setError('No user is signed in.'); return false; }
      if (user.emailVerified) return true;

      await user.sendEmailVerification();

      Get.snackbar(
        'Verification Email Sent',
        'Please check your inbox and click the verification link.',
        backgroundColor: Get.theme.colorScheme.primaryContainer,
        colorText: Get.theme.colorScheme.onPrimaryContainer,
        duration: const Duration(seconds: 4),
      );
      return true;
    } catch (e) {
      print('❌ sendEmailVerification error: $e');
      _setError('Failed to send verification email. Please try again.');
      return false;
    }
  }

  Future<bool> checkEmailVerified() async {
    try {
      await _auth.currentUser?.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // PHONE AUTHENTICATION
  // ─────────────────────────────────────────────────────────────────────────────

  Future<bool> sendPhoneVerificationCode({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      _setLoading(true);
      _setError('');

      final phoneError = UserValidator.validatePhoneNumber(phoneNumber);
      if (phoneError != null) {
        _setError(phoneError);
        onError(phoneError);
        return false;
      }

      print('📱 Sending verification code to: $phoneNumber');

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithPhoneCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ Verification failed: ${e.code} - ${e.message}');
          String errorMessage = 'Phone verification failed';
          if (e.code == 'invalid-phone-number') errorMessage = 'Invalid phone number format';
          else if (e.code == 'too-many-requests') errorMessage = 'Too many requests. Please try again later';
          else if (e.code == 'quota-exceeded') errorMessage = 'SMS quota exceeded. Please try again tomorrow';
          _setError(errorMessage);
          onError(errorMessage);
          _setLoading(false);
        },
        codeSent: (String verificationId, int? resendToken) {
          print('📤 Code sent! Verification ID: $verificationId');
          _verificationId.value = verificationId;
          _resendToken.value = resendToken ?? 0;
          _codeSent.value = true;
          onCodeSent(verificationId);
          _setLoading(false);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId.value = verificationId;
          _setLoading(false);
        },
      );
      return true;
    } catch (e) {
      print('❌ Error sending verification code: $e');
      final error = 'Failed to send verification code: ${e.toString()}';
      _setError(error);
      onError(error);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyPhoneCode({
    required String smsCode,
    required String verificationId,
  }) async {
    try {
      _setLoading(true);
      _setError('');
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId, smsCode: smsCode,
      );
      return await _signInWithPhoneCredential(credential);
    } catch (e) {
      print('❌ Error verifying code: $e');
      if (e is FirebaseAuthException) {
        if (e.code == 'invalid-verification-code') _setError('Invalid verification code');
        else if (e.code == 'session-expired') _setError('Verification session expired. Please request a new code');
        else _setError('Verification failed: ${e.message}');
      } else {
        _setError('Failed to verify code: ${e.toString()}');
      }
      _setLoading(false);
      return false;
    }
  }

  Future<bool> _signInWithPhoneCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        final token = await userCredential.user!.getIdToken();
        final response = await postRequestNoAuth(
          '/users/auth/signin/phone',
          {'idToken': token},
          contentType: 'application/json',
        );

        if (response.statusCode == 200 &&
            response.body is Map<String, dynamic> &&
            response.body['success'] == true) {
          await _saveAuthState(userCredential.user!);
          await fetchUserProfile(userCredential.user!.uid);
          await _refreshMfaEnrollmentStatus();

          Get.snackbar('Welcome Back', 'Signed in successfully!',
              backgroundColor: Get.theme.colorScheme.primaryContainer,
              colorText: Get.theme.colorScheme.onPrimaryContainer);

          _setLoading(false);
          await _handlePostAuthNavigation(isNewUser: false);
          return true;
        } else if (response.statusCode == 404) {
          _setLoading(false);
          return true;
        } else {
          _setError('Authentication failed');
          _setLoading(false);
          return false;
        }
      }
      _setLoading(false);
      return false;
    } catch (e) {
      print('❌ Error signing in with credential: $e');
      _setError('Authentication failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> completePhoneSignUp({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    String? email,
    String? password,
  }) async {
    try {
      _setLoading(true);
      _setError('');

      final firstNameError = UserValidator.validateFirstName(firstName);
      if (firstNameError != null) { _setError(firstNameError); return false; }

      final lastNameError = UserValidator.validateLastName(lastName);
      if (lastNameError != null) { _setError(lastNameError); return false; }

      final phoneError = UserValidator.validatePhoneNumber(phoneNumber);
      if (phoneError != null) { _setError(phoneError); return false; }

      if (email != null && email.isNotEmpty) {
        final emailError = UserValidator.validateEmail(email);
        if (emailError != null) { _setError(emailError); return false; }
      }

      if (password != null && password.isNotEmpty) {
        final passwordError = UserValidator.validatePassword(password);
        if (passwordError != null) { _setError(passwordError); return false; }
      }

      final currentUser = _auth.currentUser;
      if (currentUser == null) { _setError('No authenticated user found'); return false; }

      final response = await postRequestNoAuth(
        '/users/auth/signup/phone',
        {
          'phoneNumber': phoneNumber,
          'firstName': firstName,
          'lastName': lastName,
          if (email != null && email.isNotEmpty) 'email': email,
          if (password != null && password.isNotEmpty) 'password': password,
        },
        contentType: 'application/json',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = response.body;
        if (responseBody is Map<String, dynamic> && responseBody['success'] == true) {
          await _saveAuthState(currentUser);
          await fetchUserProfile(currentUser.uid);

          Get.snackbar('Success', 'Account created successfully!',
              backgroundColor: Get.theme.colorScheme.primaryContainer,
              colorText: Get.theme.colorScheme.onPrimaryContainer,
              duration: const Duration(seconds: 2));

          await _handlePostAuthNavigation(isNewUser: true);
          return true;
        } else {
          final message = responseBody is Map<String, dynamic>
              ? responseBody['message'] ?? 'Sign up failed'
              : 'Sign up failed - unexpected response format';
          _setError(message);
        }
      } else {
        final message = response.body is Map<String, dynamic>
            ? response.body['message'] ?? 'Sign up failed'
            : response.statusText ?? 'Sign up failed';
        _setError('Signup failed: $message');
      }
    } catch (e) {
      print('❌ Error completing phone signup: $e');
      _setError('An unexpected error occurred: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<bool> resendVerificationCode({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    _codeSent.value = false;
    return await sendPhoneVerificationCode(
      phoneNumber: phoneNumber, onCodeSent: onCodeSent, onError: onError,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // USER PROFILE
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _saveAuthState(User firebaseUser) async {}

  Future<void> fetchUserProfile(String uid) async {
    try {
      final response = await postRequest('auth/login', {});
      if (response.statusCode == 200) {
        final responseBody = response.body;
        if (responseBody is Map<String, dynamic> &&
            responseBody['user'] is Map<String, dynamic>) {
          final user = UserModel.fromJson(responseBody['user'] as Map<String, dynamic>);
          _currentUser.value = user;
        }
      } else if (response.statusCode == 403) {
        final body = response.body;
        if (body is Map<String, dynamic> && body['error'] == 'ACCOUNT_NOT_VERIFIED') {
          print('⚠️ Account not verified – clearing session');
          await _auth.signOut();
          _isAuthenticated.value = false;
          _currentUser.value = null;
        }
      }
    } catch (e) {
      print('❌ Error fetching user profile: $e');
    }
  }

  Future<bool> updateProfile({String? displayName, String? photoURL}) async {
    try {
      _setLoading(true);
      _setError('');
      if (currentUser == null) { _setError('No user logged in'); return false; }

      if (displayName != null) {
        final err = UserValidator.validateDisplayName(displayName);
        if (err != null) { _setError(err); return false; }
      }

      final response = await putRequest(
        '/users/auth/user/${currentUser!.uid}',
        {
          if (displayName != null) 'displayName': displayName,
          if (photoURL != null) 'photoURL': photoURL,
        },
        contentType: 'application/json',
      );

      if (response.statusCode == 200) {
        final responseBody = response.body;
        if (responseBody is Map<String, dynamic> && responseBody['success'] == true) {
          final updatedUser = currentUser!.copyWith(
            displayName: displayName ?? currentUser!.displayName,
            photoURL: photoURL ?? currentUser!.photoURL,
            updatedAt: DateTime.now(),
          );
          _currentUser.value = updatedUser;
          Get.snackbar('Success', 'Profile updated successfully!',
              backgroundColor: Get.theme.colorScheme.primaryContainer,
              colorText: Get.theme.colorScheme.onPrimaryContainer);
          return true;
        } else {
          _setError(response.body['message'] ?? 'Failed to update profile');
        }
      } else {
        _setError(response.body is Map<String, dynamic>
            ? response.body['message'] ?? 'Failed to update profile'
            : response.statusText ?? 'Failed to update profile');
      }
    } catch (e) {
      _setError('Failed to update profile: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  /// Replaces the in-memory user and persists to SharedPrefs.
  /// Called after a successful PATCH /users/me response.
  Future<void> updateCurrentUser(UserModel updated) async {
    _currentUser.value = updated;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // AUTH MANAGEMENT
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _auth.signOut();
      _currentUser.value = null;
      _isAuthenticated.value = false;
      _isNewRegistration.value = false;
      _mfaEnrolled.value = false;
      _setError('');
      Get.snackbar('Signed Out', 'You have been signed out successfully',
          backgroundColor: Get.theme.colorScheme.surfaceVariant,
          colorText: Get.theme.colorScheme.onSurfaceVariant);
    } catch (e) {
      _setError('Failed to sign out: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  bool shouldAutoLogin() => _isAuthenticated.value && _currentUser.value != null;

  Future<void> refreshAuthState() async => await _initializeAuth();

  Future<bool> resetPassword({required String email}) async {
    try {
      _setLoading(true);
      _setError('');
      final emailError = UserValidator.validateEmail(email);
      if (emailError != null) { _setError(emailError); return false; }
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar('Password Reset',
          'If your account exists, a password reset link has been sent.',
          backgroundColor: Get.theme.colorScheme.primaryContainer,
          colorText: Get.theme.colorScheme.onPrimaryContainer);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      _setError('Failed to send reset email: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _setLoading(true);
      _setError('');
      final user = _auth.currentUser;
      if (user == null) { _setError('No user logged in'); return false; }
      final credential = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      Get.snackbar('Success', 'Password changed successfully!',
          backgroundColor: Get.theme.colorScheme.primaryContainer,
          colorText: Get.theme.colorScheme.onPrimaryContainer);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      _setError('Failed to change password: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<bool> deleteAccount() async {
    try {
      _setLoading(true);
      _setError('');
      final user = _auth.currentUser;
      if (user == null) { _setError('No user logged in'); return false; }

      final response = await putRequest(
        '/users/auth/user/${user.uid}/delete',
        {'action': 'delete'},
        contentType: 'application/json',
      );

      if (response.statusCode == 200) {
        final responseBody = response.body;
        if (responseBody is Map<String, dynamic> && responseBody['success'] == true) {
          await user.delete();
          _currentUser.value = null;
          _isAuthenticated.value = false;
          _isNewRegistration.value = false;
          _mfaEnrolled.value = false;
          Get.snackbar('Account Deleted', 'Your account has been deleted successfully',
              backgroundColor: Get.theme.colorScheme.errorContainer,
              colorText: Get.theme.colorScheme.onErrorContainer);
          return true;
        } else {
          _setError(responseBody['message'] ?? 'Failed to delete account');
        }
      } else {
        _setError(response.body is Map<String, dynamic>
            ? response.body['message'] ?? 'Failed to delete account'
            : response.statusText ?? 'Failed to delete account');
      }
    } on FirebaseAuthException catch (e) {
      _setError(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      _setError('Failed to delete account: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  void clearError() => _errorMessage.value = '';
  void _setLoading(bool loading) => _isLoading.value = loading;
  void _setError(String error) => _errorMessage.value = error;

  // ─────────────────────────────────────────────────────────────────────────────
  // PROFILE PHOTO / DISPLAY NAME / FULL PROFILE
  // ─────────────────────────────────────────────────────────────────────────────

  Future<bool> updateProfilePhoto(String photoURL) async {
    try {
      _setLoading(true);
      _setError('');
      final user = _auth.currentUser;
      if (user == null) { _setError('No user logged in'); return false; }

      final response = await putRequest(
        '/users/auth/user/${user.uid}', {'photoURL': photoURL},
        contentType: 'application/json',
      );

      if (response.statusCode == 200) {
        final responseBody = response.body;
        if (responseBody is Map<String, dynamic> && responseBody['success'] == true) {
          await user.updatePhotoURL(photoURL);
          _currentUser.value = _currentUser.value?.copyWith(photoURL: photoURL, updatedAt: DateTime.now());
          Get.snackbar('Success', 'Profile photo updated successfully',
              backgroundColor: Get.theme.colorScheme.primaryContainer,
              colorText: Get.theme.colorScheme.onPrimaryContainer);
          return true;
        } else {
          _setError(responseBody['message'] ?? 'Failed to update photo');
        }
      } else {
        _setError(response.body is Map<String, dynamic>
            ? response.body['message'] ?? 'Failed to update photo'
            : response.statusText ?? 'Failed to update photo');
      }
    } catch (e) {
      _setError('Failed to update photo: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<bool> updateDisplayName(String displayName) async {
    try {
      _setLoading(true);
      _setError('');
      final user = _auth.currentUser;
      if (user == null) { _setError('No user logged in'); return false; }

      final response = await putRequest(
        '/users/auth/user/${user.uid}', {'displayName': displayName},
        contentType: 'application/json',
      );

      if (response.statusCode == 200) {
        final responseBody = response.body;
        if (responseBody is Map<String, dynamic> && responseBody['success'] == true) {
          await user.updateDisplayName(displayName);
          _currentUser.value = _currentUser.value?.copyWith(displayName: displayName, updatedAt: DateTime.now());
          Get.snackbar('Success', 'Display name updated successfully',
              backgroundColor: Get.theme.colorScheme.primaryContainer,
              colorText: Get.theme.colorScheme.onPrimaryContainer);
          return true;
        } else {
          _setError(responseBody['message'] ?? 'Failed to update display name');
        }
      } else {
        _setError(response.body is Map<String, dynamic>
            ? response.body['message'] ?? 'Failed to update display name'
            : response.statusText ?? 'Failed to update display name');
      }
    } catch (e) {
      _setError('Failed to update display name: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<bool> updateFullProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String address,
    String? photoURL,
  }) async {
    try {
      _setLoading(true);
      _setError('');
      final user = _auth.currentUser;
      if (user == null) { _setError('No user logged in'); return false; }

      final firstNameError = UserValidator.validateFirstName(firstName);
      if (firstNameError != null) { _setError(firstNameError); return false; }

      final lastNameError = UserValidator.validateLastName(lastName);
      if (lastNameError != null) { _setError(lastNameError); return false; }

      final updateData = {
        'firstName': firstName,
        'lastName': lastName,
        'displayName': '$firstName $lastName',
        'phoneNumber': phoneNumber,
        'additionalData': {
          ...(_currentUser.value?.additionalData ?? {}),
          'address': address,
        },
        if (photoURL != null) 'photoURL': photoURL,
      };

      final response = await putRequest(
        '/users/auth/user/${user.uid}', updateData,
        contentType: 'application/json',
      );

      if (response.statusCode == 200) {
        final responseBody = response.body;
        if (responseBody is Map<String, dynamic> && responseBody['success'] == true) {
          await user.updateDisplayName('$firstName $lastName');
          if (photoURL != null) await user.updatePhotoURL(photoURL);
          _currentUser.value = _currentUser.value?.copyWith(
            firstName: firstName, lastName: lastName,
            displayName: '$firstName $lastName',
            phoneNumber: phoneNumber,
            photoURL: photoURL ?? _currentUser.value?.photoURL,
            additionalData: {...(_currentUser.value?.additionalData ?? {}), 'address': address},
            updatedAt: DateTime.now(),
          );
          return true;
        } else {
          _setError(responseBody['message'] ?? 'Failed to update profile');
        }
      } else {
        _setError(response.body is Map<String, dynamic>
            ? response.body['message'] ?? 'Failed to update profile'
            : response.statusText ?? 'Failed to update profile');
      }
    } catch (e) {
      _setError('Failed to update profile: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SHOP REGISTRATION
  // ─────────────────────────────────────────────────────────────────────────────

  Future<bool> registerAsShop({
    required String businessName,
    required String businessDescription,
    required String businessAddress,
    required String businessEmail,
    required String businessPhone,
    required String county,
    required String subCounty,
    required dynamic kraPinFile,
    required dynamic businessRegFile,
    dynamic countyPermitFile,
    required dynamic ownerIdFile,
    List<dynamic> businessPhotos = const [],
  }) async {
    try {
      _setLoading(true);
      _setError('');

      final user = _auth.currentUser;
      if (user == null) { _setError('No user logged in'); return false; }

      String? kraPinUrl = await _uploadDocument(user.uid, kraPinFile, 'kra_pin');
      if (kraPinUrl == null) { _setError('Failed to upload KRA PIN certificate'); return false; }

      String? businessRegUrl = await _uploadDocument(user.uid, businessRegFile, 'business_registration');
      if (businessRegUrl == null) { _setError('Failed to upload business registration certificate'); return false; }

      String? countyPermitUrl;
      if (countyPermitFile != null) {
        countyPermitUrl = await _uploadDocument(user.uid, countyPermitFile, 'county_permit');
      }

      String? ownerIdUrl = await _uploadDocument(user.uid, ownerIdFile, 'owner_id');
      if (ownerIdUrl == null) { _setError('Failed to upload owner ID'); return false; }

      List<String> businessPhotoUrls = [];
      if (businessPhotos.isNotEmpty) {
        businessPhotoUrls = await _uploadBusinessPhotos(user.uid, businessPhotos);
      }

      final response = await postRequest(
        '/users/auth/user/${user.uid}/register-shop',
        {
          'businessName': businessName,
          'businessDescription': businessDescription,
          'businessAddress': businessAddress,
          'businessEmail': businessEmail.isNotEmpty ? businessEmail : null,
          'businessPhone': businessPhone,
          'county': county,
          'subCounty': subCounty.isNotEmpty ? subCounty : null,
          'kraPinCertificateUrl': kraPinUrl,
          'businessRegistrationUrl': businessRegUrl,
          'countyPermitUrl': countyPermitUrl,
          'ownerIdUrl': ownerIdUrl,
          'businessPhotos': businessPhotoUrls,
        },
        contentType: 'application/json',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = response.body;
        if (responseBody is Map<String, dynamic> && responseBody['success'] == true) {
          await fetchUserProfile(user.uid);
          Get.snackbar('Success', 'Shop registration submitted! Awaiting verification.',
              backgroundColor: Get.theme.colorScheme.primaryContainer,
              colorText: Get.theme.colorScheme.onPrimaryContainer,
              duration: const Duration(seconds: 3));
          return true;
        } else {
          _setError(responseBody is Map<String, dynamic>
              ? responseBody['message'] ?? 'Registration failed'
              : 'Registration failed - unexpected response');
        }
      } else {
        _setError(response.body is Map<String, dynamic>
            ? response.body['message'] ?? 'Registration failed'
            : response.statusText ?? 'Registration failed');
      }
    } catch (e) {
      _setError('Failed to register shop: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<String?> _uploadDocument(String uid, dynamic file, String documentType) async {
    try {
      final filename = '${documentType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final MultipartFile multipartFile = MultipartFile(file, filename: filename);
      final formData = FormData({'uid': uid, 'documentType': documentType, 'document': multipartFile});
      final response = await postRequest('/users/upload/document', formData);
      if (response.statusCode == 200) {
        final responseBody = response.body;
        if (responseBody is Map<String, dynamic> && responseBody['success'] == true) {
          return responseBody['document']['url'] as String?;
        }
      }
      return null;
    } catch (e) {
      print('❌ Error uploading $documentType: $e');
      return null;
    }
  }

  Future<List<String>> _uploadBusinessPhotos(String uid, List<dynamic> photos) async {
    try {
      final List<MultipartFile> multipartFiles = [];
      for (int i = 0; i < photos.length; i++) {
        final file = photos[i];
        final filename = 'photo_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        multipartFiles.add(MultipartFile(file, filename: filename));
      }
      final formData = FormData({'uid': uid, 'photos': multipartFiles});
      final response = await postRequest('/users/upload/business-photos', formData);
      if (response.statusCode == 200) {
        final responseBody = response.body;
        if (responseBody is Map<String, dynamic> && responseBody['success'] == true) {
          final uploadedPhotos = responseBody['photos'] as List<dynamic>;
          return uploadedPhotos.map((p) => p['url'] as String).toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ Error uploading business photos: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getShopStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      final response = await getRequest('/users/auth/user/${user.uid}/shop-status');
      if (response.statusCode == 200) {
        final responseBody = response.body;
        if (responseBody is Map<String, dynamic> && responseBody['success'] == true) {
          return responseBody;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────────

  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':           return 'This email is already registered';
      case 'invalid-email':                  return 'Invalid email address';
      case 'operation-not-allowed':          return 'This operation is not allowed';
      case 'weak-password':                  return 'Password is too weak';
      case 'user-disabled':                  return 'This account has been disabled';
      case 'user-not-found':                 return 'No account found with this email';
      case 'wrong-password':                 return 'Incorrect password';
      case 'invalid-verification-code':      return 'Invalid verification code';
      case 'invalid-verification-id':        return 'Invalid verification ID';
      case 'session-expired':                return 'Session expired. Please try again';
      case 'too-many-requests':              return 'Too many requests. Please try again later';
      case 'requires-recent-login':          return 'Please sign in again to continue';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method';
      case 'popup-closed-by-user':           return 'Sign-in popup was closed. Please try again.';
      default:                               return e.message ?? 'An authentication error occurred';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VALIDATOR
// ─────────────────────────────────────────────────────────────────────────────

class UserValidator {
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) return 'Please enter a valid email';
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) return 'Password is required';
    if (password.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? validatePhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return 'Phone number is required';
    if (!phone.startsWith('+')) return 'Phone number must start with country code (e.g., +254)';
    if (phone.length < 10) return 'Please enter a valid phone number';
    return null;
  }

  static String? validateFirstName(String? name) {
    if (name == null || name.trim().isEmpty) return 'First name is required';
    if (name.trim().length < 2) return 'First name must be at least 2 characters';
    return null;
  }

  static String? validateLastName(String? name) {
    if (name == null || name.trim().isEmpty) return 'Last name is required';
    if (name.trim().length < 2) return 'Last name must be at least 2 characters';
    return null;
  }

  static String? validateDisplayName(String? displayName) {
    if (displayName != null && displayName.isNotEmpty) {
      if (displayName.length < 3) return 'Display name must be at least 3 characters';
      if (displayName.length > 30) return 'Display name must be less than 30 characters';
    }
    return null;
  }
}