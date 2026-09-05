import '../../shared/widgets/social_share_modal.dart';
// lib/projects/screens/project_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/controllers/mjengo_auth_controller.dart';
import '../../comments/services/comments_service.dart';
import '../../comments/widgets/comments_section.dart';
import '../../news/models/article_model.dart';
import '../../news/services/news_api_service.dart';
import '../../news/widgets/net_image.dart';
import '../../point/routes/app_routes.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/coming_soon.dart';
import '../controllers/projects_controller.dart';
import '../models/project_model.dart';
import '../services/projects_service.dart';
import '../widgets/project_route_map.dart';
import '../widgets/projects_map_view.dart';
import 'post_update_screen.dart';
import 'submit_project_screen.dart';

const _kBlue    = Color(0xFF2563EB);
const _kBg      = Color(0xFFF0F4FF);
const _kDark    = Color(0xFF1A1A2E);
const _kSubtext = Color(0xFF8888AA);
const _kDivider = Color(0xFFEEEEF5);
const _kCard    = Colors.white;
const _kCardPad = EdgeInsets.all(20);

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
        // Hero app bar with image — full-bleed, locked to a 16:9 ratio
        // against the screen width rather than a fixed height.
        SliverAppBar(
          expandedHeight: MediaQuery.of(context).size.width * 9 / 16,
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
          actions: [
            _FollowButton(project: project, ctrl: ctrl),
            GestureDetector(
              onTap: () {
                final projectUrl = 'https://mjengohub.co.ke/projects/${project.slug}';
                SocialShareModal.show(
                  context,
                  title: 'Check out ${project.title} on Mjengo Hub:',
                  url: projectUrl,
                );
              },
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.share_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                NetImage(
                  url: project.imageUrl,
                  fit: BoxFit.cover,
                  placeholderColor: const Color(0xFF1E3A5F),
                  placeholderIcon: Icons.business_rounded,
                  placeholderIconColor: Colors.white30,
                  placeholderIconSize: 64,
                ),
                // ── Project Status elevated to the very top of the hierarchy ──
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: HeroTextBadge(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _StatusDot(status: project.status),
                        const SizedBox(width: 7),
                        Text(
                          project.statusLabel.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header info card ────────────────────────────────────────
              Container(
                color: _kCard,
                padding: _kCardPad,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (project.client != null)
                          Expanded(
                            child: Text(project.client!.name,
                                style: GoogleFonts.montserrat(
                                    fontSize: 11, color: _kSubtext),
                                overflow: TextOverflow.ellipsis),
                          )
                        else
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
                                  fontWeight: FontWeight.w500,
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
                        fontWeight: FontWeight.w500,
                        color: _kDark,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (project.county != null || project.location != null)
                      Text(
                        '📍 ${project.county ?? project.location}',
                        style: GoogleFonts.montserrat(
                            fontSize: 13, color: _kSubtext),
                      ),
                    if (project.isLinear && (project.routeData?.length ?? 0) >= 2) ...[
                      const SizedBox(height: 12),
                      ProjectRouteMap(project: project),
                    ] else if (project.hasCoordinates) ...[
                      const SizedBox(height: 12),
                      ProjectMiniMap(project: project),
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
                                  fontWeight: FontWeight.w500,
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
                    const SizedBox(height: 14),

                    // Compact rating row
                    _CompactRatingRow(ctrl: ctrl, project: project),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Admin action bar (Admin/Editor/Moderator) or "Suggest an
              // Update" entry point (everyone else, signed in) ───────────
              _ProjectActionBar(project: project, ctrl: ctrl),

              const SizedBox(height: 8),

              // ── Details card (primary section) ─────────────────────────
              _buildDetailsCard(project),

              const SizedBox(height: 8),

              // ── Project Team & Stakeholders (defensive — `team_members`
              // isn't sent by the live backend yet, so this stays hidden
              // until it is) ────────────────────────────────────────────
              if (project.teamMembers.isNotEmpty) _TeamStakeholdersCard(project: project),

              if (project.teamMembers.isNotEmpty) const SizedBox(height: 8),

              // ── Description ──────────────────────────────────────────────
              if (project.summary != null || project.description != null)
                _buildDescriptionCard(project),

              const SizedBox(height: 8),

              // ── Renders (architectural impressions) — directly below the
              // summary/description, ahead of milestones/photos ───────────
              if (project.renderGallery.isNotEmpty)
                _buildGalleryCard('Architectural Renders & Visualizations', project.renderGallery),

              const SizedBox(height: 8),

              // ── Milestones ───────────────────────────────────────────────
              if (project.milestones.isNotEmpty)
                _buildMilestonesCard(project),

              const SizedBox(height: 8),

              // ── Media / progress photos ──────────────────────────────────
              if (project.media.isNotEmpty)
                _buildGalleryCard(
                  'Photos & Media',
                  project.renderGallery.isNotEmpty ? project.progressGallery : project.media,
                ),

              const SizedBox(height: 8),

              // ── Related Articles & Coverage — falls back to a matching
              // category feed when the project has no explicitly tagged
              // articles (Spec 7) ─────────────────────────────────────────
              RelatedArticlesSection(project: project),

              const SizedBox(height: 8),

              // ── Suggest Edit / Report Content actions ───────────────────
              _ActionsCard(project: project),

              const SizedBox(height: 8),

              // ── Discussion ───────────────────────────────────────────────
              Container(
                color: _kCard,
                padding: _kCardPad,
                child: CommentsSection(
                  resource: CommentResource.project,
                  resourceId: project.id,
                  title: 'Discussion',
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildDetailsCard(Project project) {
    final rows = <_DetailRow>[];
    if (project.contractor != null)
      rows.add(_DetailRow('Contractor', project.contractor!));
    if (project.consultant != null)
      rows.add(_DetailRow('Consultant', project.consultant!));
    if (project.contractValue != null)
      rows.add(_DetailRow('Contract Value', _fmtCurrency(project.contractValue!)));
    if (project.startDate != null)
      rows.add(_DetailRow('Start Date', _fmtDate(project.startDate!)));
    if (project.status == 'completed' && project.actualEndDate != null) {
      rows.add(_DetailRow('Completed', _fmtDate(project.actualEndDate!)));
    } else if (project.expectedEndDate != null) {
      rows.add(_DetailRow('Expected Completion', _fmtDate(project.expectedEndDate!)));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return _InfoCard(
      title: 'Project Details',
      child: Column(children: rows),
    );
  }

  String _fmtCurrency(double value) {
    final s = value.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return 'KSh $buf';
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
                      if (m.media.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 52,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: m.media.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 6),
                            itemBuilder: (_, i) => ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: m.media[i].mediaType == 'image'
                                  ? NetImage(
                                      url: m.media[i].url,
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                      placeholderColor: _kDivider,
                                    )
                                  : Container(
                                      width: 52,
                                      height: 52,
                                      color: _kDark,
                                      child: const Icon(Icons.play_circle_fill_rounded,
                                          color: Colors.white54, size: 22),
                                    ),
                            ),
                          ),
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

  Widget _buildGalleryCard(String title, List<ProjectMedia> items) {
    return _InfoCard(
      title: title,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: items.length.clamp(0, 9),
        itemBuilder: (_, i) {
          final m = items[i];
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: m.mediaType == 'image'
                ? NetImage(
                    url: m.url,
                    fit: BoxFit.cover,
                    placeholderColor: _kDivider,
                    placeholderIcon: Icons.image_not_supported_rounded,
                    placeholderIconColor: _kSubtext,
                    placeholderIconSize: 20,
                  )
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

// ── Status dot (used in the hero badge) ───────────────────────────────────────

/// App-bar Follow toggle — signed-in only; guests get a snackbar nudging
/// them to sign in rather than a silent no-op or being bounced to /login.
class _FollowButton extends StatelessWidget {
  final Project project;
  final ProjectDetailController ctrl;
  const _FollowButton({required this.project, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<MjengoAuthController>();
    return GestureDetector(
      onTap: () {
        if (!auth.isAuthenticated) {
          Get.snackbar('Sign in required', 'Sign in to follow projects and get update notifications.',
              snackPosition: SnackPosition.BOTTOM);
          return;
        }
        ctrl.toggleFollow();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          project.isFollowing ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

/// Admin/Editor/Moderator: "Add an Update", "Edit Project", publish toggle.
/// Everyone else, signed in: "Suggest an Update" only. Signed-out users see
/// nothing — matches the Follow button's guest handling.
class _ProjectActionBar extends StatelessWidget {
  final Project project;
  final ProjectDetailController ctrl;
  const _ProjectActionBar({required this.project, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<MjengoAuthController>();
    if (!auth.isAuthenticated) return const SizedBox.shrink();
    final canManage = auth.currentUser?.canManageProjects == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kDivider),
      ),
      child: canManage
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ProjectActionChip(
                        icon: Icons.add_comment_rounded,
                        label: 'Add an Update',
                        onTap: () => Get.to(() => PostUpdateScreen(projectId: project.id, projectTitle: project.title, isPrivileged: true)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ProjectActionChip(
                        icon: Icons.edit_rounded,
                        label: 'Edit Project',
                        onTap: () => Get.to(() => SubmitProjectScreen(existingProject: project)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Obx(() => _ProjectActionChip(
                      icon: Icons.visibility_off_rounded,
                      label: ctrl.publishToggling.value ? 'Working…' : 'Publish / Unpublish',
                      onTap: ctrl.publishToggling.value ? null : ctrl.togglePublish,
                      fullWidth: true,
                    )),
              ],
            )
          : _ProjectActionChip(
              icon: Icons.add_comment_outlined,
              label: 'Suggest an Update',
              onTap: () => Get.to(() => PostUpdateScreen(projectId: project.id, projectTitle: project.title, isPrivileged: false)),
              fullWidth: true,
            ),
    );
  }
}

class _ProjectActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool fullWidth;
  const _ProjectActionChip({required this.icon, required this.label, required this.onTap, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _kBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBlue.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: _kBlue),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500, color: _kBlue)),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  Color get _color {
    switch (status) {
      case 'completed': return const Color(0xFF4ADE80);
      case 'ongoing': return const Color(0xFF60A5FA);
      case 'planned': return const Color(0xFFFBBF24);
      case 'stalled':
      case 'cancelled': return const Color(0xFFF87171);
      default: return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7, height: 7,
      decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
    );
  }
}

// ── Compact rating row ────────────────────────────────────────────────────────

class _CompactRatingRow extends StatelessWidget {
  final ProjectDetailController ctrl;
  final Project project;
  const _CompactRatingRow({required this.ctrl, required this.project});

  void _openRatingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _RatingSheet(ctrl: ctrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rated = ctrl.ratingSubmitted.value;
      return GestureDetector(
        onTap: () => _openRatingSheet(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: rated ? const Color(0xFF16A34A).withOpacity(0.08) : _kBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                rated ? Icons.check_circle_rounded : Icons.star_border_rounded,
                size: 17,
                color: rated ? const Color(0xFF16A34A) : _kBlue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rated
                      ? 'You rated this project ${ctrl.userRating.value}/10'
                      : 'Rate this project',
                  style: GoogleFonts.montserrat(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: rated ? const Color(0xFF16A34A) : _kDark,
                  ),
                ),
              ),
              if (!rated)
                Text('Tap to rate',
                    style: GoogleFonts.montserrat(fontSize: 11, color: _kSubtext)),
            ],
          ),
        ),
      );
    });
  }
}

class _RatingSheet extends StatelessWidget {
  final ProjectDetailController ctrl;
  const _RatingSheet({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: _kDivider, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text('Rate This Project',
              style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w500, color: _kDark)),
          const SizedBox(height: 16),
          Obx(() => Row(
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
                            Navigator.of(context).pop();
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: selected ? _kBlue : _kBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: selected ? _kBlue : _kDivider),
                      ),
                      child: Center(
                        child: Text(
                          '$rating',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: selected ? Colors.white : _kSubtext,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              )),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Poor', style: GoogleFonts.montserrat(fontSize: 9.5, color: _kSubtext)),
              Text('Excellent', style: GoogleFonts.montserrat(fontSize: 9.5, color: _kSubtext)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Suggest Edit / Report Content actions ─────────────────────────────────────

class _ActionsCard extends StatelessWidget {
  final Project project;
  const _ActionsCard({required this.project});

  MjengoAuthController? get _auth {
    try { return Get.find<MjengoAuthController>(); } catch (_) { return null; }
  }

  void _requireAuth(BuildContext context, VoidCallback action) {
    if (_auth?.isAuthenticated ?? false) {
      action();
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign in required', style: GoogleFonts.montserrat(fontWeight: FontWeight.w500)),
        content: Text('Please sign in to your Mjengo Hub account to continue.',
            style: GoogleFonts.montserrat(fontSize: 13.5, color: _kSubtext)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.montserrat(color: _kSubtext))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () { Navigator.pop(ctx); Get.toNamed('/login'); },
            child: Text('Sign In', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kCard,
      padding: _kCardPad,
      child: Row(
        children: [
          Expanded(
            child: _ActionChip(
              icon: Icons.percent_rounded,
              label: 'Suggest %',
              onTap: () => _requireAuth(context, () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _SuggestProgressSheet(project: project),
                  )),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionChip(
              icon: Icons.edit_note_rounded,
              label: 'Suggest Edit',
              onTap: () => _requireAuth(context, () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _SuggestEditSheet(project: project),
                  )),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionChip(
              icon: Icons.flag_outlined,
              label: 'Report Content',
              onTap: () => showComingSoonSnack(
                  'Copyright/content claims aren\'t available in the app yet.'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kDivider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: _kBlue),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500, color: _kBlue)),
          ],
        ),
      ),
    );
  }
}

class _SheetShell extends StatelessWidget {
  final String title;
  final Widget child;
  const _SheetShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: _kDivider, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(title, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500, color: _kDark)),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _sheetFieldDecoration(String label) => InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.montserrat(fontSize: 12.5, color: _kSubtext),
      filled: true,
      fillColor: _kBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );

/// Mirrors templates/project_detail.html's "Suggest Completion %" card —
/// a lighter-weight sibling to [_SuggestEditSheet] that hits the dedicated
/// `POST projects/{id}/suggest-progress` endpoint instead of the general
/// suggest-edit one, so admins can review progress corrections separately.
class _SuggestProgressSheet extends StatefulWidget {
  final Project project;
  const _SuggestProgressSheet({required this.project});

  @override
  State<_SuggestProgressSheet> createState() => _SuggestProgressSheetState();
}

class _SuggestProgressSheetState extends State<_SuggestProgressSheet> {
  final _percentCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _percentCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final percent = int.tryParse(_percentCtrl.text.trim());
    if (percent == null || percent < 0 || percent > 100) {
      Get.snackbar('Invalid value', 'Enter a completion percentage between 0 and 100.',
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      Get.snackbar('Name required', 'Please enter your name.',
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return;
    }
    setState(() => _submitting = true);
    final ok = await ProjectsService().suggestProgress(
      projectId: widget.project.id,
      proposedPercent: percent,
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
      reason: _reasonCtrl.text.trim().isNotEmpty ? _reasonCtrl.text.trim() : null,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.of(context).pop();
    Get.snackbar(
      ok ? 'Thanks!' : 'Couldn\'t submit',
      ok ? 'Your progress suggestion has been sent for review.' : 'Please try again.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Suggest Completion %',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Do you have better information on the actual completion? '
            'Submit for admin review.',
            style: GoogleFonts.montserrat(fontSize: 12.5, color: _kSubtext),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _nameCtrl,
            decoration: _sheetFieldDecoration('Your name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _percentCtrl,
            keyboardType: TextInputType.number,
            decoration: _sheetFieldDecoration('Completion %').copyWith(suffixText: '%'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtrl,
            decoration: _sheetFieldDecoration('Your email (optional)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonCtrl,
            decoration: _sheetFieldDecoration('Reason / source (optional)'),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Submit Suggestion',
                      style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestEditSheet extends StatefulWidget {
  final Project project;
  const _SuggestEditSheet({required this.project});

  @override
  State<_SuggestEditSheet> createState() => _SuggestEditSheetState();
}

class _SuggestEditSheetState extends State<_SuggestEditSheet> {
  static const _fields = [
    'title', 'summary', 'description', 'location',
    'contractor', 'consultant', 'start_date', 'expected_end_date', 'progress_percent',
  ];
  String _field = _fields.first;
  final _valueCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;

  Future<void> _submit() async {
    if (_valueCtrl.text.trim().isEmpty) return;
    if (_nameCtrl.text.trim().isEmpty) {
      Get.snackbar('Name required', 'Please enter your name.',
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return;
    }
    setState(() => _submitting = true);
    final result = await ProjectsService().suggestEdit(
      projectId: widget.project.id,
      fieldName: _field,
      proposedValue: _valueCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
      reason: _reasonCtrl.text.trim().isNotEmpty ? _reasonCtrl.text.trim() : null,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.of(context).pop();
    final ok = result['error'] == null;
    Get.snackbar(ok ? 'Thanks!' : 'Couldn\'t submit', ok ? 'Your suggestion has been sent for review.' : 'Please try again.',
        snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Suggest an Edit',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: _field,
            decoration: _sheetFieldDecoration('Field to correct'),
            items: _fields.map((f) => DropdownMenuItem(value: f, child: Text(f.replaceAll('_', ' ')))).toList(),
            onChanged: (v) => setState(() => _field = v ?? _field),
          ),
          const SizedBox(height: 12),
          TextField(controller: _valueCtrl, decoration: _sheetFieldDecoration('Proposed value'), maxLines: 2),
          const SizedBox(height: 12),
          TextField(controller: _nameCtrl, decoration: _sheetFieldDecoration('Your name')),
          const SizedBox(height: 12),
          TextField(controller: _emailCtrl, decoration: _sheetFieldDecoration('Your email (optional)')),
          const SizedBox(height: 12),
          TextField(controller: _reasonCtrl, decoration: _sheetFieldDecoration('Reason (optional)'), maxLines: 2),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: _kBlue, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Submit', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
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
      padding: _kCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w500,
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

// ── Project Team & Stakeholders (Spec 4) ───────────────────────────────────
//
// Renders `project.teamMembers` (clients/developers, contractors, consultants
// — anything the backend tags with a role), grouped by role, as sharp-corner
// badges. Confirmed absent from the live API response today (`team_members`
// is parsed by the model but the backend never sends it), so the caller only
// mounts this when the list is non-empty — it stays completely dormant until
// the backend starts populating it, rather than showing an empty card shell.
class _TeamStakeholdersCard extends StatelessWidget {
  final Project project;
  const _TeamStakeholdersCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final byRole = <String, List<ProjectTeamMember>>{};
    for (final m in project.teamMembers) {
      final role = m.role.isNotEmpty ? m.role : 'Team';
      byRole.putIfAbsent(role, () => []).add(m);
    }

    return Container(
      color: _kCard,
      padding: _kCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Team & Stakeholders',
            style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.headingSlate),
          ),
          const SizedBox(height: 14),
          for (final entry in byRole.entries) ...[
            Text(
              entry.key,
              style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.captionSlate, letterSpacing: 0.4),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entry.value
                  .map((m) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.sharp),
                          border: Border.all(color: AppColors.borderSlate),
                        ),
                        child: Text(
                          m.name,
                          style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.bodyCharcoal),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

// ── Related Articles & Coverage (Spec 7) ───────────────────────────────────
//
// The backend has no article↔project link today (`related_articles` is
// always absent), so this always falls back to a category-matched article
// feed — mirroring BuiltHistoryScreen's existing "From the Archives" pattern
// — which is real content and keeps this section from ever rendering empty.
class RelatedArticlesSection extends StatefulWidget {
  final Project project;
  const RelatedArticlesSection({super.key, required this.project});

  @override
  State<RelatedArticlesSection> createState() => _RelatedArticlesSectionState();
}

class _RelatedArticlesSectionState extends State<RelatedArticlesSection> {
  final _newsService = NewsApiService();
  List<Article> _articles = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tagged = widget.project.relatedArticles;
    if (tagged.isNotEmpty) {
      setState(() {
        _articles = tagged;
        _loading = false;
      });
      return;
    }

    // Fallback: recent articles in the closest matching category —
    // Built History entries fall back to the 'built-history' article
    // category, everything else falls back to a Buildings/Infrastructure
    // split by project_type.
    final categorySlug = widget.project.isBuiltHistory
        ? 'built-history'
        : widget.project.projectType == 'private_development'
            ? 'buildings'
            : 'infrastructure';
    final results = await _newsService.getArticles(categorySlug: categorySlug, perPage: 4);
    if (!mounted) return;
    setState(() {
      _articles = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && _articles.isEmpty) return const SizedBox.shrink();

    return Container(
      color: _kCard,
      padding: _kCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Related Articles & Coverage',
            style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.headingSlate),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))
          else
            SizedBox(
              height: 168,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _articles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _RelatedArticleCard(article: _articles[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _RelatedArticleCard extends StatelessWidget {
  final Article article;
  const _RelatedArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.articleDetail, arguments: article.slug),
      child: Container(
        width: 190,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.sharp),
          border: Border.all(color: AppColors.borderSlate),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetImage(url: article.imageUrl, fit: BoxFit.cover, placeholderColor: const Color(0xFF1E3A5F)),
                  if (article.category != null)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.accentBlue, borderRadius: BorderRadius.circular(4)),
                        child: Text(article.category!.name.toUpperCase(),
                            style: GoogleFonts.montserrat(fontSize: 7.5, fontWeight: FontWeight.w500, color: Colors.white, letterSpacing: 0.3)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.headingSlate, height: 1.3),
                  ),
                  if (article.readTime != null) ...[
                    const SizedBox(height: 4),
                    Text('${article.readTime} min read',
                        style: GoogleFonts.montserrat(fontSize: 10, color: AppColors.captionSlate)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

