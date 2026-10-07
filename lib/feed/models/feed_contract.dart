// lib/feed/models/feed_contract.dart
//
// Native Feed reads and authenticated text publishing use the deployed mobile
// API. Engagement, following and other social actions remain separate.

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
  static const nativePublishEndpoint = <String>['feed/posts'];

  static bool get hasNativeReadApi => nativeReadEndpoint.isNotEmpty;
  static bool get hasNativePublishApi => nativePublishEndpoint.isNotEmpty;
}
