import '../models/article_model.dart';

/// Builds links to public article pages without guessing a route when the
/// API does not provide enough information.
class ArticleCanonicalUrlBuilder {
  static const _origin = 'https://mjengohub.co.ke';
  static const _host = 'mjengohub.co.ke';

  const ArticleCanonicalUrlBuilder._();

  /// Returns an API-authoritative URL first, then the category-aware website
  /// route. Returns null when neither is safe to construct.
  static String? build(Article article) {
    final supplied = _authoritativeUrl(article.canonicalUrl);
    if (supplied != null) return supplied;

    final category = _segment(article.category?.slug);
    final slug = _segment(article.slug);
    if (category == null || slug == null) return null;

    return Uri.https(
      _host,
      '/articles/${Uri.encodeComponent(category)}/${Uri.encodeComponent(slug)}',
    ).toString();
  }

  static String? _authoritativeUrl(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return null;

    final parsed = Uri.tryParse(raw);
    if (parsed == null) return null;

    final resolved = parsed.hasScheme
        ? parsed
        : (raw.startsWith('/') ? Uri.parse(_origin).resolve(raw) : null);
    if (resolved == null ||
        !{'http', 'https'}.contains(resolved.scheme.toLowerCase()) ||
        resolved.host.toLowerCase() != _host ||
        !resolved.path.startsWith('/articles/')) {
      return null;
    }
    return resolved.toString();
  }

  static String? _segment(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty || trimmed.contains('/')
        ? null
        : trimmed;
  }
}
