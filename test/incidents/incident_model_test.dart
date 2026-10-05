import 'package:flutter_test/flutter_test.dart';

import 'package:mjengo_hub_app/incidents/models/incident_model.dart';

void main() {
  test('parses incident source and image metadata', () {
    final incident = Incident.fromJson({
      'id': 7,
      'incident_type': 'site_safety',
      'title': 'Building collapse in Mamboleo, Kisumu',
      'slug': 'building-collapse-in-mamboleo-kisumu',
      'severity': 'serious',
      'image_caption': 'The aftermath of the collapse',
      'image_source_credit': 'Kenya Red Cross',
      'source': 'SGA',
    });

    expect(incident.imageCaption, 'The aftermath of the collapse');
    expect(incident.imageSourceCredit, 'Kenya Red Cross');
    expect(incident.source, 'SGA');
  });

  test('preserves HTML paragraph boundaries in incident descriptions', () {
    final incident = Incident.fromJson({
      'id': 8,
      'incident_type': 'site_safety',
      'title': 'Incident',
      'slug': 'incident',
      'severity': 'moderate',
      'description': '<p>First paragraph.</p><p>Second paragraph.</p>',
    });

    expect(incident.paragraphs, ['First paragraph.', 'Second paragraph.']);
  });

  test('parses media caption and credit', () {
    final media = IncidentMedia.fromJson({
      'id': 1,
      'file_path': 'incidents/photo.jpg',
      'media_type': 'image',
      'caption': 'Rescue teams at the site',
      'credit': 'Kenya Red Cross',
    });

    expect(media.caption, 'Rescue teams at the site');
    expect(media.credit, 'Kenya Red Cross');
  });

  test('parses media with caption only', () {
    final media = IncidentMedia.fromJson({
      'id': 2,
      'file_path': 'incidents/photo.jpg',
      'caption': 'Visible structural damage',
    });

    expect(media.caption, 'Visible structural damage');
    expect(media.credit, isNull);
  });

  test('parses media with credit only', () {
    final media = IncidentMedia.fromJson({
      'id': 3,
      'file_path': 'incidents/photo.jpg',
      'credit': 'SGA',
    });

    expect(media.caption, isNull);
    expect(media.credit, 'SGA');
  });

  test('parses media with neither caption nor credit', () {
    final media = IncidentMedia.fromJson({
      'id': 4,
      'file_path': 'incidents/photo.jpg',
    });

    expect(media.caption, isNull);
    expect(media.credit, isNull);
  });

  test('ignores malformed media metadata', () {
    final media = IncidentMedia.fromJson({
      'id': 5,
      'file_path': 'incidents/photo.jpg',
      'caption': 42,
      'credit': <String, dynamic>{'name': 'unknown'},
      'image_credit': '  ',
    });

    expect(media.caption, isNull);
    expect(media.credit, isNull);
  });
}
