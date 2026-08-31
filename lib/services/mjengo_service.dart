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
      if (res.statusCode == 401) _clearTokens();
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

  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
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

  Future<bool> hasSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
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
