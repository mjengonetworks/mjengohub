import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// HTTP client that talks to the Mjengo Hub Flask API.
/// Automatically attaches the saved JWT access token to every request.
class MjengoService extends GetConnect {
 static const String _apiBaseUrl = 'https://mjengohub.co.ke/api/v1/';

  //static const String _apiBaseUrl = 'http://192.168.0.102:8080/api/v1/';


  static const String _accessTokenKey  = 'mjengo_access_token';
  static const String _refreshTokenKey = 'mjengo_refresh_token';
  static const String _cachedUserKey   = 'mjengo_cached_user';

  bool _ready = false;

  @override
  void onInit() {
    super.onInit();
    _configure();
  }

  void _configure() {
    if (_ready) return;
    _ready = true;

    httpClient.baseUrl = _apiBaseUrl;
    httpClient.timeout = const Duration(seconds: 30);

    httpClient.addRequestModifier<dynamic>((req) async {
      req.headers['Accept'] = 'application/json';
      // Only set Content-Type on requests that have a body (POST / PUT / PATCH).
      // Setting it on GET triggers the browser to also set content-length,
      // which is a forbidden header on web and causes request failures.
      final method = req.method?.toUpperCase() ?? '';
      if (method == 'POST' || method == 'PUT' || method == 'PATCH') {
        req.headers['Content-Type'] = 'application/json';
      }
      final token = await getAccessToken();
      if (token != null) req.headers['Authorization'] = 'Bearer $token';
      return req;
    });

    httpClient.addResponseModifier<dynamic>((req, res) {
      // Drop only the (now stale) access token. The refresh token is
      // deliberately kept so `refreshAccessToken()` still has something to
      // work with — clearing both here made `auth/refresh` unreachable.
      if (res.statusCode == 401) _clearAccessToken();
      return res;
    });
  }

  // ── Token storage ──────────────────────────────────────────────────────────

  Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey,  access);
    await prefs.setString(_refreshTokenKey, refresh);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> _clearAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
  }

  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  /// Exchanges the stored refresh token for a fresh access token via
  /// `POST auth/refresh`.
  ///
  /// This deliberately bypasses [httpClient]: the request modifier always
  /// attaches the *access* token, but this endpoint is
  /// `@jwt_required(refresh=True)` and needs the *refresh* token in the
  /// Authorization header. Going through raw `http` also keeps it clear of the
  /// 401 response modifier.
  ///
  /// Returns the new access token, or null when refresh isn't possible (no
  /// refresh token stored, expired refresh token, or a network failure). A
  /// definitive 401/422 from the server clears the session, since the refresh
  /// token itself is no longer usable.
  Future<String?> refreshAccessToken() async {
    final refresh = await getRefreshToken();
    if (refresh == null || refresh.isEmpty) return null;
    try {
      final res = await http.post(
        Uri.parse('${_apiBaseUrl}auth/refresh'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $refresh',
        },
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        // Unpacked step by step rather than with a null-aware index inside a
        // ternary: Dart can't disambiguate `cond ? a?[b] : c` and fails to parse.
        Object? token;
        if (decoded is Map) {
          final data = decoded['data'];
          if (data is Map) token = data['access_token'];
        }
        if (token is String && token.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_accessTokenKey, token);
          print('🔐 Access token refreshed');
          return token;
        }
      }
      // 401 = refresh token rejected, 422 = malformed/not a refresh token.
      if (res.statusCode == 401 || res.statusCode == 422) {
        print('🔐 Refresh token rejected (${res.statusCode}) — clearing session');
        await _clearTokens();
      }
    } catch (e) {
      // Network/timeout: keep the refresh token so a later attempt can retry.
      print('❌ refreshAccessToken failed: $e');
    }
    return null;
  }

  // ── User cache ─────────────────────────────────────────────────────────────

  Future<void> saveUserCache(Map<String, dynamic> userJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedUserKey, jsonEncode(userJson));
  }

  Future<Map<String, dynamic>?> loadUserCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_cachedUserKey);
      if (str == null || str.isEmpty) return null;
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearUserCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedUserKey);
  }

  /// True when there is anything left to restore a session from. The refresh
  /// token counts: an expired access token is cleared by the 401 modifier, but
  /// the session is still recoverable via [refreshAccessToken].
  Future<bool> hasSession() async {
    final access = await getAccessToken();
    if (access != null && access.isNotEmpty) return true;
    final refresh = await getRefreshToken();
    return refresh != null && refresh.isNotEmpty;
  }

  // ── HTTP helpers ───────────────────────────────────────────────────────────

  Future<Response> apiGet(String path, {Map<String, dynamic>? query}) async {
    _configure();
    try {
      return _wrap(await get(path.replaceAll(RegExp(r'^/+'), ''), query: query));
    } catch (e) {
      return _networkError(e);
    }
  }

  Future<Response> apiPost(String path, dynamic body, {bool auth = true}) async {
    _configure();
    try {
      if (!auth) {
        // POST without token – used for login/register
        final response = await post(
          path.replaceAll(RegExp(r'^/+'), ''),
          body,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        );
        return _wrap(response);
      }
      return _wrap(await post(path.replaceAll(RegExp(r'^/+'), ''), body));
    } catch (e) {
      return _networkError(e);
    }
  }

  Future<Response> apiPut(String path, dynamic body) async {
    _configure();
    try {
      return _wrap(await put(path.replaceAll(RegExp(r'^/+'), ''), body));
    } catch (e) {
      return _networkError(e);
    }
  }

  Future<Response> apiDelete(String path) async {
    _configure();
    try {
      return _wrap(await delete(path.replaceAll(RegExp(r'^/+'), '')));
    } catch (e) {
      return _networkError(e);
    }
  }

  Response _wrap(Response r) {
    if (r.status.connectionError) {
      return const Response(
        statusCode: 503,
        statusText: 'No internet connection',
        body: {'error': 'No internet connection'},
      );
    }
    return r;
  }

  /// Multipart upload (avatars, cover photos, project renders, copyright
  /// claim proof) using the same JWT session as every other request.
  /// Returns the decoded JSON body, or `{'error': ...}` on failure.
  Future<Map<String, dynamic>> uploadMultipart(
    String path,
    List<int> bytes,
    String filename, {
    String fieldName = 'file',
    Map<String, String>? fields,
  }) async {
    try {
      final token = await getAccessToken();
      final uri = Uri.parse('$_apiBaseUrl${path.replaceAll(RegExp(r'^/+'), '')}');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Accept'] = 'application/json';
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      if (fields != null) request.fields.addAll(fields);
      request.files.add(http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: filename,
      ));
      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode == 401) await _clearTokens();
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          return {...decoded, '_statusCode': streamed.statusCode};
        }
      } catch (_) {}
      return {
        '_statusCode': streamed.statusCode,
        if (streamed.statusCode >= 200 && streamed.statusCode < 300) 'success': true
        else 'error': 'Upload failed (${streamed.statusCode})',
      };
    } catch (e) {
      return {'error': e.toString(), '_statusCode': 500};
    }
  }

  Response _networkError(Object e) => Response(
        statusCode: 500,
        statusText: 'Network error',
        body: {'error': e.toString()},
      );

  // ── Session logout ─────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _clearTokens();
    await clearUserCache();
  }
}
