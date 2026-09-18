// lib/search/services/search_service.dart
//
// Wraps api.py's unified `GET /search`. Note the coverage: the backend route
// searches Articles, Services and InfrastructureReports only — it does NOT
// cover projects or incidents. SearchScreen therefore still fans out to
// `ProjectsService` / `IncidentsService` for those two categories and merges
// the results, rather than treating `/search` as a full replacement.
//
// The backend rejects queries shorter than 2 characters with a 400, so callers
// should not bother calling below that length.
import 'package:get/get.dart';

import '../../news/models/article_model.dart';
import '../../reports/models/report_model.dart';
import '../../service_catalog/models/service_model.dart';
import '../../services/base_service.dart';
import '../models/ai_search_models.dart';

/// Minimum query length accepted by `GET /search`.
const int kMinSearchLength = 2;

class UnifiedSearchResults {
  final String query;
  final List<Article> articles;
  final List<ServiceOffering> services;
  final List<InfrastructureReport> reports;

  const UnifiedSearchResults({
    this.query = '',
    this.articles = const [],
    this.services = const [],
    this.reports = const [],
  });

  bool get isEmpty => articles.isEmpty && services.isEmpty && reports.isEmpty;

  int get totalCount => articles.length + services.length + reports.length;

  factory UnifiedSearchResults.fromJson(Map<String, dynamic> j) =>
      UnifiedSearchResults(
        query: (j['query'] as String?) ?? '',
        articles: _list(j['articles']).map(Article.fromJson).toList(),
        services: _list(j['services']).map(ServiceOffering.fromJson).toList(),
        reports: _list(
          j['reports'],
        ).map(InfrastructureReport.fromJson).toList(),
      );

  static Iterable<Map<String, dynamic>> _list(dynamic raw) =>
      raw is List ? raw.whereType<Map<String, dynamic>>() : const [];
}

class SearchService {
  BaseService get _api => Get.find<BaseService>();

  Future<UnifiedSearchResults> search(String query) async {
    final q = query.trim();
    if (q.length < kMinSearchLength) return const UnifiedSearchResults();
    try {
      final res = await _api.getRequest('search', query: {'q': q});
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is Map<String, dynamic>) {
          return UnifiedSearchResults.fromJson(data);
        }
      }
    } catch (e) {
      print('❌ search("$q") failed: $e');
    }
    return const UnifiedSearchResults();
  }

  /// Omnibar's AI-augmented search — `GET ai-search?q=`. **Not confirmed
  /// live** (see doc comment on [AISearchResponse]); returns an empty
  /// response on any failure (404 included), same try/catch-and-degrade
  /// pattern as [search], never throws into the caller.
  Future<AISearchResponse> fetchAISearch(String query) async {
    final q = query.trim();
    if (q.length < kMinSearchLength) return const AISearchResponse();
    try {
      final res = await _api.getRequest('ai-search', query: {'q': q});
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is Map<String, dynamic>) {
          return AISearchResponse.fromJson(data);
        }
        if (res.body is Map<String, dynamic>) {
          return AISearchResponse.fromJson(res.body as Map<String, dynamic>);
        }
      }
    } catch (e) {
      print('❌ fetchAISearch("$q") failed: $e');
    }
    return AISearchResponse(query: q);
  }
}
