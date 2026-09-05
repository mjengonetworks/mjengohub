// lib/news/widgets/net_image.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

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
/// On mobile: sends a [Referer] header so cPanel hotlink-protection
/// doesn't block the request.
///
/// On web: custom headers are NOT sent. Browsers enforce CORS and treat
/// Referer/User-Agent as forbidden headers (silently ignored). The only
/// real fix on web is an `Access-Control-Allow-Origin` header returned
/// by the server for static files.
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

    // On web: Referer & User-Agent are forbidden headers — browsers ignore
    // them and the extra CORS preflight they trigger makes things worse.
    // CORS must be solved on the server (.htaccess Access-Control-Allow-Origin).
    final Map<String, String>? headers = kIsWeb
        ? null
        : {
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
