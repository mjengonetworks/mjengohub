// lib/projects/widgets/project_route_map.dart
//
// Linear-route variant of ProjectMiniMap (Spec 5) — a polyline across
// `project.routeData`'s ordered waypoints instead of a single pin, for roads/
// railways/pipelines. Reuses the same flutter_map tile source and marker
// styling as projects_map_view.dart. Defensive: only ever mounted by
// ProjectDetailScreen when `project.isLinear` and `routeData` has >= 2
// points, both of which are confirmed absent from the live backend today —
// this stays dormant until the API sends real route data.
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../shared/theme/app_theme.dart';
import '../models/project_model.dart';

class ProjectRouteMap extends StatelessWidget {
  final Project project;
  const ProjectRouteMap({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final points = project.routeData;
    if (points == null || points.length < 2) return const SizedBox.shrink();

    final bounds = LatLngBounds.fromPoints(points);
    final start = points.first;
    final end = points.last;
    final waypoints = points.sublist(1, points.length - 1);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sharp),
      child: SizedBox(
        height: 200,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCameraFit: CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(28)),
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'ke.co.mjengohub.app',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(points: points, strokeWidth: 4, color: AppColors.accentBlue),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    for (int i = 0; i < waypoints.length; i++)
                      Marker(
                        point: waypoints[i],
                        width: 16,
                        height: 16,
                        child: _WaypointDot(index: i + 1),
                      ),
                    Marker(point: start, width: 30, height: 30, child: const _RoutePin(color: AppColors.success, icon: Icons.trip_origin)),
                    Marker(point: end, width: 30, height: 30, child: const _RoutePin(color: AppColors.danger, icon: Icons.flag_rounded)),
                  ],
                ),
                const RichAttributionWidget(
                  attributions: [TextSourceAttribution('OpenStreetMap contributors')],
                ),
              ],
            ),
            if (project.routeLengthKm != null)
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.sharp),
                    border: Border.all(color: AppColors.borderSlate),
                    boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  child: Text(
                    'Total Route Length: ${project.routeLengthKm!.toStringAsFixed(1)} km',
                    style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.headingSlate),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoutePin extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _RoutePin({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }
}

class _WaypointDot extends StatelessWidget {
  final int index;
  const _WaypointDot({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.headingSlate,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        '$index',
        style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }
}
