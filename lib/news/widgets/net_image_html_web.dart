// lib/news/widgets/net_image_html_web.dart
//
// Web-only image rendering: paints a genuine DOM `<img>` element via a
// platform view instead of letting CanvasKit fetch + decode the image bytes
// itself. CanvasKit needs `Access-Control-Allow-Origin` on the response to
// fetch cross-origin image bytes for its WebGL texture upload -- without it
// the fetch throws a CORS error and the image never renders ("canvas
// tainted by cross-origin data"). A plain `<img src="...">` tag has no such
// requirement to simply *display* a cross-origin image (only *reading pixel
// data back out* of a canvas needs CORS), so routing through one sidesteps
// the failure entirely without needing any change on the mjengohub.co.ke
// server. Only reached via the conditional import in net_image.dart, which
// picks this file over net_image_html_stub.dart when `dart.library.html` is
// available (i.e. compiling for web).
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

int _viewCounter = 0;

/// Registers a fresh platform view for [url] and returns the widget that
/// hosts it. Call once per widget instance (e.g. from `initState`/on URL
/// change) rather than on every rebuild -- each call registers a new view
/// factory that is never unregistered, so calling this from `build()` would
/// leak an ever-growing number of factories.
Widget buildHtmlNetworkImage({
  required String url,
  required BoxFit fit,
  required VoidCallback onError,
}) {
  final viewType = 'mjengohub-net-image-${_viewCounter++}';

  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final img = html.ImageElement()
      ..src = url
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = _cssObjectFit(fit)
      ..style.border = 'none'
      ..style.display = 'block';
    img.onError.listen((_) => onError());
    return img;
  });

  return HtmlElementView(viewType: viewType);
}

String _cssObjectFit(BoxFit fit) {
  switch (fit) {
    case BoxFit.fill:
      return 'fill';
    case BoxFit.contain:
      return 'contain';
    case BoxFit.cover:
      return 'cover';
    // CSS object-fit has no distinct "fit width only" / "fit height only"
    // keyword -- 'cover' is the closest visual approximation for both.
    case BoxFit.fitWidth:
    case BoxFit.fitHeight:
      return 'cover';
    case BoxFit.none:
      return 'none';
    case BoxFit.scaleDown:
      return 'scale-down';
  }
}
