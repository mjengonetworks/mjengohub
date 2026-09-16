// lib/projects/widgets/projects_map_view.dart
//
// Interactive project map — the Flutter equivalent of the website's Leaflet +
// OpenStreetMap map (templates/projects.html's #pj-map / project_detail.html's
// #pd-mini-map): same tile source, same Nairobi-centered default view, no API
// key required. Markers are sleek 22px pucks color-coded by sector; tapping
// one opens a
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

/// Geographic center of Kenya — used as the base map view for domestic
/// trackers (Built History, Private Developments, Site Safety) when the
/// current filter matches zero pins, so the map still centers somewhere
/// sensible rather than defaulting to Nairobi specifically.
const LatLng kKenyaGeographicCenter = LatLng(-0.0236, 37.9062);

/// Default center for AfricaWorldScreen's map when the current
/// region/filter matches zero pins.
const LatLng kAfricaMapCenter = LatLng(1.6508, 17.5849);

Color statusMarkerColor(String status) {
  switch (status) {
    case 'ongoing':
      return AppColors.accentBlue;
    case 'completed':
      return AppColors.success;
    case 'commissioned':
      return const Color(0xFF10B981); // emerald
    case 'planned':
      return const Color(0xFF9333EA); // purple
    case 'stalled':
    case 'cancelled':
      return AppColors.danger;
    default:
      return AppColors.textSubtle;
  }
}

/// Category-color-coded map pin fills, keyed off [Project.sectorLabel] —
/// mirrors the website's sector legend so the map reads at a glance without
/// opening each pin.
Color categoryMarkerColor(String sectorLabel) {
  switch (sectorLabel) {
    case 'Transport':
    case 'Rail':
      return const Color(0xFFEA580C); // Orange-600 — roads/highways/transport
    case 'Energy':
      return const Color(0xFFEAB308); // Yellow-500 — energy/power
    case 'Water':
      return const Color(
        0xFF0284C7,
      ); // Sky-600 — water & sanitation/environment
    case 'Housing':
      return const Color(0xFF2563EB); // Blue-600 — building/residential/housing
    case 'Ports':
      return const Color(0xFF059669); // Emerald-600 — aviation/maritime/ports
    default:
      return const Color(
        0xFF1E293B,
      ); // Slate/Navy — default/other infrastructure
  }
}

