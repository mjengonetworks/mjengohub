import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mjengo_hub_app/feed/models/feed_contract.dart';
import 'package:mjengo_hub_app/feed/screens/feed_screen.dart';

void main() {
  test('exposes the website Feed tabs without claiming native support', () {
    expect(FeedTab.values.map((tab) => tab.label), [
      'For You',
      'Following',
      'Trending',
      'Topics',
      'Discussions',
      'Messages',
      'Calls',
    ]);
    expect(FeedTab.values.every((tab) => !tab.hasNativeApi), isTrue);
    expect(FeedContract.hasNativeReadApi, isFalse);
    expect(FeedContract.hasNativePublishApi, isFalse);
  });

  testWidgets('renders the honest native Feed foundation state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: FeedScreen()));

    expect(find.text('Media & Feed'), findsOneWidget);
    expect(
      find.text("What's happening in the built environment?"),
      findsOneWidget,
    );
    expect(
      find.text('The native timeline is not connected yet.'),
      findsOneWidget,
    );
    expect(find.text('Open Feed on website'), findsOneWidget);
    expect(find.text('Open Media Directory'), findsOneWidget);
  });
}
