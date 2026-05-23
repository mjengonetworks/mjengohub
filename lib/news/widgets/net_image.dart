// lib/news/widgets/net_image.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget child = _buildImage();
    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  Widget _buildImage() {
    if (url == null || url!.isEmpty) {
      return _placeholder(isError: false);
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
      url!,
      width: width,
      height: height,
      fit: fit,
      headers: headers,
      errorBuilder: (context, error, stack) {
        debugPrint('NetImage error for $url: $error');
        return _placeholder(isError: true);
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
            isError ? Icons.broken_image_outlined : Icons.image_outlined,
            color: const Color(0xFF9CA3AF),
            size: 28,
          ),
        ),
      );

  Widget _shimmer() => Container(
        width: width,
        height: height,
        color: placeholderColor,
      );
}
