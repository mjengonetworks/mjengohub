import 'dart:convert';

import 'package:http/http.dart' as http;

const String articleMicroSummaryApiRoot = 'https://mjengohub.co.ke/api';

class ArticleMicroSummaryResult {
  final bool success;
  final String? summary;
  final bool cached;
  final int? statusCode;
  final String? error;

  const ArticleMicroSummaryResult({
    required this.success,
    this.summary,
    this.cached = false,
    this.statusCode,
    this.error,
  });

  bool get isRateLimited => statusCode == 429;

  factory ArticleMicroSummaryResult.failure({String? error, int? statusCode}) =>
      ArticleMicroSummaryResult(
        success: false,
        error: error,
        statusCode: statusCode,
      );
}

/// Calls the public website endpoint directly because it is outside the
/// app's `/api/v1/` API prefix and does not require authentication.
class ArticleMicroSummaryService {
  final http.Client _client;
  final bool _ownsClient;

  ArticleMicroSummaryService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  Future<ArticleMicroSummaryResult> fetch(int articleId) async {
    if (articleId <= 0) {
      return ArticleMicroSummaryResult.failure(
        error: 'Article summary is unavailable.',
      );
    }

    final uri = Uri.parse(
      '$articleMicroSummaryApiRoot/articles/$articleId/micro-summary',
    );
    try {
      final response = await _client
          .post(
            uri,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: '{}',
          )
          .timeout(const Duration(seconds: 30));

      Map<String, dynamic>? body;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) body = decoded;
      } catch (_) {
        body = null;
      }

      final rawSummary = body?['summary'];
      final summary = rawSummary is String ? rawSummary.trim() : '';
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          body?['success'] == true &&
          summary.isNotEmpty) {
        return ArticleMicroSummaryResult(
          success: true,
          summary: summary,
          cached: body?['cached'] == true,
          statusCode: response.statusCode,
        );
      }

      return ArticleMicroSummaryResult.failure(
        statusCode: response.statusCode,
        error: _errorMessage(body, response.statusCode),
      );
    } on Exception {
      return ArticleMicroSummaryResult.failure(
        error: 'AI summary is temporarily unavailable. Please try again.',
      );
    }
  }

  String _errorMessage(Map<String, dynamic>? body, int statusCode) {
    final serverMessage = body?['error'];
    if (serverMessage is String && serverMessage.trim().isNotEmpty) {
      return serverMessage.trim();
    }
    if (statusCode == 429) {
      return 'Too many summary requests. Please try again shortly.';
    }
    if (statusCode == 404) return 'Article not found.';
    return 'AI summary is temporarily unavailable. Please try again.';
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
