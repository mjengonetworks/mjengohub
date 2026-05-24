// lib/projects/screens/project_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/projects_controller.dart';
import '../models/project_model.dart';

const _kBlue    = Color(0xFF2563EB);
const _kBg      = Color(0xFFF0F4FF);
const _kDark    = Color(0xFF1A1A2E);
const _kSubtext = Color(0xFF8888AA);
const _kDivider = Color(0xFFEEEEF5);
const _kCard    = Colors.white;

class ProjectDetailScreen extends StatelessWidget {
  final String slug;
  const ProjectDetailScreen({Key? key, required this.slug}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(
      ProjectDetailController(slug),
      tag: slug,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBg,
        body: Obx(() {
          if (ctrl.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: _kBlue));
          }
          if (ctrl.project.value == null) {
            return _buildError(ctrl);
          }
          return _buildContent(context, ctrl);
        }),
      ),
    );
  }

  Widget _buildError(ProjectDetailController ctrl) {
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
                    fontWeight: FontWeight.w600, color: _kBlue)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, ProjectDetailController ctrl) {
    final project = ctrl.project.value!;
    final topPad = MediaQuery.of(context).padding.top;

    return CustomScrollView(
      slivers: [
        // Hero app bar with image
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          backgroundColor: const Color(0xFF1E3A5F),
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
            background: project.imageUrl != null
                ? Image.network(project.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _heroPlaceholder())
                : _heroPlaceholder(),
          ),
        ),

        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header info card ────────────────────────────────────────
              Container(
                color: _kCard,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _StatusBadge(status: project.status),
                        if (project.client != null) ...[
                          const SizedBox(width: 8),
                          Text(project.client!.name,
                              style: GoogleFonts.montserrat(
                                  fontSize: 11, color: _kSubtext)),
                        ],
                        const Spacer(),
                        if (project.averageRating != null)
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFF59E0B), size: 16),
                              const SizedBox(width: 3),
                              Text(
                                project.ratingDisplay!,
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _kDark,
                                ),
                              ),
                              Text(
                                ' (${project.ratingCount})',
                                style: GoogleFonts.montserrat(
                                    fontSize: 11, color: _kSubtext),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      project.title,
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _kDark,
                        height: 1.25,
                      ),
                    ),
                    if (project.county != null ||
                        project.location != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '📍 ${project.county ?? project.location}',
                        style: GoogleFonts.montserrat(
                            fontSize: 13, color: _kSubtext),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Progress bar — prominent
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _kBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Project Progress',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _kDark)),
                              Text(
                                '${project.progressPercent}%',
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _kBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: project.progressPercent / 100,
                              minHeight: 10,
                              backgroundColor: _kDivider,
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(_kBlue),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Rating widget
                    _RatingWidget(ctrl: ctrl, project: project),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Details card ────────────────────────────────────────────
              _buildDetailsCard(project),

              const SizedBox(height: 8),

              // ── Description ──────────────────────────────────────────────
              if (project.summary != null || project.description != null)
                _buildDescriptionCard(project),

              const SizedBox(height: 8),

              // ── Milestones ───────────────────────────────────────────────
              if (project.milestones.isNotEmpty)
                _buildMilestonesCard(project),

              const SizedBox(height: 8),

              // ── Media ────────────────────────────────────────────────────
              if (project.media.isNotEmpty)
                _buildMediaCard(project),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroPlaceholder() => Container(
        color: const Color(0xFF1E3A5F),
        child: const Center(
          child: Icon(Icons.business_rounded,
              color: Colors.white30, size: 64),
        ),
      );

  Widget _buildDetailsCard(Project project) {
    final rows = <_DetailRow>[];
    if (project.contractor != null)
      rows.add(_DetailRow('Contractor', project.contractor!));
    if (project.consultant != null)
      rows.add(_DetailRow('Consultant', project.consultant!));
    if (project.startDate != null)
      rows.add(_DetailRow('Start Date', _fmtDate(project.startDate!)));
    if (project.expectedEndDate != null)
      rows.add(_DetailRow('Expected Completion', _fmtDate(project.expectedEndDate!)));

    if (rows.isEmpty) return const SizedBox.shrink();

    return _InfoCard(
      title: 'Project Details',
      child: Column(children: rows),
    );
  }

  Widget _buildDescriptionCard(Project project) {
    final text = project.summary ?? project.description ?? '';
    return _InfoCard(
      title: 'About This Project',
      child: Text(
        text.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
        style: GoogleFonts.montserrat(
            fontSize: 13.5, color: _kDark, height: 1.6),
      ),
    );
  }

  Widget _buildMilestonesCard(Project project) {
    return _InfoCard(
      title: 'Milestones',
      child: Column(
        children: project.milestones.map((m) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: m.isAchieved
                        ? const Color(0xFF16A34A)
                        : _kDivider,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    m.isAchieved
                        ? Icons.check_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 14,
                    color: m.isAchieved ? Colors.white : _kSubtext,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.title,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kDark,
                        ),
                      ),
                      if (m.milestoneDate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _fmtDate(m.milestoneDate!),
                          style: GoogleFonts.montserrat(
                              fontSize: 11, color: _kSubtext),
                        ),
                      ],
                      if (m.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          m.description!,
                          style: GoogleFonts.montserrat(
                              fontSize: 12, color: _kSubtext),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMediaCard(Project project) {
    return _InfoCard(
      title: 'Photos & Media',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: project.media.length.clamp(0, 9),
        itemBuilder: (_, i) {
          final m = project.media[i];
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: m.mediaType == 'image'
                ? Image.network(m.url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                          color: _kDivider,
                          child: const Icon(Icons.image_not_supported_rounded,
                              color: _kSubtext, size: 20),
                        ))
                : Container(
                    color: _kDark,
                    child: const Icon(Icons.play_circle_fill_rounded,
                        color: Colors.white54, size: 32),
                  ),
          );
        },
      ),
    );
  }

  String _fmtDate(String s) {
    try {
      final d = DateTime.parse(s);
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${d.day} ${months[d.month]} ${d.year}';
    } catch (_) {
      return s;
    }
  }
}