/// Compact bottom preview card shown when a map pin is tapped.
Future<void> showProjectPreviewSheet(BuildContext context, Project project) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
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
                  NetImage(
                    url: project.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholderColor: const Color(0xFF1E3A5F),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusMarkerColor(project.status),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        project.statusLabel.toUpperCase(),
                        style: GoogleFonts.montserrat(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
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
                  Text(
                    project.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  if ((project.county ?? project.location ?? project.country) !=
                      null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 13,
                          color: AppColors.textSubtle,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            project.county ??
                                project.location ??
                                project.country!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: AppColors.textSubtle,
                            ),
                          ),
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
                        Get.to(
                          () => ProjectDetailScreen(slug: project.slug),
                          transition: Transition.cupertino,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'View Details',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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

/// Marker diameter at the fully-zoomed-in (city/street) level — matches the
/// puck size [_ProjectPin] always rendered before zoom-dependent scaling was
/// added.
const double kMarkerFullDiameter = 22.0;

/// Diameter used for the selected/active marker, regardless of zoom — always
/// a notch above [kMarkerFullDiameter] so the active pin stays visually on
/// top of its neighbors.
const double kMarkerSelectedDiameter = 26.0;

/// Zoom-dependent puck sizing, mirroring the website's cluster-to-pin
/// transition: coarse country-level zooms collapse markers to plain dots,
/// mid zooms scale up smoothly, and city-level zooms show the full puck.
double markerDiameterForZoom(double zoom) {
  if (zoom < 7.0) return 8.0;
  if (zoom <= 11.0) {
    final t = (zoom - 7.0) / (11.0 - 7.0);
    return 10.0 + t * (16.0 - 10.0);
  }
  return kMarkerFullDiameter;
}

/// Full interactive map for a project list — every project with coordinates
/// gets a marker; tapping one opens that project's detail page directly
/// (skipping the website's hover-popup step, which doesn't translate well to
/// touch).
class ProjectsMapView extends StatefulWidget {
  final List<Project> projects;

  /// Base view shown when [projects] has no located pins — the map itself
  /// is never unmounted for an empty filter result, only its camera falls
  /// back to this center with an "Explore project locations" overlay pill
  /// instead of a marker set.
  final LatLng defaultCenter;

  const ProjectsMapView({
    super.key,
    required this.projects,
    this.defaultCenter = kKenyaGeographicCenter,
  });

  @override
  State<ProjectsMapView> createState() => _ProjectsMapViewState();
}

class _ProjectsMapViewState extends State<ProjectsMapView> {
  final MapController _mapController = MapController();

  /// Current *integer* zoom step — markers are only rebuilt when this
  /// changes, not on every fractional camera update, so pans/pinches stay
  /// smooth.
  late int _zoomStep;
  late double _zoom;
  String? _selectedSlug;

  @override
  void initState() {
    super.initState();
    _zoom = widget.projects.where((p) => p.hasCoordinates).length == 1
        ? 14.0
        : 6.0;
    _zoomStep = _zoom.floor();
  }

  void _handleMapEvent(MapEvent event) {
    final zoom = event.camera.zoom;
    final step = zoom.floor();
    if (step == _zoomStep) return;
    setState(() {
      _zoomStep = step;
      _zoom = zoom;
    });
  }

  @override
  Widget build(BuildContext context) {
    final located = widget.projects.where((p) => p.hasCoordinates).toList();
    final points = located
        .map((p) => LatLng(p.latitude!, p.longitude!))
        .toList();
    final bounds = located.isNotEmpty ? LatLngBounds.fromPoints(points) : null;
    final initialZoom = located.length == 1 ? 14.0 : 6.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 220,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCameraFit: located.length > 1
                      ? CameraFit.bounds(
                          bounds: bounds!,
                          padding: const EdgeInsets.all(40),
                        )
                      : null,
                  initialCenter: located.length == 1
                      ? points.first
                      : widget.defaultCenter,
                  initialZoom: initialZoom,
                  interactionOptions: const InteractionOptions(
                    flags:
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.drag |
                        InteractiveFlag.doubleTapZoom,
                  ),
                  onMapEvent: _handleMapEvent,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'ke.co.mjengohub.app',
                  ),
                  PolylineLayer(
                    polylines: [
                      for (final project in located)
                        if ((project.routeCoordinates?.length ?? 0) >= 2)
                          Polyline(
                            points: project.routeCoordinates!,
                            strokeWidth: 5,
                            color: const Color(0xFFD97706),
                          ),
                    ],
                  ),
                  MarkerLayer(
                    markers: located.map((p) {
                      final selected = p.slug == _selectedSlug;
                      final diameter = selected
                          ? kMarkerSelectedDiameter
                          : markerDiameterForZoom(_zoom);
                      return Marker(
                        point: LatLng(p.latitude!, p.longitude!),
                        width: diameter,
                        height: diameter,
                        child: _ProjectPin(
                          project: p,
                          diameter: diameter,
                          selected: selected,
                          onTap: () {
                            setState(() => _selectedSlug = p.slug);
                            showProjectPreviewSheet(context, p).whenComplete(
                              () {
                                if (mounted && _selectedSlug == p.slug) {
                                  setState(() => _selectedSlug = null);
                                }
                              },
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),
              if (located.isEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Text(
                      'Explore project locations on the map',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.headingSlate,
                      ),
                    ),
                  ),
                )
              else
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Tap map to explore',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.headingSlate,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectPin extends StatelessWidget {
  final Project project;

  /// Rendered size — [kMarkerFullDiameter] unless a zoom-dependent map
  /// passes something smaller/larger (see [markerDiameterForZoom] and
  /// [kMarkerSelectedDiameter]).
  final double diameter;

  /// Whether this pin is the active/selected marker — forces the full puck
  /// styling regardless of [diameter]'s zoom tier.
  final bool selected;

  /// Overrides the default tap behavior (open the preview sheet directly),
  /// used by [ProjectsMapView] to also track selection state.
  final VoidCallback? onTap;

  const _ProjectPin({
    required this.project,
    this.diameter = kMarkerFullDiameter,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = categoryMarkerColor(project.sectorLabel);
    final isCoarse = !selected && diameter < 10.0;
    final isFull = selected || diameter >= kMarkerFullDiameter;
    final borderWidth = isCoarse ? 1.0 : (isFull ? 2.0 : 1.5);

    return GestureDetector(
      onTap: onTap ?? () => showProjectPreviewSheet(context, project),
      child: Tooltip(
        message:
            '${project.title} · ${project.sectorLabel} · ${project.statusLabel}',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: borderWidth),
            boxShadow: isFull
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: isCoarse
              ? null
              : Center(
                  child: Container(
                    width: diameter * (6 / kMarkerFullDiameter),
                    height: diameter * (6 / kMarkerFullDiameter),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 240,
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
                    width: 22,
                    height: 22,
                    child: _ProjectPin(project: project),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
