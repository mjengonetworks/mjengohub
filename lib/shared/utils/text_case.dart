// lib/shared/utils/text_case.dart
//
// Generic snake_case/slug -> Title Case conversion, used as a fallback for
// any backend enum value (status, category slug, etc.) that doesn't have an
// explicit display-label mapping — so new backend values render sensibly
// without a code change instead of leaking the raw slug to the UI.
String titleCaseFromSlug(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return trimmed;
  return trimmed
      .split(RegExp(r'[_\-\s]+'))
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
}
