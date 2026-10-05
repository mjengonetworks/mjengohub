import 'package:flutter_test/flutter_test.dart';

import 'package:mjengo_hub_app/projects/models/project_model.dart';

void main() {
  test('preserves Project Overview headings and paragraph order', () {
    final blocks = parseProjectOverviewHtml(
      '<h4>Project Background &amp; Scope</h4>'
      '<p>Works began on site.</p>'
      '<h4>Documented Progress</h4>'
      '<p>Construction is active.</p>',
    );

    expect(blocks.map((block) => (block.isHeading, block.text)).toList(), [
      (true, 'Project Background & Scope'),
      (false, 'Works began on site.'),
      (true, 'Documented Progress'),
      (false, 'Construction is active.'),
    ]);
  });

  test('falls back to a plain overview block for non-HTML text', () {
    final blocks = parseProjectOverviewHtml('A plain project overview.');

    expect(blocks, hasLength(1));
    expect(blocks.single.isHeading, isFalse);
    expect(blocks.single.text, 'A plain project overview.');
  });

  test('preserves text surrounding structured overview blocks', () {
    final blocks = parseProjectOverviewHtml(
      'Intro text. <h4>Scope</h4><p>Works continue.</p>Later content '
      '&lt;confirmed&gt; and &#x27;verified&#x27;.',
    );

    expect(blocks.map((block) => block.text).toList(), [
      'Intro text.',
      'Scope',
      'Works continue.',
      "Later content <confirmed> and 'verified'.",
    ]);
  });

  test('parses project media caption and credit', () {
    final media = ProjectMedia.fromJson({
      'id': 4,
      'file_path': 'projects/site.jpg',
      'media_type': 'image',
      'caption': 'Workers on site',
      'credit': 'Mjengo Hub',
      'is_featured': false,
    });

    expect(media.caption, 'Workers on site');
    expect(media.credit, 'Mjengo Hub');
  });

  test('accepts only usable HTTP media URLs for download actions', () {
    final valid = ProjectMedia(
      id: 1,
      filePath: 'https://media.mjengohub.co.ke/static/site.jpg',
      mediaType: 'image',
      isFeatured: false,
    );
    final missing = ProjectMedia(
      id: 2,
      filePath: '',
      mediaType: 'image',
      isFeatured: false,
    );
    final invalid = ProjectMedia(
      id: 3,
      filePath: 'javascript:alert(1)',
      mediaType: 'image',
      isFeatured: false,
    );

    expect(valid.hasUsableUrl, isTrue);
    expect(missing.hasUsableUrl, isFalse);
    expect(invalid.hasUsableUrl, isFalse);
  });
}
