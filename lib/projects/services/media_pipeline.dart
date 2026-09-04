// lib/projects/services/media_pipeline.dart
//
// Multi-image/video picker with automatic client-side compression (~80%
// quality, EXIF stripped) before upload. Video files are passed through
// as-is — flutter_image_compress is image-only; client-side video
// transcoding is a materially larger undertaking (native codec access) and
// out of scope here.
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class PickedMedia {
  final Uint8List bytes;
  final String filename;
  final bool isVideo;
  const PickedMedia({required this.bytes, required this.filename, required this.isVideo});
}

class MediaPipeline {
  static final ImagePicker _picker = ImagePicker();

  /// Compresses one already-picked image to ~80% quality with EXIF
  /// stripped. Returns the original bytes unchanged if compression fails
  /// (e.g. an already-tiny image, or an unsupported format on this
  /// platform) rather than blocking the upload.
  static Future<Uint8List> _compress(Uint8List bytes) async {
    try {
      return await FlutterImageCompress.compressWithList(bytes, quality: 80, keepExif: false);
    } catch (_) {
      return bytes;
    }
  }

  /// Opens the gallery for multi-select images + video, compressing every
  /// image picked. [imagesOnly] restricts the picker to still images (used
  /// by the dedicated Project Renders picker, which doesn't accept video).
  static Future<List<PickedMedia>> pickMultiple({bool imagesOnly = false}) async {
    final results = <PickedMedia>[];

    final images = await _picker.pickMultiImage(imageQuality: 100);
    for (final img in images) {
      final bytes = await img.readAsBytes();
      final compressed = await _compress(bytes);
      results.add(PickedMedia(bytes: compressed, filename: img.name, isVideo: false));
    }

    if (!imagesOnly) {
      final video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        final bytes = await video.readAsBytes();
        results.add(PickedMedia(bytes: bytes, filename: video.name, isVideo: true));
      }
    }

    return results;
  }
}
