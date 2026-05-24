// lib/mental_health/models/mental_health_model.dart
const String _kBase = 'https://mjengohub.co.ke';

class MentalHealthPost {
  final int id;
  final String authorName;
  final bool isAnonymous;
  final String message;
  final bool isFeatured;
  final String? createdAt;

  const MentalHealthPost({
    required this.id,
    required this.authorName,
    required this.isAnonymous,
    required this.message,
    required this.isFeatured,
    this.createdAt,
  });

  factory MentalHealthPost.fromJson(Map<String, dynamic> j) => MentalHealthPost(
        id: (j['id'] as num).toInt(),
        authorName: (j['author_name'] as String?) ?? 'Anonymous',
        isAnonymous: (j['is_anonymous'] as bool?) ?? true,
        message: (j['message'] as String?) ?? '',
        isFeatured: (j['is_featured'] as bool?) ?? false,
        createdAt: j['created_at'] as String?,
      );

  String get monthYear {
    if (createdAt == null) return '';
    try {
      final d = DateTime.parse(createdAt!);
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[d.month]} ${d.year}';
    } catch (_) {
      return '';
    }
  }
}

class MentalHealthVideo {
  final int id;
  final String uploaderName;
  final String title;
  final String? description;
  final String? filePath;
  final String? youtubeId;
  final String? thumbnail;
  final int viewCount;

  const MentalHealthVideo({
    required this.id,
    required this.uploaderName,
    required this.title,
    this.description,
    this.filePath,
    this.youtubeId,
    this.thumbnail,
    required this.viewCount,
  });

  factory MentalHealthVideo.fromJson(Map<String, dynamic> j) => MentalHealthVideo(
        id: (j['id'] as num).toInt(),
        uploaderName: (j['uploader_name'] as String?) ?? '',
        title: (j['title'] as String?) ?? '',
        description: j['description'] as String?,
        filePath: j['file_path'] as String?,
        youtubeId: j['youtube_id'] as String?,
        thumbnail: j['thumbnail'] as String?,
        viewCount: (j['view_count'] as num?)?.toInt() ?? 0,
      );

  String? get thumbnailUrl {
    if (youtubeId != null && youtubeId!.isNotEmpty) {
      return 'https://img.youtube.com/vi/$youtubeId/mqdefault.jpg';
    }
    if (thumbnail != null && thumbnail!.isNotEmpty) {
      if (thumbnail!.startsWith('http')) return thumbnail;
      return '$_kBase/static/$thumbnail';
    }
    return null;
  }

  String? get youtubeUrl =>
      youtubeId != null ? 'https://www.youtube.com/watch?v=$youtubeId' : null;

  String? get fileUrl {
    if (filePath == null || filePath!.isEmpty) return null;
    if (filePath!.startsWith('http')) return filePath;
    return '$_kBase/static/$filePath';
  }
}
