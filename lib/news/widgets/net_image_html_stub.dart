// lib/news/widgets/net_image_html_stub.dart
//
// Non-web fallback target for the conditional import in net_image.dart.
// NetImage only ever calls into this API when `kIsWeb` is true, so this
// stub is never actually invoked on Android/iOS/macOS/Windows/Linux --  it
// exists purely so the conditional-import target still type-checks when
// compiling for those platforms (which can't import `dart:html`/`dart:ui_web`
// at all).
import 'package:flutter/material.dart';

Widget buildHtmlNetworkImage({
  required String url,
  required BoxFit fit,
  required VoidCallback onError,
}) {
  return const SizedBox.shrink();
}
