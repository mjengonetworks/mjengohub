import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:mjengo_hub_app/feed/controllers/feed_discussion_controller.dart';
import 'package:mjengo_hub_app/feed/controllers/feed_controller.dart';
import 'package:mjengo_hub_app/feed/models/feed_discussion_model.dart';
import 'package:mjengo_hub_app/feed/models/feed_model.dart';
import 'package:mjengo_hub_app/feed/screens/feed_discussion_screen.dart';
import 'package:mjengo_hub_app/feed/screens/feed_screen.dart';
import 'package:mjengo_hub_app/feed/services/feed_report_service.dart';
import 'package:mjengo_hub_app/feed/widgets/feed_report_button.dart';
import 'package:mjengo_hub_app/services/base_service.dart';

class _Api extends BaseService {
  Response response = const Response(
    statusCode: 201,
    body: {
      'success': true,
      'data': {'post_id': 42, 'status': 'reported'},
    },
  );
  String? path;
  dynamic payload;
  int calls = 0;
  @override
  Future<Response> postRequest(
    String path,
    dynamic body, {
    String? contentType,
    bool requireAuth = true,
  }) async {
    this.path = path;
    payload = body;
    calls++;
    return response;
  }
}

class _Reports extends FeedReportService {
  int calls = 0;
  String? explanation;
  FeedReportException? failure;
  bool duplicate = false;
  Completer<FeedReportResult>? pending;
  @override
  Future<FeedReportResult> report(
    int postId, {
    required String reason,
    String? explanation,
  }) async {
    calls++;
    this.explanation = explanation;
    if (failure != null) throw failure!;
    if (pending != null) return pending!.future;
    return FeedReportResult(postId: postId, alreadyReported: duplicate);
  }
}

Future<void> _open(
  WidgetTester tester,
  _Reports service, {
  bool authenticated = true,
  VoidCallback? onRequireAuth,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: FeedReportButton(
          postId: 42,
          authenticated: authenticated,
          onRequireAuth: onRequireAuth ?? () {},
          service: service,
        ),
      ),
    ),
  );
  await tester.tap(find.byTooltip('Report content'));
  await tester.pumpAndSettle();
}

Future<void> _reason(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Spam').last);
  await tester.pumpAndSettle();
}

