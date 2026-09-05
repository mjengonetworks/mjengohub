// lib/news/widgets/net_image.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'net_image_html_stub.dart' if (dart.library.html) 'net_image_html_web.dart' as html_image;

/// Normalizes a possibly-relative or possibly-insecure image URL into an
/// absolute `https://mjengohub.co.ke/...` URL. Several model `imageUrl`
/// getters across the app already prepend the production host to bare
/// relative paths (e.g. `/static/uploads/...`), but pass an already-`http://`
/// URL straight through unchanged -- which Flutter web silently fails to
/// load on the HTTPS-hosted app (mixed-content blocking) and looks exactly
/// like a broken image. This is the single normalization point every
/// [NetImage] goes through regardless of what its caller already did, so
/// it's safe/idempotent to call even on an already-resolved URL.
String? resolveImageUrl(String? raw) {
  if (raw == null) return null;
  final url = raw.trim();
  if (url.isEmpty) return null;
  if (url.startsWith('http://')) return 'https://${url.substring('http://'.length)}';
  if (url.startsWith('https://')) return url;
  return 'https://mjengohub.co.ke${url.startsWith('/') ? '' : '/'}$url';
}

/// Network image with a shimmer placeholder and graceful error fallback.
///
/// On mobile/desktop: uses [Image.network] with a [Referer] header so
/// cPanel hotlink-protection doesn't block the request.
///
/// On web: renders through a genuine DOM `<img>` element instead
/// (`_WebNetImage`/net_image_html_web.dart) rather than [Image.network].
/// CanvasKit fetches image bytes itself for WebGL texture upload, which
/// requires `Access-Control-Allow-Origin` from the server — mjengohub.co.ke
/// doesn't send it for static uploads, so [Image.network] fails outright on
/// web. A plain `<img>` has no such requirement just to display an image.
class NetImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color placeholderColor;
  final Map<String, String>? extraHeaders;

  /// Overrides the default image/broken-image icon shown when there's no
  /// URL or the load fails. Useful for context-specific fallbacks (a video
  /// camera icon for video thumbnails, a building icon for projects, …)
  /// without every screen re-implementing its own placeholder Container.
  final IconData? placeholderIcon;
  final Color placeholderIconColor;
  final double placeholderIconSize;

  /// Full custom fallback, used for both the no-URL and load-failure cases
  /// instead of [placeholderIcon]. For things a generic icon can't express —
  /// e.g. a user's initials on an avatar.
  final Widget Function(BuildContext context)? errorBuilder;

  // Used only on mobile — cPanel hotlink-protection bypass.
  static const Map<String, String> _mobileHeaders = {
    'Referer': 'https://mjengohub.co.ke',
    'User-Agent': 'Mozilla/5.0 (compatible; MjengoHub/1.0)',
  };

  const NetImage({
    Key? key,
    this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderColor = const Color(0xFFE5E7EB),
    this.extraHeaders,
    this.placeholderIcon,
    this.placeholderIconColor = const Color(0xFF9CA3AF),
    this.placeholderIconSize = 28,
    this.errorBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget child = _buildImage(context);
    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  Widget _buildImage(BuildContext context) {
    final resolved = resolveImageUrl(url);
    if (resolved == null) {
      return errorBuilder?.call(context) ?? _placeholder(isError: false);
    }

    // Web: route through a genuine DOM <img> element instead of
    // Image.network — CanvasKit needs CORS headers to fetch cross-origin
    // image bytes for its own decode/texture-upload, which mjengohub.co.ke
    // doesn't send for static uploads, so Image.network fails outright
    // there. A plain <img> tag has no such requirement just to *display*
    // a cross-origin image. See net_image_html_web.dart.
    if (kIsWeb) {
      return SizedBox(
        width: width,
        height: height,
        child: _WebNetImage(
          url: resolved,
          fit: fit,
          errorWidget: errorBuilder?.call(context) ?? _placeholder(isError: true),
        ),
      );
    }

    // Mobile/desktop: Referer & User-Agent bypass cPanel hotlink protection.
    final Map<String, String>? headers = {
      ..._mobileHeaders,
      if (extraHeaders != null) ...extraHeaders!,
    };

    return Image.network(
      resolved,
      width: width,
      height: height,
      fit: fit,
      headers: headers,
      errorBuilder: (context, error, stack) {
        debugPrint('NetImage error for $resolved: $error');
        return errorBuilder?.call(context) ?? _placeholder(isError: true);
      },
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return _shimmer();
      },
    );
  }

  Widget _placeholder({required bool isError}) => Container(
        width: width,
        height: height,
        color: placeholderColor,
        child: Center(
          child: Icon(
            placeholderIcon ??
                (isError ? Icons.broken_image_outlined : Icons.image_outlined),
            color: placeholderIconColor,
            size: placeholderIconSize,
          ),
        ),
      );

  Widget _shimmer() => Shimmer.fromColors(
        baseColor: placeholderColor,
        highlightColor: Colors.white.withValues(alpha: 0.8),
        child: Container(
          width: width,
          height: height,
          color: placeholderColor,
        ),
      );
}

/// Web-only DOM-`<img>`-backed image (see net_image_html_web.dart for why).
/// Owns its own failure state, since the underlying platform view reports
/// load errors via a DOM event rather than a Flutter-level errorBuilder.
class _WebNetImage extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final Widget errorWidget;
  const _WebNetImage({required this.url, required this.fit, required this.errorWidget});

  @override
  State<_WebNetImage> createState() => _WebNetImageState();
}

class _WebNetImageState extends State<_WebNetImage> {
  bool _failed = false;
  late Widget _view;

  @override
  void initState() {
    super.initState();
    _registerView();
  }

  @override
  void didUpdateWidget(covariant _WebNetImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.fit != widget.fit) {
      _failed = false;
      _registerView();
    }
  }

  // Registers a fresh platform view exactly once per widget instance (here
  // and on URL/fit change) rather than on every rebuild -- see the warning
  // in net_image_html_web.dart about calling buildHtmlNetworkImage from
  // build().
  void _registerView() {
    _view = html_image.buildHtmlNetworkImage(
      url: widget.url,
      fit: widget.fit,
      onError: () {
        if (mounted) setState(() => _failed = true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _failed ? widget.errorWidget : _view;
  }
}
