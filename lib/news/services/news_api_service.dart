// lib/news/services/news_api_service.dart
import 'package:get/get.dart';
import '../../services/base_service.dart';
import '../models/article_model.dart';
import '../models/category_model.dart';

class NewsApiService {
  BaseService get _api => Get.find<BaseService>();

  // ── Articles ──────────────────────────────────────────────────────────────

  Future<List<Article>> getFeaturedArticles({int perPage = 5}) async {
    try {
      final res = await _api.getRequest('articles', query: {
        'featured': 'true',
        'per_page': '$perPage',
      });
      return _parseArticleList(res);
    } catch (e) {
      _log('getFeaturedArticles', e);
      return [];
    }
  }

  Future<List<Article>> getBreakingNews({int perPage = 10}) async {
    try {
      final res = await _api.getRequest('articles', query: {
        'breaking': 'true',
        'per_page': '$perPage',
      });
      return _parseArticleList(res);
    } catch (e) {
      _log('getBreakingNews', e);
      return [];
    }
  }

  Future<List<Article>> getArticles({
    String? categorySlug,
    String? q,
    int page = 1,
    int perPage = 12,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': '$page',
        'per_page': '$perPage',
      };
      if (categorySlug != null && categorySlug.isNotEmpty) {
        query['category'] = categorySlug;
      }
      if (q != null && q.isNotEmpty) {
        query['q'] = q;
      }
      final res = await _api.getRequest('articles', query: query);
      return _parseArticleList(res);
    } catch (e) {
      _log('getArticles', e);
      return [];
    }
  }

  Future<Article?> getArticle(String slug) async {
    try {
      final res = await _api.getRequest('articles/$slug');
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is Map<String, dynamic>) {
          return Article.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      _log('getArticle', e);
      return null;
    }
  }

  /// Submits a new article — `POST /articles`, gated server-side behind
  /// Mjengo Hub Prime (403 if the caller isn't verified). Lands PENDING,
  /// awaiting editorial review before publication.
  Future<Map<String, dynamic>> submitArticle({
    required String title,
    required String content,
    String? summary,
    String? categorySlug,
  }) async {
    try {
      final res = await _api.postRequest('articles', {
        'title': title,
        'content': content,
        if (summary != null && summary.isNotEmpty) 'summary': summary,
        if (categorySlug != null) 'category': categorySlug,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        return {'success': true, 'message': res.body?['message'] as String?};
      }
      return {'success': false, 'message': _errorMessage(res.body), 'status': res.statusCode};
    } catch (e) {
      _log('submitArticle', e);
      return {'success': false, 'message': 'Could not submit article. Check your connection.'};
    }
  }

  String _errorMessage(dynamic body) {
    if (body is Map) {
      final msg = body['message'] ?? body['error'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return 'Could not submit article. Please try again.';
  }

  /// Articles authored by the signed-in user — `GET /auth/me/articles`.
  Future<List<Article>> getMyArticles({int page = 1, int perPage = 20}) async {
    try {
      final res = await _api.getRequest('auth/me/articles', query: {'page': '$page', 'per_page': '$perPage'});
      return _parseArticleList(res);
    } catch (e) {
      _log('getMyArticles', e);
      return [];
    }
  }

  // ── Categories ────────────────────────────────────────────────────────────

  Future<List<Category>> getCategories() async {
    try {
      final res = await _api.getRequest('categories');
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map(Category.fromJson)
              .toList();
        }
      }
      return [];
    } catch (e) {
      _log('getCategories', e);
      return [];
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<Article> _parseArticleList(Response res) {
    if (res.statusCode == 200 && res.body != null) {
      final data = res.body['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(Article.fromJson)
            .toList();
      }
    }
    return [];
  }

  void _log(String method, Object e) {
    print('NewsApiService.$method error: $e');
  }
}