void main() {
  test('report targets never confuse canonical IDs with FeedPost IDs', () {
    expect(const FeedItem(id: 42).reportPostId, 42);
    expect(const FeedItem(id: 9, postType: 'editorial').reportPostId, isNull);
    expect(
      const FeedItem(id: 9, postType: 'editorial', feedPostId: 42).reportPostId,
      42,
    );
    expect(const FeedItem(id: 0).reportPostId, isNull);
  });

  test(
    'service sends only report input and accepts new/duplicate responses',
    () async {
      final api = _Api();
      final service = FeedReportService(api: api);
      final result = await service.report(
        42,
        reason: 'spam',
        explanation: '  Context  ',
      );
      expect(api.path, 'feed/posts/42/report');
      expect(api.payload, {'reason': 'spam', 'explanation': 'Context'});
      expect(result.alreadyReported, isFalse);
      api.response = const Response(
        statusCode: 200,
        body: {
          'success': true,
          'data': {'post_id': 42, 'status': 'already_reported'},
        },
      );
      expect(
        (await service.report(42, reason: 'other')).alreadyReported,
        isTrue,
      );
      expect(api.payload, {'reason': 'other'});
    },
  );

  test(
    'all backend reasons and Unicode character limits are supported',
    () async {
      final api = _Api();
      final service = FeedReportService(api: api);
      for (final reason in feedReportReasons.keys) {
        await service.report(42, reason: reason, explanation: '🛠' * 400);
      }
      for (final action in [
        () => service.report(0, reason: 'spam'),
        () => service.report(42, reason: 'invalid'),
        () => service.report(42, reason: 'spam', explanation: 'x' * 401),
      ]) {
        await expectLater(action(), throwsA(isA<FeedReportException>()));
      }
      expect(api.calls, feedReportReasons.length);
    },
  );

  test(
    'validation, lifecycle, account, rate and JWT errors stay actionable',
    () async {
      final api = _Api();
      final service = FeedReportService(api: api);
      for (final code in [400, 401, 403, 404, 422, 429, 500, 503]) {
        api.response = Response(
          statusCode: code,
          body: {'success': false, 'error': 'Backend message'},
        );
        await expectLater(
          service.report(42, reason: 'spam'),
          throwsA(
            isA<FeedReportException>()
                .having((e) => e.statusCode, 'status', code)
                .having(
                  (e) => e.requiresSignIn,
                  'sign in',
                  code == 401 || code == 422,
                ),
          ),
        );
      }
      api.response = const Response(
        statusCode: 429,
        body: '<html>Unavailable</html>',
      );
      await expectLater(
        service.report(42, reason: 'spam'),
        throwsA(
          isA<FeedReportException>().having(
            (e) => e.message,
            'message',
            contains('Too many reports'),
          ),
        ),
      );
    },
  );

  test('malformed success or wrong target never confirms reporting', () async {
    final api = _Api();
    final service = FeedReportService(api: api);
    for (final data in [
      null,
      {'post_id': 99, 'status': 'reported'},
      {'post_id': 42, 'status': 'resolved'},
      {'post_id': 42},
    ]) {
      api.response = Response(
        statusCode: 201,
        body: {'success': true, 'data': data},
      );
      await expectLater(
        service.report(42, reason: 'spam'),
        throwsA(isA<FeedReportException>()),
      );
    }
  });

  testWidgets('guests request login without opening or submitting a report', (
    tester,
  ) async {
    var logins = 0;
    final service = _Reports();
    await _open(
      tester,
      service,
      authenticated: false,
      onRequireAuth: () => logins++,
    );
    expect(logins, 1);
    expect(service.calls, 0);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('reason/explanation validation and cancelling never submit', (
    tester,
  ) async {
    final service = _Reports();
    await _open(tester, service);
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a reason.'), findsOneWidget);
    await _reason(tester);
    await tester.enterText(find.byType(TextFormField), 'x' * 401);
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();
    expect(find.text('Use at most 400 characters.'), findsOneWidget);
    expect(service.calls, 0);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('prevents double submission and confirms reporting', (
    tester,
  ) async {
    final service = _Reports()..pending = Completer<FeedReportResult>();
    await _open(tester, service);
    await _reason(tester);
    await tester.tap(find.text('Send report'));
    await tester.pump();
    await tester.tap(find.text('Sending…'));
    await tester.pump();
    expect(service.calls, 1);
    service.pending!.complete(const FeedReportResult(postId: 42));
    await tester.pumpAndSettle();
    expect(find.text('Report sent to the moderation team.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
    'rate errors keep input and duplicate retry closes with feedback',
    (tester) async {
      final service = _Reports()
        ..failure = const FeedReportException(
          'Please try again shortly.',
          statusCode: 429,
        );
      await _open(tester, service);
      await _reason(tester);
      await tester.enterText(find.byType(TextFormField), 'Context');
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(find.text('Please try again shortly.'), findsOneWidget);
      expect(find.text('Context'), findsOneWidget);
      service.failure = null;
      service.duplicate = true;
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(service.explanation, 'Context');
      expect(
        find.text('You have already reported this content.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'expired JWT offers reauthentication even for a cached signed-in user',
    (tester) async {
      var logins = 0;
      final service = _Reports()
        ..failure = const FeedReportException(
          'Session expired.',
          statusCode: 401,
        );
      await _open(tester, service, onRequireAuth: () => logins++);
      await _reason(tester);
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign in again'));
      await tester.pumpAndSettle();
      expect(logins, 1);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets('discussion exposes root, comment and nested reply report IDs', (
    tester,
  ) async {
    final controller = FeedDiscussionController(42);
    controller.comments.assignAll(const [
      FeedComment(
        id: 50,
        content: 'Comment',
        replies: [FeedComment(id: 51, content: 'Nested', parentId: 50)],
      ),
    ]);
    await tester.pumpWidget(
      GetMaterialApp(
        home: FeedDiscussionScreen(
          post: const FeedItem(id: 42, feedPostId: 42, text: 'Root'),
          controller: controller,
        ),
      ),
    );
    await tester.pump();
    expect(
      tester
          .widgetList<FeedReportButton>(find.byType(FeedReportButton))
          .map((w) => w.postId),
      [42, 50, 51],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('timeline exposes only reportable FeedPost targets', (
    tester,
  ) async {
    final controller = FeedController(loadOnInit: false);
    controller.items.assignAll(const [
      FeedItem(id: 10, text: 'Community'),
      FeedItem(id: 11, postType: 'editorial', text: 'Canonical only'),
      FeedItem(
        id: 12,
        postType: 'editorial',
        feedPostId: 99,
        text: 'Feed source',
      ),
    ]);
    await tester.pumpWidget(
      GetMaterialApp(home: FeedScreen(controller: controller)),
    );
    await tester.pump();
    expect(
      tester
          .widgetList<FeedReportButton>(find.byType(FeedReportButton))
          .map((w) => w.postId),
      [10, 99],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('report dialog fits a 320px screen and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final service = _Reports();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Scaffold(
          body: FeedReportButton(
            postId: 42,
            authenticated: true,
            onRequireAuth: () {},
            service: service,
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Report content'));
    await tester.pumpAndSettle();
    await _reason(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });
}
