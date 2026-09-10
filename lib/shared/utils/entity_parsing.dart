// lib/shared/utils/entity_parsing.dart
//
// `Project.contractor`/`consultant`/`financier` are plain free-text strings
// server-side and occasionally carry more than one stakeholder joined by a
// semicolon (e.g. joint-venture contractors) rather than a real array. This
// splits that text into individual, tappable names.
//
// Splits ONLY on `;`, never on `,` — legal entity names routinely contain
// commas of their own (e.g. "Henan Highway Engineering Group Co., Ltd.
// (HEGO); CRBC"), and splitting on comma there would break a single entity
// into fragments.
List<String> parseEntities(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  return raw
      .split(';')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty && s.toLowerCase() != 'n/a')
      .toList();
}
