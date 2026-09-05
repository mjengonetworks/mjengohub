// lib/news/models/article_content_blocks.dart
//
// Splits an article's raw HTML `content` field into typed structural blocks
// (headings, quotes, bullet lists, inline figures, paragraphs) so
// ArticleDetailScreen can render each with its own styling instead of
// stripping every tag down to flat paragraph text (Article.plainContent).
// Inline formatting (bold/italic/links) inside a block is not preserved —
// only the block-level structure the parity spec calls out (H2/H3, quote
// blocks, bullets, full-width figures) is.
library;

enum ArticleBlockType { heading2, heading3, quote, bulletList, image, paragraph }

/// One inline fragment of a paragraph's text — either plain text, or a
/// segment that was inside an `<a href="...">` tag in the source HTML.
/// [href] is null for plain-text fragments.
class ArticleInlineSpan {
  final String text;
  final String? href;
  const ArticleInlineSpan(this.text, {this.href});
}

class ArticleContentBlock {
  final ArticleBlockType type;
  final String? text;
  final List<String>? items;
  final String? imageUrl;
  final String? imageCaption;

  /// Populated only for [ArticleBlockType.paragraph] blocks that contain at
  /// least one `<a href="...">` link — lets the renderer show tappable
  /// inline links (in-app for other Mjengo Hub articles, external browser
  /// otherwise) instead of silently dropping the href like plain-text
  /// flattening does. Null for link-free paragraphs, so the common case
  /// stays on the cheap plain-Text render path.
  final List<ArticleInlineSpan>? spans;

  const ArticleContentBlock._({
    required this.type,
    this.text,
    this.items,
    this.imageUrl,
    this.imageCaption,
    this.spans,
  });

  factory ArticleContentBlock.heading2(String text) =>
      ArticleContentBlock._(type: ArticleBlockType.heading2, text: text);
  factory ArticleContentBlock.heading3(String text) =>
      ArticleContentBlock._(type: ArticleBlockType.heading3, text: text);
  factory ArticleContentBlock.quote(String text) =>
      ArticleContentBlock._(type: ArticleBlockType.quote, text: text);
  factory ArticleContentBlock.bulletList(List<String> items) =>
      ArticleContentBlock._(type: ArticleBlockType.bulletList, items: items);
  factory ArticleContentBlock.image(String url, {String? caption}) =>
      ArticleContentBlock._(type: ArticleBlockType.image, imageUrl: url, imageCaption: caption);
  factory ArticleContentBlock.paragraph(String text, {List<ArticleInlineSpan>? spans}) =>
      ArticleContentBlock._(type: ArticleBlockType.paragraph, text: text, spans: spans);
}

final RegExp _kBlockPattern = RegExp(
  r'<h2[^>]*>(.*?)</h2>'
  r'|<h3[^>]*>(.*?)</h3>'
  r'|<blockquote[^>]*>(.*?)</blockquote>'
  r'|<ul[^>]*>(.*?)</ul>'
  r'|<ol[^>]*>(.*?)</ol>'
  r'|<figure[^>]*>(.*?)</figure>'
  r'|<img([^>]*)/?>'
  r'|<p[^>]*>(.*?)</p>',
  caseSensitive: false,
  dotAll: true,
);

final RegExp _kListItemPattern = RegExp(r'<li[^>]*>(.*?)</li>', caseSensitive: false, dotAll: true);
final RegExp _kImgTagPattern = RegExp(r'<img([^>]*)/?>', caseSensitive: false, dotAll: true);
final RegExp _kFigcaptionPattern = RegExp(r'<figcaption[^>]*>(.*?)</figcaption>', caseSensitive: false, dotAll: true);
final RegExp _kSrcAttr = RegExp(r'''src=["']([^"']*)["']''', caseSensitive: false);
final RegExp _kAltAttr = RegExp(r'''alt=["']([^"']*)["']''', caseSensitive: false);
final RegExp _kAnchorPattern =
    RegExp(r'''<a[^>]*href=["']([^"']*)["'][^>]*>(.*?)</a>''', caseSensitive: false, dotAll: true);

