import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// HTTP client that talks to the Mjengo Hub Flask API.
/// Automatically attaches the saved JWT access token to every request.
class MjengoService extends GetConnect {
  static const String _apiBaseUrl = 'http://192.168.100.224:8080/api/v1/';

  static const String _accessTokenKey  = 'mjengo_access_token';
  static const String _refreshTokenKey = 'mjengo_refresh_token';

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
      req.headers['Accept']       = 'application/json';
      req.headers['Content-Type'] = 'application/json';
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

  Response _networkError(Object e) => Response(
        statusCode: 500,
        statusText: 'Network error',
        body: {'error': e.toString()},
      );

  // ── Session logout ─────────────────────────────────────────────────────────

  Future<void> logout() => _clearTokens();
}
