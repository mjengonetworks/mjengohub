import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkedItem {
  final String id;
  final String title;
  final String slug;
  final String? imageUrl;
  final String? category;
  final String type; // 'article' or 'project'
  final DateTime savedAt;

  BookmarkedItem({
    required this.id,
    required this.title,
    required this.slug,
    this.imageUrl,
    this.category,
    required this.type,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'slug': slug,
        'imageUrl': imageUrl,
        'category': category,
        'type': type,
        'savedAt': savedAt.toIso8601String(),
      };

  factory BookmarkedItem.fromJson(Map<String, dynamic> json) => BookmarkedItem(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        slug: json['slug'] ?? '',
        imageUrl: json['imageUrl'],
        category: json['category'],
        type: json['type'] ?? 'article',
        savedAt: DateTime.tryParse(json['savedAt'] ?? '') ?? DateTime.now(),
      );
}

class BookmarksService {
  static const _key = 'mjengo_saved_bookmarks';

  static Future<List<BookmarkedItem>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => BookmarkedItem.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> isBookmarked(String slug) async {
    final list = await getBookmarks();
    return list.any((b) => b.slug == slug);
  }

  static Future<bool> toggleBookmark(BookmarkedItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getBookmarks();
    final index = list.indexWhere((b) => b.slug == item.slug);

    bool nowBookmarked;
    if (index >= 0) {
      list.removeAt(index);
      nowBookmarked = false;
    } else {
      list.insert(0, item);
      nowBookmarked = true;
    }

    final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_key, encoded);
    return nowBookmarked;
  }
}