/// Splits a paragraph's raw (pre-tag-strip) HTML into plain-text and
/// `<a href>` link fragments, in source order. Returns a single plain-text
/// span (matching [_cleanInline]'s output) when there are no links.
List<ArticleInlineSpan> _parseInlineSpans(String rawHtml) {
  final spans = <ArticleInlineSpan>[];
  var last = 0;
  for (final m in _kAnchorPattern.allMatches(rawHtml)) {
    if (m.start > last) {
      final plain = _cleanInline(rawHtml.substring(last, m.start));
      if (plain.isNotEmpty) spans.add(ArticleInlineSpan(plain));
    }
    final linkText = _cleanInline(m.group(2) ?? '');
    if (linkText.isNotEmpty) spans.add(ArticleInlineSpan(linkText, href: m.group(1)));
    last = m.end();
  }
  if (last < rawHtml.length) {
    final plain = _cleanInline(rawHtml.substring(last));
    if (plain.isNotEmpty) spans.add(ArticleInlineSpan(plain));
  }
  return spans;
}

String _cleanInline(String html) => html
    .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll(RegExp(r'\n{2,}'), '\n')
    .trim();

String? _attr(RegExp pattern, String tag) {
  final m = pattern.firstMatch(tag);
  return m?.group(1);
}

/// Parses [html] into structural blocks. Falls back to plain paragraph
/// blocks (split on blank lines, same heuristic as the old
/// Article.plainContent) if no recognized block tags are found at all —
/// e.g. content that's just bare text with no markup.
List<ArticleContentBlock> parseArticleHtml(String? html) {
  if (html == null || html.trim().isEmpty) return const [];

  final blocks = <ArticleContentBlock>[];
  final matches = _kBlockPattern.allMatches(html).toList();

  for (final m in matches) {
    if (m.group(1) != null) {
      final text = _cleanInline(m.group(1)!);
      if (text.isNotEmpty) blocks.add(ArticleContentBlock.heading2(text));
    } else if (m.group(2) != null) {
      final text = _cleanInline(m.group(2)!);
      if (text.isNotEmpty) blocks.add(ArticleContentBlock.heading3(text));
    } else if (m.group(3) != null) {
      final text = _cleanInline(m.group(3)!);
      if (text.isNotEmpty) blocks.add(ArticleContentBlock.quote(text));
    } else if (m.group(4) != null || m.group(5) != null) {
      final listHtml = (m.group(4) ?? m.group(5))!;
      final items = _kListItemPattern
          .allMatches(listHtml)
          .map((li) => _cleanInline(li.group(1) ?? ''))
          .where((s) => s.isNotEmpty)
          .toList();
      if (items.isNotEmpty) blocks.add(ArticleContentBlock.bulletList(items));
    } else if (m.group(6) != null) {
      // <figure>...<img>...<figcaption>...
      final figureHtml = m.group(6)!;
      final imgTag = _kImgTagPattern.firstMatch(figureHtml)?.group(0) ?? '';
      final src = _attr(_kSrcAttr, imgTag);
      if (src != null && src.isNotEmpty) {
        final captionMatch = _kFigcaptionPattern.firstMatch(figureHtml);
        final caption = captionMatch != null ? _cleanInline(captionMatch.group(1) ?? '') : null;
        blocks.add(ArticleContentBlock.image(src, caption: caption?.isNotEmpty == true ? caption : null));
      }
    } else if (m.group(7) != null) {
      // Standalone <img ...> not wrapped in <figure>
      final tag = '<img${m.group(7)}>';
      final src = _attr(_kSrcAttr, tag);
      if (src != null && src.isNotEmpty) {
        final alt = _attr(_kAltAttr, tag);
        blocks.add(ArticleContentBlock.image(src, caption: (alt?.isNotEmpty == true) ? alt : null));
      }
    } else if (m.group(8) != null) {
      final raw = m.group(8)!;
      final text = _cleanInline(raw);
      if (text.isNotEmpty) {
        final spans = _parseInlineSpans(raw);
        final hasLink = spans.any((s) => s.href != null && s.href!.isNotEmpty);
        blocks.add(ArticleContentBlock.paragraph(text, spans: hasLink ? spans : null));
      }
    }
  }

  if (blocks.isNotEmpty) return blocks;

  // Fallback: no recognized block tags at all — split on blank lines.
  final plain = _cleanInline(html.replaceAll(RegExp(r'</(p|div|li|h[1-6])>', caseSensitive: false), '\n\n'));
  return plain
      .split(RegExp(r'\n\s*\n'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .map(ArticleContentBlock.paragraph)
      .toList();
}
