import 'package:flutter_test/flutter_test.dart';

import 'package:mjengo_hub_app/news/models/article_model.dart';
import 'package:mjengo_hub_app/news/utils/article_url_builder.dart';

Article _article({
  String slug = 'inspection-update',
  ArticleCategory? category,
  String? canonicalUrl,
}) {
  return Article(
    id: 1,
    title: 'Inspection update',
    slug: slug,
    canonicalUrl: canonicalUrl,
    category: category,
    isFeatured: false,
    isBreaking: false,
    viewCount: 0,
  );
}

ArticleCategory _category(String slug) =>
    ArticleCategory(id: 1, name: 'Engineering', slug: slug);

void main() {
  test('builds the category-aware canonical route', () {
    expect(
      ArticleCanonicalUrlBuilder.build(
        _article(category: _category('engineering')),
      ),
      'https://mjengohub.co.ke/articles/engineering/inspection-update',
    );
  });

  test('prefers a valid API-provided canonical URL', () {
    final article = Article.fromJson({
      'id': 1,
      'title': 'Inspection update',
      'slug': 'inspection-update',
      'canonical_url':
          'https://mjengohub.co.ke/articles/engineering/authoritative-route',
      'category': {'id': 1, 'name': 'Engineering', 'slug': 'engineering'},
    });

    expect(
      ArticleCanonicalUrlBuilder.build(article),
      'https://mjengohub.co.ke/articles/engineering/authoritative-route',
    );
  });

  test('resolves an API-provided relative canonical URL', () {
    expect(
      ArticleCanonicalUrlBuilder.build(
        _article(
          canonicalUrl: '/articles/engineering/relative-route',
          category: _category('wrong-category'),
        ),
      ),
      'https://mjengohub.co.ke/articles/engineering/relative-route',
    );
  });

  test('returns null when category or slug is unavailable', () {
    expect(ArticleCanonicalUrlBuilder.build(_article()), isNull);
    expect(
      ArticleCanonicalUrlBuilder.build(
        _article(category: _category('engineering'), slug: ''),
      ),
      isNull,
    );
  });

  test('rejects unsafe supplied URLs instead of inventing a fallback', () {
    expect(
      ArticleCanonicalUrlBuilder.build(
        _article(
          canonicalUrl: 'https://example.com/articles/engineering/route',
          category: _category('engineering'),
        ),
      ),
      'https://mjengohub.co.ke/articles/engineering/inspection-update',
    );
  });
}
