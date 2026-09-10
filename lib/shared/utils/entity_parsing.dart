// lib/shared/utils/entity_parsing.dart
//
// `Project.contractor`/`consultant`/`financier` are plain free-text strings
// server-side and occasionally carry more than one stakeholder joined by a
// comma or semicolon (e.g. joint-venture contractors) rather than a real
// array. This splits that text into individual, tappable names.
List<String> parseEntities(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  return raw
      .split(RegExp(r'[,;]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty && s.toLowerCase() != 'n/a')
      .toList();
}
