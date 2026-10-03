import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mjengo_hub_app/news/widgets/article_ai_summary_card.dart';

void main() {
  testWidgets('shows the initial summary button and invokes request', (
    tester,
  ) async {
    var requests = 0;
    await tester.pumpWidget(
      _testApp(
        ArticleAiSummaryCard(onRequest: () => requests++, onSignIn: () {}),
      ),
    );

    expect(find.text('Quick AI Summary'), findsOneWidget);
    await tester.tap(find.text('Quick AI Summary'));
    expect(requests, 1);
  });

  testWidgets('shows loading state and disables request', (tester) async {
    var requests = 0;
    await tester.pumpWidget(
      _testApp(
        ArticleAiSummaryCard(
          loading: true,
          onRequest: () => requests++,
          onSignIn: () {},
        ),
      ),
    );

    expect(find.text('Summarizing…'), findsOneWidget);
    await tester.tap(find.text('Summarizing…'));
    expect(requests, 0);
  });

  testWidgets('shows cached summary presentation', (tester) async {
    await tester.pumpWidget(
      _testApp(
        ArticleAiSummaryCard(
          summary: 'Cached summary.',
          cached: true,
          onRequest: () {},
          onSignIn: () {},
        ),
      ),
    );

    expect(find.text('Cached summary.'), findsOneWidget);
    expect(find.text('CACHED'), findsOneWidget);
    expect(find.text('Quick AI Summary'), findsNothing);
  });

  testWidgets('shows error and retry control', (tester) async {
    var requests = 0;
    await tester.pumpWidget(
      _testApp(
        ArticleAiSummaryCard(
          requested: true,
          error: 'Rate limited.',
          onRequest: () => requests++,
          onSignIn: () {},
        ),
      ),
    );

    expect(find.text('Rate limited.'), findsOneWidget);
    expect(find.text('Retry AI Summary'), findsOneWidget);
    await tester.tap(find.text('Retry AI Summary'));
    expect(requests, 1);
  });

  testWidgets('shows signed-out chat sign-in inside the AI card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ArticleAiSummaryCard(
            summary: 'Summary text.',
            signedIn: false,
            onRequest: () {},
            onSignIn: () {},
          ),
        ),
      ),
    );

    expect(find.text('MJENGO HUB AI'), findsOneWidget);
    expect(find.text('Summary text.'), findsOneWidget);
    expect(find.text('Sign in to Chat'), findsOneWidget);
  });

  testWidgets('does not show chat sign-in for signed-in users', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ArticleAiSummaryCard(
            summary: 'Summary text.',
            signedIn: true,
            onRequest: () {},
            onSignIn: () {},
          ),
        ),
      ),
    );

    expect(find.text('MJENGO HUB AI'), findsOneWidget);
    expect(find.text('Summary text.'), findsOneWidget);
    expect(find.text('Sign in to Chat'), findsNothing);
  });

  testWidgets('keeps controls usable in a narrow viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _testApp(
        ArticleAiSummaryCard(
          summary: 'A summary that remains readable on a narrow screen.',
          onRequest: () {},
          onSignIn: () {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final signInButton = find.ancestor(
      of: find.text('Sign in to Chat'),
      matching: find.byType(TextButton),
    );
    expect(tester.getSize(signInButton).height, greaterThanOrEqualTo(44));
  });

  testWidgets('provides at least a 44 logical pixel summary tap target', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(ArticleAiSummaryCard(onRequest: () {}, onSignIn: () {})),
    );

    final button = find.ancestor(
      of: find.text('Quick AI Summary'),
      matching: find.byType(OutlinedButton),
    );
    expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
  });
}

Widget _testApp(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}
