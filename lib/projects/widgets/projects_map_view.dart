// lib/projects/widgets/projects_map_view.dart
//
// Interactive project map — the Flutter equivalent of the website's Leaflet +
// OpenStreetMap map (templates/projects.html's #pj-map / project_detail.html's
// #pd-mini-map): same tile source, same Nairobi-centered default view, no API
// key required. Markers are color-coded by status; tapping one opens a
// compact bottom preview card (16:9 thumbnail, title, location, status
// badge, View Details button) rather than navigating straight to the detail
// screen, matching the website's map popup behavior.
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../news/widgets/net_image.dart';
import '../../shared/theme/app_theme.dart';
import '../models/project_model.dart';
import '../screens/project_detail_screen.dart';

/// Nairobi — the same default center the website's #pj-map uses.
const LatLng kKenyaMapCenter = LatLng(-1.286389, 36.817223);

Color statusMarkerColor(String status) {
  switch (status) {
    case 'ongoing': return AppColors.accentBlue;
    case 'completed': return AppColors.success;
    case 'commissioned': return const Color(0xFF10B981); // emerald
    case 'planned': return const Color(0xFF9333EA); // purple
    case 'stalled':
    case 'cancelled': return AppColors.danger;
    default: return AppColors.textSubtle;
  }
}

/// Compact bottom preview card shown when a map pin is tapped.
void showProjectPreviewSheet(BuildContext context, Project project) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetImage(url: project.imageUrl, fit: BoxFit.cover, width: double.infinity, placeholderColor: const Color(0xFF1E3A5F)),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(color: statusMarkerColor(project.status), borderRadius: BorderRadius.circular(999)),
                      child: Text(project.statusLabel.toUpperCase(),
                          style: GoogleFonts.montserrat(fontSize: 9.5, fontWeight: FontWeight.w500, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(project.title,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textDark)),
                  if ((project.county ?? project.location ?? project.country) != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 13, color: AppColors.textSubtle),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(project.county ?? project.location ?? project.country!,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textSubtle)),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Get.to(() => ProjectDetailScreen(slug: project.slug), transition: Transition.cupertino);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('View Details', style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Full interactive map for a project list — every project with coordinates
/// gets a marker; tapping one opens that project's detail page directly
/// (skipping the website's hover-popup step, which doesn't translate well to
/// touch).
class ProjectsMapView extends StatelessWidget {
  final List<Project> projects;
  const ProjectsMapView({super.key, required this.projects});

  @override
  Widget build(BuildContext context) {
    final located = projects.where((p) => p.hasCoordinates).toList();

    if (located.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 44, color: AppColors.textSubtle),
              const SizedBox(height: 12),
              Text(
                'None of these projects have map coordinates yet.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSubtle),
              ),
            ],
          ),
        ),
      );
    }

    final points = located.map((p) => LatLng(p.latitude!, p.longitude!)).toList();
    final bounds = LatLngBounds.fromPoints(points);

    return FlutterMap(
      options: MapOptions(
        initialCameraFit: located.length > 1
            ? CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40))
            : null,
        initialCenter: located.length == 1 ? points.first : kKenyaMapCenter,
        initialZoom: located.length == 1 ? 14 : 6,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'ke.co.mjengohub.app',
        ),
        MarkerLayer(
          markers: located
              .map((p) => Marker(
                    point: LatLng(p.latitude!, p.longitude!),
                    width: 34,
                    height: 34,
                    child: _ProjectPin(project: p),
                  ))
              .toList(),
        ),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }
}

class _ProjectPin extends StatelessWidget {
  final Project project;
  const _ProjectPin({required this.project});

  @override
  Widget build(BuildContext context) {
    final color = statusMarkerColor(project.status);
    return GestureDetector(
      onTap: () => showProjectPreviewSheet(context, project),
      child: Tooltip(
        message: '${project.title} · ${project.statusLabel}',
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

/// Small, mostly-static preview map for a single project's detail page —
/// mirrors the website's #pd-mini-map (zoom 14, scroll-wheel zoom disabled).
/// Pan/zoom gestures are disabled so it reads as a location preview, not an
/// interactive widget competing with the page's own scroll.
class ProjectMiniMap extends StatelessWidget {
  final Project project;
  const ProjectMiniMap({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    if (!project.hasCoordinates) return const SizedBox.shrink();
    final point = LatLng(project.latitude!, project.longitude!);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 160,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom: 14,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'ke.co.mjengohub.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 34,
                  height: 34,
                  child: _ProjectPin(project: project),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
