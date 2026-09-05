// lib/news/widgets/article_map_embed.dart
//
// Mid-article interactive map (Spec 6). Renders a single centered pin for
// point articles or a polyline across `mapRoute` for route articles. Fully
// self-contained (its own flutter_map setup, not shared with the tracker
// screens' map widgets) so it doesn't depend on project-side widgets built
// elsewhere. Genuinely a no-op — returns `SizedBox.shrink()` — unless the
// article actually carries `map_enabled: true` and valid center/route data,
// which the current backend never sends yet.
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../shared/theme/app_theme.dart';
import '../models/article_model.dart';

class ArticleMapEmbed extends StatelessWidget {
  final Article article;
  const ArticleMapEmbed({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    if (!article.mapEnabled) return const SizedBox.shrink();

    final isRoute = article.mapType == 'line';
    if (isRoute) {
      final route = article.mapRoute;
      if (route == null || route.length < 2) return const SizedBox.shrink();
      return _MapCard(child: _RouteMap(route: route));
    }

    final center = article.mapCenter;
    if (center == null) return const SizedBox.shrink();
    return _MapCard(child: _PointMap(center: center));
  }
}

class _MapCard extends StatelessWidget {
  final Widget child;
  const _MapCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sharp),
        child: Container(
          height: 200,
          decoration: BoxDecoration(border: Border.all(color: AppColors.borderSlate)),
          child: child,
        ),
      ),
    );
  }
}

class _PointMap extends StatelessWidget {
  final LatLng center;
  const _PointMap({required this.center});

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'ke.co.mjengohub.app',
        ),
        MarkerLayer(markers: [
          Marker(
            point: center,
            width: 34,
            height: 34,
            child: const Icon(Icons.location_on, color: AppColors.danger, size: 34),
          ),
        ]),
      ],
    );
  }
}

class _RouteMap extends StatelessWidget {
  final List<LatLng> route;
  const _RouteMap({required this.route});

  @override
  Widget build(BuildContext context) {
    final bounds = LatLngBounds.fromPoints(route);
    return FlutterMap(
      options: MapOptions(
        initialCameraFit: CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(24)),
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'ke.co.mjengohub.app',
        ),
        PolylineLayer(polylines: [
          Polyline(points: route, strokeWidth: 4, color: AppColors.accentBlue),
        ]),
        MarkerLayer(markers: [
          Marker(
            point: route.first,
            width: 26,
            height: 26,
            child: const Icon(Icons.trip_origin, color: AppColors.success, size: 22),
          ),
          Marker(
            point: route.last,
            width: 26,
            height: 26,
            child: const Icon(Icons.flag, color: AppColors.danger, size: 22),
          ),
        ]),
      ],
    );
  }
}
