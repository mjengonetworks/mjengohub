// lib/shared/services/deep_link_service.dart
//
// Universal app deep linking (Spec 2): opens https://mjengohub.co.ke/... and
// https://app.mjengohub.co.ke/... links directly into the matching screen,
// both on cold start and while the app is already running.
//
// Navigation goes through `Get.toNamed(route, arguments: value)` — the only
// navigation-argument convention used anywhere in this app (see
// lib/point/routes/app_routes.dart: every detail route reads a slug/id via
// `Get.arguments`, never a query string) — so links land exactly like any
// other in-app navigation.
//
// Both ArticleDetailScreen and ProjectDetailScreen resolve their content by
// slug (`NewsApiService.getArticle(slug)` / `ProjectsService.getProject(slug)`
// — confirmed no id-based lookup exists in either service), so a `.../{id}`
// link can't be resolved to a specific item without an id->slug endpoint
// this API doesn't expose. Those links fall back to the closest list screen
// instead of pushing a detail screen that would fail to load.
import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:get/get.dart';

import '../../point/routes/app_routes.dart';

class DeepLinkService {
  static const _hosts = {'mjengohub.co.ke', 'app.mjengohub.co.ke', 'www.mjengohub.co.ke'};

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  Future<void> init() async {
    final initial = await _appLinks.getInitialLink();
    if (initial != null) _handle(initial);

    _sub = _appLinks.uriLinkStream.listen(_handle, onError: (_) {});
  }

  void dispose() {
    _sub?.cancel();
  }

  void _handle(Uri uri) {
    if (!_hosts.contains(uri.host)) return;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return;

    final head = segments.first.toLowerCase();

    // /article/{slug}, or the real website shape /articles/{category}/{slug}
    // (and the legacy flat /articles/{slug-or-id}) — always take the last
    // segment as the article identifier, never assume a fixed position.
    if (head == 'article' || head == 'articles') {
      if (segments.length < 2) return;
      final value = segments.last;
      if (_looksLikeSlug(value)) {
        Get.toNamed(AppRoutes.articleDetail, arguments: value);
      } else {
        // Numeric id only — no id->slug lookup exists, so fall back to the
        // app's home feed rather than push a detail screen with no way to
        // load its content.
        Get.toNamed(AppRoutes.home);
      }
      return;
    }

    // /project/{slug-or-id} or /projects/{slug}
    if (head == 'project' || head == 'projects') {
      if (segments.length < 2) {
        Get.toNamed(AppRoutes.projects);
        return;
      }
      final value = segments[1];
      if (_looksLikeSlug(value)) {
        Get.toNamed(AppRoutes.projectDetail, arguments: value);
      } else {
        // Numeric id only — ProjectsService.getProject() only accepts a
        // slug, so route to the tracker list instead of a broken detail push.
        Get.toNamed(AppRoutes.projects);
      }
      return;
    }

    // /infrastructure
    if (head == 'infrastructure') {
      Get.toNamed(AppRoutes.projects);
      return;
    }
  }

  /// Heuristic: a pure integer segment is treated as an id (unresolvable
  /// today); anything else (hyphenated words, mixed alnum) is treated as a
  /// slug and passed straight through to the existing slug-based lookups.
  bool _looksLikeSlug(String value) => int.tryParse(value) == null;
}
