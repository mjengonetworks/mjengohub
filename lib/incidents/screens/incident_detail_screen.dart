// lib/incidents/screens/incident_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/incidents_controller.dart';
import '../models/incident_model.dart';
import '../../comments/services/comments_service.dart';
import '../../comments/widgets/comments_section.dart';

const _kDark    = Color(0xFF1A1A2E);
const _kSubtext = Color(0xFF8888AA);
const _kDivider = Color(0xFFEEEEF5);
const _kCard    = Colors.white;
const _kBg      = Color(0xFFF8FAFC);

class IncidentDetailScreen extends StatelessWidget {
  final String slug;
  const IncidentDetailScreen({Key? key, required this.slug}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(
      IncidentDetailController(slug),
      tag: 'incident_$slug',
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBg,
        body: Obx(() {
          if (ctrl.isLoading.value) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFDC2626)));
          }
          if (ctrl.incident.value == null) {
            return _buildError(ctrl);
          }
          return _buildContent(context, ctrl);
        }),
      ),
    );
  }

  Widget _buildError(IncidentDetailController ctrl) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: _kSubtext),
          const SizedBox(height: 12),
          Text(ctrl.errorMessage.value,
              style: GoogleFonts.montserrat(fontSize: 14, color: _kSubtext)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: ctrl.load,
            child: Text('Retry',
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFDC2626))),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, IncidentDetailController ctrl) {
    final incident = ctrl.incident.value!;
    final topPad = MediaQuery.of(context).padding.top;
    final heroColor = incident.isRoadSafety
        ? const Color(0xFF7F1D1D)
        : const Color(0xFF431407);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: incident.imageUrl != null ? 220 : 140,
          pinned: true,
          backgroundColor: heroColor,
          leading: GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              margin: EdgeInsets.only(left: 12, top: topPad > 0 ? 0 : 4),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            titlePadding:
                const EdgeInsets.fromLTRB(16, 0, 16, 12),
            title: Text(
              incident.title,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                shadows: [
                  const Shadow(color: Colors.black54, blurRadius: 4)
                ],
              ),
              maxLines: 2,
            ),
            background: incident.imageUrl != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(incident.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: heroColor)),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              heroColor.withOpacity(0.4),
                              heroColor.withOpacity(0.9),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [heroColor, _severityColor(incident.severity)],
                      ),
                    ),
                  ),
          ),
        ),

        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Stats bar ───────────────────────────────────────────────
              Container(
                color: const Color(0xFF1A1A2E),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    _SeverityBadge(severity: incident.severity),
                    const SizedBox(width: 12),
                    if (incident.county != null ||
                        incident.location != null)
                      Flexible(
                        child: Text(
                          '📍 ${incident.county ?? incident.location}',
                          style: GoogleFonts.montserrat(
                              fontSize: 12, color: Colors.white70),
                        ),
                      ),
                    const Spacer(),
                    if (incident.formattedDate.isNotEmpty)
                      Text(
                        incident.formattedDate,
                        style: GoogleFonts.montserrat(
                            fontSize: 11, color: Colors.white60),
                      ),
                  ],
                ),
              ),

              // Casualties row
              if (incident.casualties != null ||
                  incident.injuries != null)
                Container(
                  color: const Color(0xFF1A1A2E),
                  padding:
                      const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      if (incident.casualties != null)
                        _StatChip(
                          label:
                              '${incident.casualties} fatalities',
                          color: const Color(0xFFFCA5A5),
                        ),
                      if (incident.injuries != null) ...[
                        const SizedBox(width: 12),
                        _StatChip(
                          label: '${incident.injuries} injured',
                          color: const Color(0xFFFDE68A),
                        ),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // ── Description ─────────────────────────────────────────────
              if (incident.description != null)
                _buildCard(
                  title: 'What Happened',
                  child: Text(
                    incident.description!
                        .replaceAll(RegExp(r'<[^>]*>'), '')
                        .trim(),
                    style: GoogleFonts.montserrat(
                        fontSize: 13.5,
                        color: _kDark,
                        height: 1.65),
                  ),
                ),

              // ── Media ────────────────────────────────────────────────────
              if (incident.media.isNotEmpty)
                _buildCard(
                  title: 'Photos & Videos',
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemCount: incident.media.length.clamp(0, 9),
                    itemBuilder: (_, i) {
                      final m = incident.media[i];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: m.mediaType == 'image'
                            ? Image.network(m.url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(
                                  color: _kDivider,
                                  child: const Icon(
                                      Icons
                                          .image_not_supported_rounded,
                                      color: _kSubtext,
                                      size: 20),
                                ))
                            : Container(
                                color: _kDark,
                                child: const Icon(
                                    Icons.play_circle_fill_rounded,
                                    color: Colors.white54,
                                    size: 32),
                              ),
                      );
                    },
                  ),
                ),

              // ── Lessons Learned ──────────────────────────────────────────
              if (incident.lessonsLearned != null)
                _buildCard(
                  title: '💡 Lessons Learned',
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(8),
                      border: const Border(
                        left: BorderSide(
                            color: Color(0xFFF97316), width: 4),
                      ),
                    ),
                    child: Text(
                      incident.lessonsLearned!
                          .replaceAll(RegExp(r'<[^>]*>'), '')
                          .trim(),
                      style: GoogleFonts.montserrat(
                          fontSize: 13.5,
                          color: _kDark,
                          height: 1.6),
                    ),
                  ),
                ),

              // ── Recommendations ──────────────────────────────────────────
              if (incident.recommendations != null)
                _buildCard(
                  title: '✅ Recommendations',
                  child: Text(
                    incident.recommendations!
                        .replaceAll(RegExp(r'<[^>]*>'), '')
                        .trim(),
                    style: GoogleFonts.montserrat(
                        fontSize: 13.5,
                        color: _kDark,
                        height: 1.6),
                  ),
                ),

              // ── Updates ──────────────────────────────────────────────────
              if (incident.updates.isNotEmpty)
                _buildCard(
                  title: 'Updates',
                  child: Column(
                    children: incident.updates.map((u) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: const Border(
                            left: BorderSide(
                                color: Color(0xFF16A34A),
                                width: 3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  u.title ?? 'Update',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _kDark,
                                  ),
                                ),
                                Text(u.formattedDate,
                                    style: GoogleFonts.montserrat(
                                        fontSize: 10.5,
                                        color: _kSubtext)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(u.content,
                                style: GoogleFonts.montserrat(
                                    fontSize: 12.5,
                                    color: _kDark)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // ── Discussion (Reddit-style threaded comments, auth-gated) ───
              Container(
                color: _kCard,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(20),
                child: CommentsSection(
                  resource: CommentResource.incident,
                  resourceId: incident.id,
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      color: _kCard,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _kDark,
              )),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Color _severityColor(String s) {
    switch (s) {
      case 'fatal': return const Color(0xFF7F1D1D);
      case 'serious': return const Color(0xFFDC2626);
      case 'moderate': return const Color(0xFFF97316);
      default: return const Color(0xFF22C55E);
    }
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _SeverityBadge extends StatelessWidget {
  final String severity;
  const _SeverityBadge({required this.severity});

  Color get _color {
    switch (severity) {
      case 'fatal': return const Color(0xFF7F1D1D);
      case 'serious': return const Color(0xFFDC2626);
      case 'moderate': return const Color(0xFFF97316);
      case 'minor': return const Color(0xFF22C55E);
      default: return const Color(0xFF8888AA);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        severity.toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}
