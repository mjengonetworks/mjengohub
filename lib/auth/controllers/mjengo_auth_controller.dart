import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../services/mjengo_service.dart';
import '../models/user_model.dart';

/// Auth controller for the Mjengo Hub REST API.
/// Handles register, login, logout, and profile using JWT tokens.
class MjengoAuthController extends GetxController {
  final MjengoService _api = Get.find<MjengoService>();

  final Rx<UserModel?>  _user            = Rx<UserModel?>(null);
  final RxBool          _isLoading        = false.obs;
  final RxBool          _isAuthenticated  = false.obs;
  final RxString        _errorMessage     = ''.obs;
  final RxBool          _isInitialized    = false.obs;

  // Web OAuth client registered on the Mjengo Hub backend — used to obtain a
  // Google ID token whose audience the server can verify.
  static const String _googleClientId =
      '729219361762-7pcsonpov16fit17ettakrj1cufsjel2.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _googleSignInInit;

  // ── Getters ───────────────────────────────────────────────────────────────

  UserModel? get currentUser      => _user.value;
  bool       get isLoading        => _isLoading.value;
  bool       get isAuthenticated  => _isAuthenticated.value;
  bool       get isInitialized    => _isInitialized.value;
  String     get errorMessage     => _errorMessage.value;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _restoreSession();
    // Kick off Google Sign-In initialization eagerly (and only once) so the
    // later call to authenticate() from the button's onTap is the *first*
    // await in that gesture — required for the popup/GIS flow to be treated
    // as user-initiated on web.
    if (_isGoogleSignInSupported) {
      _googleSignInInit = _googleSignIn
          .initialize(serverClientId: _googleClientId)
          .catchError((_) {});
    }
  }

  bool get _isGoogleSignInSupported {
    if (kIsWeb) return true;
    try {
      return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  /// Restore session from saved JWT on app start.
  Future<void> _restoreSession() async {
    try {
      final hasSession = await _api.hasSession();
      if (hasSession) {
        // Load cached user immediately — no network required
        final cached = await _api.loadUserCache();
        if (cached != null) {
          _user.value = _parseUser(cached);
          _isAuthenticated.value = true;
        }
        // Mark ready so the splash screen can proceed without waiting for network
        _isInitialized.value = true;
        // Silently refresh profile in background
        _refreshProfileSilently();
        return;
      }
    } catch (_) {}
    _isInitialized.value = true;
  }

  /// Refresh user profile from network without blocking the UI.
  /// Only clears session on a definitive 401 — network errors keep the cached session.
  Future<void> _refreshProfileSilently() async {
    try {
      final response = await _api.apiGet('auth/me');
      if (response.statusCode == 200) {
        final body = response.body as Map<String, dynamic>;
        final userData = body['data'] as Map<String, dynamic>;
        _user.value = _parseUser(userData);
        _isAuthenticated.value = true;
        await _api.saveUserCache(userData);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        await signOut(silent: true);
      }
      // 5xx / network errors → keep the cached session
    } catch (_) {}
  }

  // ── Register ──────────────────────────────────────────────────────────────

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

      if (email.isEmpty || password.isEmpty) {
        _setError('Email and password are required');
        return false;
      }
      if (firstName.trim().isEmpty) { _setError('First name is required'); return false; }
      if (lastName.trim().isEmpty)  { _setError('Last name is required');  return false; }
      if (password.length < 6) {
        _setError('Password must be at least 6 characters');
        return false;
      }

      final response = await _api.apiPost(
        'auth/register',
        {
          'email':      email.trim().toLowerCase(),
          'password':   password,
          'first_name': firstName.trim(),
          'last_name':  lastName.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        },
        auth: false,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.body as Map<String, dynamic>;
        final userData = body['data']['user'] as Map<String, dynamic>;
        await _api.saveTokens(
          body['data']['access_token']  as String,
          body['data']['refresh_token'] as String,
        );
        await _api.saveUserCache(userData);
        _user.value = _parseUser(userData);
        _isAuthenticated.value = true;

        Get.snackbar(
          'Welcome to Mjengo Hub!',
          'Your account has been created.',
          backgroundColor: const Color(0xFF22C55E),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 10,
          duration: const Duration(seconds: 3),
        );

        Get.offAllNamed('/home');
        return true;
      } else {
        _setError(_extractError(response.body));
      }
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<bool> signInWithEmail({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      _setLoading(true);
      _setError('');

      if (email.isEmpty || password.isEmpty) {
        _setError('Email and password are required');
        return false;
      }

      final response = await _api.apiPost(
        'auth/login',
        {
          'email':    email.trim().toLowerCase(),
          'password': password,
        },
        auth: false,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.body as Map<String, dynamic>;
        final userData = body['data']['user'] as Map<String, dynamic>;
        await _api.saveTokens(
          body['data']['access_token']  as String,
          body['data']['refresh_token'] as String,
        );
        await _api.saveUserCache(userData);
        _user.value = _parseUser(userData);
        _isAuthenticated.value = true;

        Get.offAllNamed('/home');
        return true;
      } else if (response.statusCode == 401) {
        _setError('Invalid email or password');
      } else if (response.statusCode == 403) {
        _setError('Your account has been deactivated');
      } else {
        _setError(_extractError(response.body));
      }
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  // ── Google sign-in ────────────────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    if (!_isGoogleSignInSupported) {
      _setError('Google sign-in is not available on this platform.');
      return;
    }

    try {
      _setLoading(true);
      _setError('');

      await (_googleSignInInit ??=
          _googleSignIn.initialize(serverClientId: _googleClientId));

      final GoogleSignInAccount account = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null) {
        _setError('Google sign-in failed. Please try again.');
        return;
      }

      final response = await _api.apiPost(
        'auth/google',
        {'id_token': idToken},
        auth: false,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.body as Map<String, dynamic>;
        final userData = body['data']['user'] as Map<String, dynamic>;
        await _api.saveTokens(
          body['data']['access_token']  as String,
          body['data']['refresh_token'] as String,
        );
        await _api.saveUserCache(userData);
        _user.value = _parseUser(userData);
        _isAuthenticated.value = true;
        Get.offAllNamed('/home');
      } else if (response.statusCode == 403) {
        _setError('Your account has been deactivated');
      } else {
        _setError(_extractError(response.body));
      }
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled) {
        _setError('Google sign-in failed. Please try again.');
      }
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  /// Signs the user out of any active Google session as well as the app.
  Future<void> _signOutGoogle() async {
    try {
      if (_isGoogleSignInSupported) await _googleSignIn.signOut();
    } catch (_) {}
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<bool> fetchProfile() async {
    try {
      final response = await _api.apiGet('auth/me');
      if (response.statusCode == 200) {
        final body = response.body as Map<String, dynamic>;
        final userData = body['data'] as Map<String, dynamic>;
        _user.value = _parseUser(userData);
        _isAuthenticated.value = true;
        await _api.saveUserCache(userData);
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        await signOut(silent: true);
      }
      // Network/server errors — don't sign out, keep existing auth state
    } catch (_) {}
    return false;
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? bio,
    String? location,
    String? company,
    String? password,
  }) async {
    try {
      _setLoading(true);
      _setError('');

      final body = <String, dynamic>{
        if (firstName != null) 'first_name': firstName,
        if (lastName  != null) 'last_name':  lastName,
        if (phone     != null) 'phone':       phone,
        if (bio       != null) 'bio':         bio,
        if (location  != null) 'location':    location,
        if (company   != null) 'company':     company,
        if (password  != null && password.isNotEmpty) 'password': password,
      };

      final response = await _api.apiPut('auth/me', body);
      if (response.statusCode == 200) {
        final respBody = response.body as Map<String, dynamic>;
        _user.value = _parseUser(respBody['data'] as Map<String, dynamic>);
        return true;
      } else {
        _setError(_extractError(response.body));
      }
    } catch (e) {
      _setError('Failed to update profile. Please try again.');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  // ── Forgot password ───────────────────────────────────────────────────────

  /// Sends a password-reset link to [email] via the Mjengo backend.
  /// Returns `true` on a successful request (email may or may not exist —
  /// the backend always responds 200 to prevent enumeration).
  Future<bool> forgotPassword({required String email}) async {
    try {
      _setLoading(true);
      _setError('');

      final response = await _api.apiPost(
        'auth/forgot-password',
        {'email': email.trim().toLowerCase()},
        auth: false,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        _setError(_extractError(response.body));
      }
    } catch (e) {
      _setError('Unable to send reset email. Please try again.');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  // ── Sign out ──────────────────────────────────────────────────────────────

  Future<void> signOut({bool silent = false}) async {
    await _api.logout();
    await _signOutGoogle();
    _user.value = null;
    _isAuthenticated.value = false;
    _setError('');
    if (!silent) Get.offAllNamed('/login');
  }

  // ── Guest access ──────────────────────────────────────────────────────────

  /// Lets the user browse the app without an account. No session is created;
  /// features that require an account should check [isAuthenticated].
  void continueAsGuest() {
    Get.offAllNamed('/home');
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void clearError() => _setError('');

  void _setLoading(bool v) => _isLoading.value = v;
  void _setError(String v)  => _errorMessage.value = v;

  UserModel _parseUser(Map<String, dynamic> json) {
    return UserModel(
      uid:         json['id']?.toString() ?? '',
      email:       json['email'] as String?,
      firstName:   json['first_name'] as String?,
      lastName:    json['last_name'] as String?,
      phoneNumber: json['phone'] as String?,
      photoURL:    json['profile_image'] as String?,
      coverImageUrl: json['cover_image'] as String?,
      bio:         json['bio'] as String?,
      location:    json['location'] as String?,
      company:     json['company'] as String?,
      provider:    'email',
      isActive:    json['is_active'] as bool? ?? true,
      points:      (json['points'] as num?)?.toInt() ?? 0,
      referralCode: json['referral_code'] as String?,
      referredById: json['referred_by_id']?.toString(),
      isVerified:  json['is_verified'] as bool? ?? false,
      verificationExpiresAt: json['verification_expires_at'] != null
          ? DateTime.tryParse(json['verification_expires_at'].toString())
          : null,
      createdAt:   json['created_at'] != null
                       ? DateTime.tryParse(json['created_at'] as String)
                       : null,
    );
  }

  // ── Avatar / cover photo upload (Cloudflare R2-backed on the server) ────────

  Future<bool> uploadAvatar(List<int> bytes, String filename) async {
    try {
      _setLoading(true);
      final result = await _api.uploadMultipart(
        'auth/me/avatar',
        bytes,
        filename,
        fieldName: 'profile_image',
      );
      final code = result['_statusCode'] as int? ?? 500;
      if (code >= 200 && code < 300) {
        final data = (result['data'] as Map?)?.cast<String, dynamic>();
        if (data != null) {
          _user.value = _parseUser(data);
          await _api.saveUserCache(data);
        } else if (result['profile_image'] != null && _user.value != null) {
          _user.value = _user.value!.copyWith(photoURL: result['profile_image'] as String);
        }
        return true;
      }
      _setError(_extractError(result));
      return false;
    } catch (e) {
      _setError('Failed to upload photo. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> uploadCoverImage(List<int> bytes, String filename) async {
    try {
      _setLoading(true);
      final result = await _api.uploadMultipart(
        'auth/me/cover',
        bytes,
        filename,
        fieldName: 'cover_image',
      );
      final code = result['_statusCode'] as int? ?? 500;
      if (code >= 200 && code < 300) {
        final data = (result['data'] as Map?)?.cast<String, dynamic>();
        if (data != null) {
          _user.value = _parseUser(data);
          await _api.saveUserCache(data);
        } else if (result['cover_image'] != null && _user.value != null) {
          _user.value = _user.value!.copyWith(coverImageUrl: result['cover_image'] as String);
        }
        return true;
      }
      _setError(_extractError(result));
      return false;
    } catch (e) {
      _setError('Failed to upload cover photo. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  String _extractError(dynamic body) {
    if (body is Map<String, dynamic>) {
      return (body['error'] ?? body['message'] ?? 'Something went wrong').toString();
    }
    return 'Something went wrong';
  }
}
