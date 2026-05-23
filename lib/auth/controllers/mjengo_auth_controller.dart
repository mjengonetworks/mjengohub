import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  // ── Google sign-in (placeholder) ──────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    Get.snackbar(
      'Coming Soon',
      'Google sign-in will be available soon.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 10,
      duration: const Duration(seconds: 3),
    );
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

  // ── Sign out ──────────────────────────────────────────────────────────────

  Future<void> signOut({bool silent = false}) async {
    await _api.logout();
    _user.value = null;
    _isAuthenticated.value = false;
    _setError('');
    if (!silent) Get.offAllNamed('/login');
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void clearError() => _setError('');

  void _setLoading(bool v) => _isLoading.value = v;
  void _setError(String v)  => _errorMessage.value = v;

  UserModel _parseUser(Map<String, dynamic> json) {
    return UserModel(
      uid:        json['id']?.toString() ?? '',
      email:      json['email'] as String?,
      firstName:  json['first_name'] as String?,
      lastName:   json['last_name'] as String?,
      phoneNumber: json['phone'] as String?,
      photoURL:    json['profile_image'] as String?,
      bio:         json['bio'] as String?,
      provider:    'email',
      isActive:    json['is_active'] as bool? ?? true,
      createdAt:   json['created_at'] != null
                       ? DateTime.tryParse(json['created_at'] as String)
                       : null,
    );
  }

  String _extractError(dynamic body) {
    if (body is Map<String, dynamic>) {
      return (body['error'] ?? body['message'] ?? 'Something went wrong').toString();
    }
    return 'Something went wrong';
  }
}
