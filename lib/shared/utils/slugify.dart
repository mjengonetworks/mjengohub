// lib/shared/utils/slugify.dart
//
// Best-effort re-implementation of the backend's entity/client slug
// generation (lowercase, strip punctuation, spaces -> hyphens), verified
// against the one live entity today: "Kenya National Highways Authority
// (KeNHA)" -> "kenya-national-highways-authority-kenha".
//
// Used to guess an `entities/{slug}` lookup for stakeholder names that
// arrive as plain text with no slug of their own (Project.contractor/
// consultant/financier). It's a guess, not a guarantee — callers must
// handle the entity-not-found case gracefully.
String slugify(String input) {
  final lower = input.trim().toLowerCase();
  final stripped = lower.replaceAll(RegExp(r"[^a-z0-9\s-]"), '');
  final hyphenated = stripped.replaceAll(RegExp(r'[\s-]+'), '-');
  return hyphenated.replaceAll(RegExp(r'^-+|-+$'), '');
}
