import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:mjengo_hub_app/news/services/article_micro_summary_service.dart';

void main() {
  test('parses a successful generated summary', () async {
    final service = ArticleMicroSummaryService(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://mjengohub.co.ke/api/articles/42/micro-summary',
        );
        return http.Response(
          jsonEncode({'success': true, 'summary': 'A concise summary.'}),
          200,
        );
      }),
    );

    final result = await service.fetch(42);

    expect(result.success, isTrue);
    expect(result.summary, 'A concise summary.');
    expect(result.cached, isFalse);
  });

  test('parses a cached summary', () async {
    final service = ArticleMicroSummaryService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'success': true,
            'summary': 'Cached summary.',
            'cached': true,
          }),
          200,
        ),
      ),
    );

    final result = await service.fetch(42);

    expect(result.success, isTrue);
    expect(result.cached, isTrue);
  });

  test('rejects a missing article id without making a request', () async {
    var requests = 0;
    final service = ArticleMicroSummaryService(
      client: MockClient((_) async {
        requests++;
        return http.Response('{}', 500);
      }),
    );

    final result = await service.fetch(0);

    expect(result.success, isFalse);
    expect(result.statusCode, isNull);
    expect(requests, 0);
  });

  test('returns server errors and rate limiting distinctly', () async {
    final serverError = ArticleMicroSummaryService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'success': false, 'error': 'AI unavailable.'}),
          503,
        ),
      ),
    );
    final rateLimited = ArticleMicroSummaryService(
      client: MockClient((_) async => http.Response('{}', 429)),
    );

    final serverResult = await serverError.fetch(42);
    final rateResult = await rateLimited.fetch(42);

    expect(serverResult.success, isFalse);
    expect(serverResult.error, 'AI unavailable.');
    expect(rateResult.isRateLimited, isTrue);
    expect(rateResult.error, contains('Too many'));
  });

  test('rejects missing or malformed summary data', () async {
    final missing = ArticleMicroSummaryService(
      client: MockClient(
        (_) async => http.Response(jsonEncode({'success': true}), 200),
      ),
    );
    final malformed = ArticleMicroSummaryService(
      client: MockClient(
        (_) async =>
            http.Response(jsonEncode({'success': true, 'summary': 42}), 200),
      ),
    );

    expect((await missing.fetch(42)).success, isFalse);
    expect((await malformed.fetch(42)).success, isFalse);
  });
}
