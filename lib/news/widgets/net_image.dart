// lib/news/widgets/net_image.dart
import 'package:flutter/material.dart';

/// Network image with a shimmer placeholder and graceful error fallback.
class NetImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color placeholderColor;

  const NetImage({
    Key? key,
    this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderColor = const Color(0xFFE5E7EB),
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
    return Image.network(
      url!,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _placeholder(isError: true),
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
