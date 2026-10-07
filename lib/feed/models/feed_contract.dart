// lib/feed/models/feed_contract.dart
//
// The current website Feed is server-rendered at /feed. There is no
// /api/v1/feed JSON contract yet, so the native surface must not invent a
// second timeline or silently compose one from unrelated API resources.

enum FeedTab {
  forYou('For You'),
  following('Following'),
  trending('Trending'),
  topics('Topics'),
  discussions('Discussions'),
  messages('Messages'),
  calls('Calls');

  final String label;
  const FeedTab(this.label);

  bool get hasNativeApi => this == FeedTab.forYou;
}

class FeedContract {
  FeedContract._();

  static const websiteUrl = 'https://mjengohub.co.ke/feed';
  static const nativeReadEndpoint = <String>['feed'];
  static const nativePublishEndpoint = <String>[];

  static bool get hasNativeReadApi => nativeReadEndpoint.isNotEmpty;
  static bool get hasNativePublishApi => nativePublishEndpoint.isNotEmpty;
}