// ── Rating widget ─────────────────────────────────────────────────────────────

class _RatingWidget extends StatelessWidget {
  final ProjectDetailController ctrl;
  final Project project;
  const _RatingWidget({required this.ctrl, required this.project});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.ratingSubmitted.value) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF16A34A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF16A34A), size: 18),
              const SizedBox(width: 8),
              Text(
                'You rated this project ${ctrl.userRating.value}/10',
                style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF16A34A)),
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rate This Project',
            style: GoogleFonts.montserrat(
                fontSize: 12, fontWeight: FontWeight.w600, color: _kDark),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(10, (i) {
              final rating = i + 1;
              final selected = ctrl.userRating.value >= rating;
              return GestureDetector(
                onTap: ctrl.ratingLoading.value
                    ? null
                    : () {
                        ctrl.userRating.value = rating;
                        ctrl.submitRating(rating);
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: selected ? _kBlue : _kBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: selected ? _kBlue : _kDivider),
                  ),
                  child: Center(
                    child: Text(
                      '$rating',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : _kSubtext,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Poor',
                  style: GoogleFonts.montserrat(
                      fontSize: 9.5, color: _kSubtext)),
              Text('Excellent',
                  style: GoogleFonts.montserrat(
                      fontSize: 9.5, color: _kSubtext)),
            ],
          ),
        ],
      );
    });
  }
}

// ── Shared layout widgets ──────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kCard,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _kDark,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: GoogleFonts.montserrat(
                    fontSize: 12, color: _kSubtext)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kDark)),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case 'completed': return const Color(0xFF16A34A);
      case 'ongoing': return _kBlue;
      case 'suspended': return const Color(0xFFDC2626);
      default: return _kSubtext;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: _color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
