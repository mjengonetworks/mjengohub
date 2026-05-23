// lib/videos/models/video_model.dart

class VideoCategory {
  final int id;
  final String name;

  const VideoCategory({required this.id, required this.name});

  factory VideoCategory.fromJson(Map<String, dynamic> j) =>
      VideoCategory(id: j['id'] as int, name: j['name'] as String);
}

class Video {
  final int id;
  final String youtubeId;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final String? duration;
  final int viewCount;
  final bool isFeatured;
  final String? playlistId;
  final VideoCategory? category;
  final DateTime? publishedAt;

  const Video({
    required this.id,
    required this.youtubeId,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    this.duration,
    required this.viewCount,
    required this.isFeatured,
    this.playlistId,
    this.category,
    this.publishedAt,
  });

  String get youtubeUrl => 'https://www.youtube.com/watch?v=$youtubeId';

  factory Video.fromJson(Map<String, dynamic> j) {
    return Video(
      id:           j['id'] as int,
      youtubeId:    j['youtube_id'] as String,
      title:        j['title'] as String,
      description:  j['description'] as String? ?? '',
      thumbnailUrl: j['thumbnail_url'] as String?,
      duration:     j['duration'] as String?,
      viewCount:    j['view_count'] as int? ?? 0,
      isFeatured:   j['is_featured'] as bool? ?? false,
      playlistId:   j['playlist_id'] as String?,
      category: j['category'] != null
          ? VideoCategory.fromJson(j['category'] as Map<String, dynamic>)
          : null,
      publishedAt: j['published_at'] != null
          ? DateTime.tryParse(j['published_at'] as String)
          : null,
    );
  }
}

class VideoPlaylist {
  final int id;
  final String playlistId;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final int videoCount;
  final List<Video> videos;

  const VideoPlaylist({
    required this.id,
    required this.playlistId,
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.videoCount,
    required this.videos,
  });

  factory VideoPlaylist.fromJson(Map<String, dynamic> j) {
    final rawVideos = j['videos'] as List? ?? [];
    return VideoPlaylist(
      id:          j['id'] as int,
      playlistId:  j['playlist_id'] as String,
      title:       j['title'] as String,
      description: j['description'] as String?,
      thumbnailUrl:j['thumbnail_url'] as String?,
      videoCount:  j['video_count'] as int? ?? 0,
      videos:      rawVideos
          .whereType<Map<String, dynamic>>()
          .map(Video.fromJson)
          .toList(),
    );
  }
}
