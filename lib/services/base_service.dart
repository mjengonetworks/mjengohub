import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class BaseService extends GetConnect {


  //static const String _apiBase = 'https://mjengohub.co.ke/api/v1/';

  static const String _apiBase  = 'http://192.168.0.102:8080/api/v1/';
  String get apiBase => _apiBase;
  //static const String _testBase = 'https://test.mjengohub.co.ke/api/v1/';

  bool _isSetup = false;
  
  void _setup() {
    if (_isSetup) return;
    _isSetup = true;

    httpClient.baseUrl = _apiBase;
    httpClient.timeout = const Duration(seconds: 60);

    httpClient.addRequestModifier<dynamic>((request) async {
      request.headers['Accept'] = 'application/json';
      if (!kIsWeb) {
        // These headers trigger CORS preflight on web and are either blocked
        // (User-Agent is a forbidden header) or rejected by strict browsers.
        request.headers['User-Agent'] = 'Flutter/GetConnect Dart/3.0.0';
      }

      final token = await _getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      print('Request URL: ${request.url}');
      print('Request Method: ${request.method}');
      print('Request Headers: ${request.headers}');

      return request;
    });

    httpClient.addResponseModifier<dynamic>((request, response) {
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.bodyString}');

      if (response.status.connectionError) {
        print('Connection Error detected');
        return const Response(
          statusText: 'No internet connection. Please check your network.',
          statusCode: 503,
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Request successful: ${request.url}');
      } else {
        print('❌ Request failed: ${response.statusCode} - ${response.statusText}');
      }

      return response;
    });

    print('BaseService initialized with URL: $_apiBase');
  }

  @override
  void onInit() {
    super.onInit();
    _setup();
  }

  // Method to get Firebase token
  Future<String?> _getToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      return await user?.getIdToken();
    } catch (e) {
      print('Error getting Firebase token: $e');
      return null;
    }
  }

  // Generic GET request with better error handling
  Future<Response> getRequest(String endpoint,
      {Map<String, dynamic>? query}) async {
    _setup();
    try {
      String cleanEndpoint = endpoint.replaceAll(RegExp(r'^/+'), '');
      print('Making GET request to: ${httpClient.baseUrl}$cleanEndpoint');
      final response = await get(cleanEndpoint, query: query);
      return _handleResponse(response);
    } catch (e) {
      print('GET request error: $e');
      return Response(
          statusText: 'Network error: $e',
          statusCode: 500,
          body: {'error': 'NETWORK_ERROR', 'message': e.toString()}
      );
    }
  }

  // POST request with better authentication handling
  Future<Response> postRequest(String path, dynamic body,
      {String? contentType, bool requireAuth = true}) async {
    _setup();
    try {
      String cleanPath = path.replaceAll(RegExp(r'^/+'), '');
      print('Making POST request to: ${httpClient.baseUrl}$cleanPath');
      print('Request body type: ${body.runtimeType}');

      // Let GetConnect and request modifier handle everything
      final response = await post(cleanPath, body);
      return _handleResponse(response);
    } catch (e) {
      print('POST request error: $e');
      return Response(
          statusText: 'Network error: $e',
          statusCode: 500,
          body: {'error': 'NETWORK_ERROR', 'message': e.toString()}
      );
    }
  }

  // POST request without authentication
  Future<Response> postRequestNoAuth(String path, dynamic body,
      {String? contentType}) async {
    _setup();
    try {
      String cleanPath = path.replaceAll(RegExp(r'^/+'), '');
      print('Making unauthenticated POST request to: ${httpClient.baseUrl}$cleanPath');
      print('Request body type: ${body.runtimeType}');

      final response = await post(cleanPath, body);
      return _handleResponse(response);
    } catch (e) {
      print('POST request (no auth) error: $e');
      return Response(
          statusText: 'Network error: $e',
          statusCode: 500,
          body: {'error': 'NETWORK_ERROR', 'message': e.toString()}
      );
    }
  }

  // PUT request
  Future<Response> putRequest(String path, dynamic body,
      {String? contentType}) async {
    _setup();
    try {
      String cleanPath = path.replaceAll(RegExp(r'^/+'), '');
      print('Making PUT request to: ${httpClient.baseUrl}$cleanPath');
      print('Request body type: ${body.runtimeType}');

      final response = await put(cleanPath, body);
      return _handleResponse(response);
    } catch (e) {
      print('PUT request error: $e');
      return Response(
          statusText: 'Network error: $e',
          statusCode: 500,
          body: {'error': 'NETWORK_ERROR', 'message': e.toString()}
      );
    }
  }

  Future<Response> deleteRequest(String path, {Map<String, dynamic>? query}) async {
    _setup();
    try {
      String cleanPath = path.replaceAll(RegExp(r'^/+'), '');
      print('Making DELETE request to: ${httpClient.baseUrl}$cleanPath');

      final response = await delete(cleanPath, query: query);
      return _handleResponse(response);
    } catch (e) {
      print('DELETE request error: $e');
      return Response(
          statusText: 'Network error: $e',
          statusCode: 500,
          body: {'error': 'NETWORK_ERROR', 'message': e.toString()}
      );
    }
  }

  Future<Response> patchRequest(String path, dynamic body,
      {String? contentType}) async {
    _setup();
    try {
      String cleanPath = path.replaceAll(RegExp(r'^/+'), '');
      print('Making PATCH request to: ${httpClient.baseUrl}$cleanPath');

      final response = await patch(cleanPath, body);
      return _handleResponse(response);
    } catch (e) {
      print('PATCH request error: $e');
      return Response(
          statusText: 'Network error: $e',
          statusCode: 500,
          body: {'error': 'NETWORK_ERROR', 'message': e.toString()}
      );
    }
  }

  // DELETE request with a JSON body (non-standard but required by some endpoints)
  Future<Response> deleteWithBodyRequest(String path, Map<String, dynamic> body) async {
    _setup();
    try {
      String cleanPath = path.replaceAll(RegExp(r'^/+'), '');
      print('Making DELETE (with body) request to: ${httpClient.baseUrl}$cleanPath');
      final response = await request(cleanPath, 'DELETE', body: body);
      return _handleResponse(response);
    } catch (e) {
      print('DELETE (with body) request error: $e');
      return Response(
          statusText: 'Network error: $e',
          statusCode: 500,
          body: {'error': 'NETWORK_ERROR', 'message': e.toString()}
      );
    }
  }

  Response _handleResponse(Response response) {
    print('Handling response: ${response.statusCode}');

    if (response.status.connectionError) {
      print('❌ Connection Error');
      return const Response(
          statusText: 'No internet connection. Please check your network.',
          statusCode: 503,
          body: {
            'error': 'CONNECTION_ERROR',
            'message': 'No internet connection. Please check your network.',
          }
      );
    }

    final code = response.statusCode;
    if (code == null) return response;

    if (code == 401) {
      print('❌ Unauthorized: token missing or expired');
      return Response(
          statusText: 'Unauthorized',
          statusCode: 401,
          body: response.body ?? {
            'error': 'UNAUTHORIZED',
            'message': 'Session expired. Please sign in again.',
          }
      );
    }

    if (code == 429) {
      print('❌ Rate limited by server');
      return Response(
          statusText: 'Too many requests',
          statusCode: 429,
          body: response.body ?? {
            'error': 'RATE_LIMITED',
            'message': 'Too many requests, please try again later.',
          }
      );
    }

    if (code == 413) {
      print('❌ Payload too large');
      return Response(
          statusText: 'Payload too large',
          statusCode: 413,
          body: response.body ?? {
            'error': 'PAYLOAD_TOO_LARGE',
            'message': 'Request too large.',
          }
      );
    }

    if (code >= 500) {
      print('❌ Server Error: $code');
      return Response(
          statusText: 'Server error',
          statusCode: code,
          body: response.body ?? {
            'error': 'SERVER_ERROR',
            'message': 'Internal server error.',
          }
      );
    }

    if (code >= 400) {
      print('❌ Client Error: $code');
      return Response(
          statusText: 'Client error',
          statusCode: code,
          body: response.body ?? {
            'error': 'CLIENT_ERROR',
            'message': 'Bad request.',
          }
      );
    }

    print('✅ Response OK: $code');
    return response;
  }

  Future<int> uploadFile(
    String endpoint,
    List<int> bytes,
    String filename, {
    String fieldName = 'file',
    Map<String, String>? fields,
  }) async {
    _setup();
    try {
      final token = await _getToken();
      final uri = Uri.parse('$_apiBase${endpoint.replaceAll(RegExp(r'^/+'), '')}');
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
      return streamed.statusCode;
    } catch (e) {
      print('uploadFile error: $e');
      return 500;
    }
  }

  Future<bool> testConnection() async {
    try {
      print('Testing connection to server...');
      // /health is served at root level, outside /api/v1/ prefix
      final baseWithoutPath = httpClient.baseUrl!.replaceAll(RegExp(r'api/v1/?$'), '');
      final response = await get('${baseWithoutPath}health');

      if (response.statusCode == 200) {
        print('✅ Connection test successful');
        print('Server response: ${response.body}');
        return true;
      } else {
        print('❌ Connection test failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Connection test error: $e');
      return false;
    }
  }

  Future<bool> testFlutterEndpoint() async {
    try {
      print('Testing Flutter-specific endpoint...');
      final response = await post(
          'test-flutter',
          {'test': 'Flutter connection'}
      );

      if (response.statusCode == 200) {
        print('✅ Flutter endpoint test successful');
        print('Server response: ${response.body}');
        return true;
      } else {
        print('❌ Flutter endpoint test failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Flutter endpoint test error: $e');
      return false;
    }
  }
}