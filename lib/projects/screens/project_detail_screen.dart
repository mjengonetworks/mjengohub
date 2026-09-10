import '../../shared/widgets/social_share_modal.dart';
// lib/projects/screens/project_detail_screen.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../auth/controllers/mjengo_auth_controller.dart';
import '../../comments/services/comments_service.dart';
import '../../comments/widgets/comments_section.dart';
import '../../news/models/article_model.dart';
import '../../news/services/news_api_service.dart';
import '../../news/widgets/net_image.dart';
import '../../point/routes/app_routes.dart';
import '../../shared/services/link_launcher.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/entity_parsing.dart';
import '../../shared/utils/slugify.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/breadcrumb_bar.dart';
import '../../shared/widgets/coming_soon.dart';
import '../../shared/widgets/guest_gate_sheet.dart';
import '../../shared/widgets/responsive.dart';
import '../controllers/projects_controller.dart';
import '../models/project_model.dart';
import '../services/projects_service.dart';
import '../widgets/project_route_map.dart';
import '../widgets/projects_map_view.dart';
import 'post_update_screen.dart';
import 'submit_project_screen.dart';

const _kBlue = Color(0xFF2563EB);
const _kBg = Color(0xFFF0F4FF);
const _kDark = Color(0xFF1A1A2E);
const _kSubtext = Color(0xFF8888AA);
const _kDivider = Color(0xFFEEEEF5);
const _kCard = Colors.white;
const _kCardPad = EdgeInsets.all(20);

class ProjectDetailScreen extends StatelessWidget {
  final String slug;
  const ProjectDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ProjectDetailController(slug), tag: slug);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBg,
        body: Obx(() {
          if (ctrl.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: _kBlue),
            );
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
          Text(
            ctrl.errorMessage.value,
            style: GoogleFonts.montserrat(fontSize: 14, color: _kSubtext),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: ctrl.load,
            child: Text(
              'Retry',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: _kBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ProjectDetailController ctrl) {
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
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          actions: [
            _FollowButton(project: project, ctrl: ctrl),
            GestureDetector(
              onTap: () {
                final projectUrl =
                    'https://mjengohub.co.ke/projects/${project.slug}';
                SocialShareModal.show(
                  context,
                  title: 'Check out ${project.title} on Mjengo Hub:',
                  url: projectUrl,
                  summary: project.summary,
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
                child: const Icon(
                  Icons.share_rounded,
                  color: Colors.white,
                  size: 18,
                ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
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
          child: ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Breadcrumbs — horizontally scrolling, never wraps ────────
                BreadcrumbBar(items: _breadcrumbs(project)),

                // ── Compact map preview — fixed 240px, tight margins.
                // Extracted from the header identity card so it reads as its
                // own section right under the breadcrumb trail. ─────────────
                if (project.isLinear &&
                    (project.routeData?.length ?? 0) >= 2) ...[
                  ProjectRouteMap(project: project),
                  const SizedBox(height: 8),
                ] else if (project.hasCoordinates) ...[
                  ProjectMiniMap(project: project),
                  const SizedBox(height: 8),
                ],

                // ── Header info card ────────────────────────────────────────
                Container(
                  color: _kCard,
                  padding: _kCardPad,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Matches the website hero's own meta row (🏗 +
                      // contractor, plain text, not a link there either — the
                      // full stakeholder list with tappable entity links lives
                      // in the Project Details card below). Rating badge moved
                      // out of the hero entirely — see [_RatingCard], placed
                      // between Project Overview and Project Details.
                      if (project.contractor != null)
                        Text(
                          '🏗 ${project.contractor!}',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: _kSubtext,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),
                      Text(
                        project.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0A2540),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _AttributionLine(project: project),
                      const SizedBox(height: 8),
                      if (project.county != null || project.location != null)
                        Text(
                          '📍 ${project.county ?? project.location}',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: _kSubtext,
                          ),
                        ),
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
                                Text(
                                  'Project Progress',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _kDark,
                                  ),
                                ),
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
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  _kBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Quick Facts strip — surfaces the fields buried lower in
                // the fact table (est. completion, budget) plus the project
                // type, right under the hero, for mobile scannability. The
                // website itself keeps these only in the "Project Details"
                // table further down; there's no separate `sector`/`category`
                // field in the API, so project_type ('Infrastructure' /
                // 'Private Development') stands in for it here. ────────────
                _QuickFactsStrip(project: project),

                const SizedBox(height: 8),

                // ── Admin action bar (Admin/Editor/Moderator) or "Suggest an
                // Update" entry point (everyone else, signed in) ───────────
                _ProjectActionBar(project: project, ctrl: ctrl),

                const SizedBox(height: 8),

                // ── Project Summary — short admin-editable teaser, matching
                // the website's own "Project Summary" card (kept distinct
                // from the fuller Project Overview below it — the website
                // shows both, not one replacing the other) ──────────────────
                if ((project.summary ?? '').isNotEmpty) ...[
                  _buildSummaryCard(project),
                  const SizedBox(height: 8),
                ],

                // ── Project Overview — the longform description, matching
                // the website's "Project Overview" heading (was "About This
                // Project"). ──────────────────────────────────────────────
                if ((project.descriptionOverview ?? project.description) !=
                    null) ...[
                  _buildDescriptionCard(project),
                  const SizedBox(height: 8),
                ],

                // ── Official Project Name — a distinct bold heading from
                // the (possibly informal) title, shown only when the backend
                // sends it ────────────────────────────────────────────────
                if ((project.officialProjectName ?? '').isNotEmpty) ...[
                  Container(
                    color: _kCard,
                    padding: _kCardPad,
                    width: double.infinity,
                    child: Text(
                      project.officialProjectName!,
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0A2540),
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // ── Project Details: stakeholders (Client/Developer,
                // Contractor, Consultant, Financier) + dates/budget, one
                // scannable 2-column fact grid — mirrors the website's own
                // "Project Details" table ────────────────────────────────
                _buildDetailsCard(project),

                const SizedBox(height: 8),

                // ── Rating module — directly below Project Details, out of
                // the hero header ─────────────────────────────────────────
                _RatingCard(ctrl: ctrl, project: project),

                const SizedBox(height: 8),

                // ── Project Team & Stakeholders (defensive — `team_members`
                // isn't sent by the live backend yet, so this stays hidden
                // until it is) ────────────────────────────────────────────
                if (project.teamMembers.isNotEmpty)
                  _TeamStakeholdersCard(project: project),

                if (project.teamMembers.isNotEmpty) const SizedBox(height: 8),

                // ── Entity-linked stakeholders, with consortium grouping —
                // distinct from `_TeamStakeholdersCard` above (`team_members`),
                // this is the newer `stakeholders` array where each entry
                // carries a real entity slug ─────────────────────────────
                if (project.stakeholders.isNotEmpty) ...[
                  _StakeholdersCard(project: project, onTapEntity: _openEntity),
                  const SizedBox(height: 8),
                ],

                // ── Financiers — funding partners with real entity slugs,
                // separate from the older plain-text `project.financier` field
                // surfaced in Project Details above ──────────────────────────
                if (project.financiers.isNotEmpty) ...[
                  _FinanciersCard(project: project, onTapEntity: _openEntity),
                  const SizedBox(height: 8),
                ],

                // ── Renders (architectural impressions) — directly below the
                // Overview, ahead of documents/photos/milestones ───────────
                if (project.renderGallery.isNotEmpty)
                  _buildGalleryCard(
                    'Architectural Renders & Visualizations',
                    project.renderGallery,
                  ),

                const SizedBox(height: 8),

                // ── Project Documents — official PDFs/reports/planning
                // approvals, admin-manageable on the website. Hidden until a
                // project actually has rows, same pattern as the entity
                // sections above ──────────────────────────────────────────
                if (project.documents.isNotEmpty) ...[
                  _DocumentsCard(project: project),
                  const SizedBox(height: 8),
                ],

                // ── Featured Project Photos & Videos — real on-site progress
                // documentation ───────────────────────────────────────────
                if (project.media.isNotEmpty)
                  _buildGalleryCard(
                    'Featured Project Photos & Videos',
                    project.renderGallery.isNotEmpty
                        ? project.progressGallery
                        : project.media,
                  ),

                const SizedBox(height: 8),

                // ── Milestones, then Documented Progress, then Discussion —
                // grouped together as the page's final section, matching the
                // website's fixed section order (milestones timeline first,
                // then crowdsourced dated updates, then comments) ──────────
                if (project.milestones.isNotEmpty) ...[
                  _buildMilestonesCard(project),
                  const SizedBox(height: 8),
                ],

                // ── Documented Progress Updates — GET /projects/{id}/updates
                // already exists in ProjectsService but was never rendered
                // anywhere; this is that missing surface. Per-update upvotes
                // and per-update threaded comments are scoped out: neither
                // ProjectUpdate nor any service method exposes them, and
                // there's no comment-resource type for updates — the
                // project-level Discussion below stays the one discussion
                // surface.
                _ProgressUpdatesSection(project: project),

                const SizedBox(height: 8),

                // ── Sidebar discovery lists (stacked on mobile): Related
                // Projects → Latest Projects → Trending Projects, each real
                // `GET projects` queries (sector-match / newest / the
                // backend's confirmed-live `sort=trending`) ───────────────
                _DiscoverProjectsSection(project: project),

                const SizedBox(height: 8),

                // ── Related Articles & Coverage — falls back to a matching
                // category feed when the project has no explicitly tagged
                // articles (Spec 7) ─────────────────────────────────────────
                RelatedArticlesSection(project: project),

                const SizedBox(height: 8),

                // ── Suggest Edit / Report Content actions ───────────────────
                _ActionsCard(project: project),

                const SizedBox(height: 8),

                // ── Partner With Us — mirrors the Hub screen's own entry
                // point (AppRoutes.advertise), surfaced here for readers
                // deep in a project page ─────────────────────────────────
                const _PartnerWithUsCard(),

                const SizedBox(height: 8),

                // ── Discussion — tightened top padding vs. the other cards'
                // uniform _kCardPad ──────────────────────────────────────
                Container(
                  color: _kCard,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
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
        ),
      ],
    );
  }

  /// Home > tracker > county/sector > title (current page, non-tappable).
  /// The tracker crumb routes back to whichever catalog this project belongs
  /// to (Built History / Africa & World take priority over the plain
  /// infrastructure/private split, matching how HubScreen distinguishes them).
  List<BreadcrumbItem> _breadcrumbs(Project project) {
    final String trackerLabel;
    final String trackerRoute;
    if (project.isBuiltHistory) {
      trackerLabel = 'Built History';
      trackerRoute = AppRoutes.builtHistory;
    } else if (project.geoScope == 'global') {
      trackerLabel = 'Africa & World';
      trackerRoute = AppRoutes.africaWorld;
    } else if (project.projectType == 'private_development') {
      trackerLabel = 'Private Projects';
      trackerRoute = AppRoutes.privateProjects;
    } else {
      trackerLabel = 'Infrastructure Tracker';
      trackerRoute = AppRoutes.projects;
    }
    final middle = project.county ?? project.sector;
    return [
      BreadcrumbItem('Home', onTap: () => Get.until((r) => r.isFirst)),
      BreadcrumbItem(trackerLabel, onTap: () => Get.toNamed(trackerRoute)),
      if (middle != null && middle.isNotEmpty) BreadcrumbItem(middle),
      BreadcrumbItem(project.title),
    ];
  }

  /// Client always has a real entity slug (ProjectClient.slug); Contractor/
  /// Consultant/Financier are plain free-text strings on Project with no
  /// entity linkage, so their taps guess a slug via slugify() — see
  /// entities/screens/entity_profile_screen.dart for how a miss is handled.
  void _openEntity(String name, [String? realSlug]) {
    Get.toNamed(
      AppRoutes.entityProfile,
      arguments: {'slug': realSlug ?? slugify(name), 'fallbackName': name},
    );
  }

  /// Contractor/Consultant/Financier(free-text) taps go to the Project
  /// Catalog filtered by that stakeholder string, matching the real
  /// website's `.pd-chip` -> `/projects?contractor=...` behavior — not an
  /// entity profile (see [_openEntity]), since these fields carry no real
  /// entity slug. If a catalog screen for this project's tracker is already
  /// on the nav stack (its ProjectsController is registered), the filter is
  /// applied to that existing instance and the stack pops back to it rather
  /// than pushing a duplicate route.
  void _openStakeholderFilter(Project project, String field, String name) {
    final route = project.projectType == 'private_development'
        ? AppRoutes.privateProjects
        : AppRoutes.projects;
    if (Get.isRegistered<ProjectsController>(tag: project.projectType)) {
      Get.find<ProjectsController>(tag: project.projectType).applyFilters(
        contractor: field == 'contractor' ? name : null,
        consultant: field == 'consultant' ? name : null,
        financier: field == 'financier' ? name : null,
      );
      Get.until((r) => r.settings.name == route);
    } else {
      Get.toNamed(route, arguments: {field: name});
    }
  }

  // Attribution (submitter/approving admin) is scoped out: submittedBy/
  // editedBy are bare user ids with no name-resolution endpoint anywhere in
  // this app, and there's no backend toggle for submitter-only display.
  Widget _buildDetailsCard(Project project) {
    final rows = <_DetailRow>[];
    if (project.client != null) {
      rows.add(
        _DetailRow(
          project.projectType == 'private_development' ? 'Developer' : 'Client',
          project.client!.name,
          onTap: () => _openEntity(project.client!.name, project.client!.slug),
        ),
      );
    }
    if (project.contractor != null) {
      rows.add(
        _DetailRow.entities(
          'Contractor',
          project.contractor!,
          chips: parseEntities(project.contractor),
          onTapChip: (name) =>
              _openStakeholderFilter(project, 'contractor', name),
        ),
      );
    }
    if (project.consultant != null) {
      rows.add(
        _DetailRow.entities(
          'Consultant',
          project.consultant!,
          chips: parseEntities(project.consultant),
          onTapChip: (name) =>
              _openStakeholderFilter(project, 'consultant', name),
        ),
      );
    }
    if (project.financier != null) {
      rows.add(
        _DetailRow.entities(
          'Financier',
          project.financier!,
          chips: parseEntities(project.financier),
          onTapChip: (name) =>
              _openStakeholderFilter(project, 'financier', name),
        ),
      );
    }
    if (project.contractValue != null) {
      rows.add(
        _DetailRow('Contract Value', _fmtCurrency(project.contractValue!)),
      );
    }
    if (project.startDate != null) {
      rows.add(_DetailRow('Start Date', _fmtDate(project.startDate!)));
    }
    if (project.status == 'completed' && project.actualEndDate != null) {
      rows.add(_DetailRow('Completed', _fmtDate(project.actualEndDate!)));
    } else if (project.expectedEndDate != null) {
      rows.add(
        _DetailRow('Expected Completion', _fmtDate(project.expectedEndDate!)),
      );
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return _InfoCard(
      title: 'Project Details',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final colWidth = (constraints.maxWidth - 12) / 2;
          return Wrap(
            children: rows.map((r) => SizedBox(width: colWidth, child: r)).toList(),
          );
        },
      ),
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

  /// Short admin-editable teaser (`project.summary`), always shown in full —
  /// distinct from the longer Overview below it, matching the website's own
  /// "Project Summary" card (light accent background, no truncation).
  Widget _buildSummaryCard(Project project) {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: _kCardPad,
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: AppColors.headingSlate, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Summary',
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.headingSlate,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            project.summary!.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
            style: GoogleFonts.montserrat(
              fontSize: 13.5,
              height: 1.6,
              color: _kDark,
            ),
          ),
        ],
      ),
    );
  }

  /// The full longform description — matches the website's "Project
  /// Overview" heading (this card was previously titled "About This
  /// Project" and conflated summary+description, dropping the description
  /// entirely whenever a summary was present).
  Widget _buildDescriptionCard(Project project) {
    final text = (project.descriptionOverview ?? project.description ?? '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();
    return _InfoCard(
      title: 'Project Overview',
      child: _ExpandableDescription(text: text),
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
                    color: m.isAchieved ? const Color(0xFF16A34A) : _kDivider,
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
                            fontSize: 11,
                            color: _kSubtext,
                          ),
                        ),
                      ],
                      if (m.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          m.description!,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: _kSubtext,
                          ),
                        ),
                      ],
                      if (m.media.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 52,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: m.media.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 6),
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
                                      child: const Icon(
                                        Icons.play_circle_fill_rounded,
                                        color: Colors.white54,
                                        size: 22,
                                      ),
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
                    child: const Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.white54,
                      size: 32,
                    ),
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
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
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
          Get.snackbar(
            'Sign in required',
            'Sign in to follow projects and get update notifications.',
            snackPosition: SnackPosition.BOTTOM,
          );
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
          project.isFollowing
              ? Icons.notifications_active_rounded
              : Icons.notifications_none_rounded,
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
    // Guests see the same "Suggest an Update" chip signed-in non-privileged
    // users see, gated on tap via the guest-gate sheet, instead of the
    // action bar disappearing entirely.
    final canManage =
        auth.isAuthenticated && auth.currentUser?.canManageProjects == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canManage
              ? AppColors.headingSlate.withValues(alpha: 0.18)
              : _kDivider,
        ),
      ),
      child: canManage
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shield_rounded,
                      size: 13,
                      color: AppColors.headingSlate,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ADMIN ACTIONS',
                      style: GoogleFonts.montserrat(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.headingSlate,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ProjectActionChip(
                        icon: Icons.add_comment_rounded,
                        label: 'Add an Update',
                        dark: true,
                        onTap: () => Get.to(
                          () => PostUpdateScreen(
                            projectId: project.id,
                            projectTitle: project.title,
                            isPrivileged: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ProjectActionChip(
                        icon: Icons.edit_rounded,
                        label: 'Edit Project',
                        dark: true,
                        onTap: () => Get.to(
                          () => SubmitProjectScreen(existingProject: project),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Obx(
                  () => _ProjectActionChip(
                    icon: Icons.visibility_off_rounded,
                    label: ctrl.publishToggling.value
                        ? 'Working…'
                        : 'Publish / Unpublish',
                    dark: true,
                    onTap: ctrl.publishToggling.value
                        ? null
                        : ctrl.togglePublish,
                    fullWidth: true,
                  ),
                ),
              ],
            )
          : _ProjectActionChip(
              icon: Icons.add_comment_outlined,
              label: 'Suggest an Update',
              onTap: () => requireAuth(
                context,
                () => Get.to(
                  () => PostUpdateScreen(
                    projectId: project.id,
                    projectTitle: project.title,
                    isPrivileged: false,
                  ),
                ),
                message: 'Sign in to submit project updates',
              ),
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

  /// Deep-slate architectural style for admin/editor/moderator-only actions,
  /// distinct from the blue "Suggest an Update" chip regular users see.
  final bool dark;
  const _ProjectActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.fullWidth = false,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = dark ? AppColors.headingSlate : _kBlue;
    final bg = dark
        ? AppColors.headingSlate.withValues(alpha: 0.06)
        : _kBlue.withValues(alpha: 0.08);
    final border = dark
        ? AppColors.headingSlate
        : _kBlue.withValues(alpha: 0.25);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(dark ? AppRadius.sharp : 10),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: fg,
              ),
            ),
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
      case 'completed':
        return const Color(0xFF4ADE80);
      case 'ongoing':
        return const Color(0xFF60A5FA);
      case 'planned':
        return const Color(0xFFFBBF24);
      case 'stalled':
      case 'cancelled':
        return const Color(0xFFF87171);
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
    );
  }
}

// ── Rating card — standalone module in the body stack, between Project
// Overview and Project Details (was a compact row inside the hero header
// card; relocated so the hero stays focused on identity, not interaction).
class _RatingCard extends StatelessWidget {
  final ProjectDetailController ctrl;
  final Project project;
  const _RatingCard({required this.ctrl, required this.project});

  void _openRatingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _RatingSheet(ctrl: ctrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kCard,
      padding: _kCardPad,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (project.averageRating != null) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFF59E0B),
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    project.ratingDisplay!,
                    style: GoogleFonts.montserrat(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: _kDark,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${project.ratingCount} rating${project.ratingCount == 1 ? '' : 's'})',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: _kSubtext,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Obx(() {
              final rated = ctrl.ratingSubmitted.value;
              return GestureDetector(
                onTap: () => requireAuth(
                  context,
                  () => _openRatingSheet(context),
                  message: 'Sign in to rate this project',
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: rated
                        ? const Color(0xFF16A34A).withValues(alpha: 0.08)
                        : _kBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        rated
                            ? Icons.check_circle_rounded
                            : Icons.star_border_rounded,
                        size: 17,
                        color: rated ? const Color(0xFF16A34A) : _kBlue,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          rated
                              ? 'You rated this project ${ctrl.userRating.value}/10'
                              : 'Rate this project',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: rated ? const Color(0xFF16A34A) : _kDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _RatingSheet extends StatelessWidget {
  final ProjectDetailController ctrl;
  const _RatingSheet({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
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
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _kDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Rate This Project',
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _kDark,
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => Row(
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
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Poor',
                style: GoogleFonts.montserrat(fontSize: 9.5, color: _kSubtext),
              ),
              Text(
                'Excellent',
                style: GoogleFonts.montserrat(fontSize: 9.5, color: _kSubtext),
              ),
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

  void _requireAuth(BuildContext context, VoidCallback action) {
    requireAuth(
      context,
      action,
      message: 'Sign in to suggest an edit or progress update',
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
              onTap: () => _requireAuth(
                context,
                () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _SuggestProgressSheet(project: project),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionChip(
              icon: Icons.edit_note_rounded,
              label: 'Suggest Edit',
              onTap: () => _requireAuth(
                context,
                () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _SuggestEditSheet(project: project),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionChip(
              icon: Icons.flag_outlined,
              label: 'Report Content',
              onTap: () => showComingSoonSnack(
                'Copyright/content claims aren\'t available in the app yet.',
              ),
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
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

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
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _kBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Partner With Us — same destination as HubScreen's utility item ────────
class _PartnerWithUsCard extends StatelessWidget {
  const _PartnerWithUsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kCard,
      padding: _kCardPad,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primeBadge.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sharp),
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: AppColors.primeBadge,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Partner With Us',
                  style: GoogleFonts.montserrat(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: _kDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Reach construction professionals across Kenya',
                  style: GoogleFonts.montserrat(
                    fontSize: 11.5,
                    color: _kSubtext,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Get.toNamed(AppRoutes.advertise),
            child: Text(
              'Advertise',
              style: GoogleFonts.montserrat(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _kBlue,
              ),
            ),
          ),
        ],
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
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).padding.bottom + 20,
        ),
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
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _kDivider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _kDark,
                ),
              ),
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
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide.none,
  ),
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
      Get.snackbar(
        'Invalid value',
        'Enter a completion percentage between 0 and 100.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'Name required',
        'Please enter your name.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }
    setState(() => _submitting = true);
    final ok = await ProjectsService().suggestProgress(
      projectId: widget.project.id,
      proposedPercent: percent,
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
      reason: _reasonCtrl.text.trim().isNotEmpty
          ? _reasonCtrl.text.trim()
          : null,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.of(context).pop();
    Get.snackbar(
      ok ? 'Thanks!' : 'Couldn\'t submit',
      ok
          ? 'Your progress suggestion has been sent for review.'
          : 'Please try again.',
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
            decoration: _sheetFieldDecoration(
              'Completion %',
            ).copyWith(suffixText: '%'),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Submit Suggestion',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
    'title',
    'summary',
    'description',
    'location',
    'contractor',
    'consultant',
    'start_date',
    'expected_end_date',
    'progress_percent',
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
      Get.snackbar(
        'Name required',
        'Please enter your name.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }
    setState(() => _submitting = true);
    final result = await ProjectsService().suggestEdit(
      projectId: widget.project.id,
      fieldName: _field,
      proposedValue: _valueCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
      reason: _reasonCtrl.text.trim().isNotEmpty
          ? _reasonCtrl.text.trim()
          : null,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.of(context).pop();
    final ok = result['error'] == null;
    Get.snackbar(
      ok ? 'Thanks!' : 'Couldn\'t submit',
      ok ? 'Your suggestion has been sent for review.' : 'Please try again.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Suggest an Edit',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _field,
            decoration: _sheetFieldDecoration('Field to correct'),
            items: _fields
                .map(
                  (f) => DropdownMenuItem(
                    value: f,
                    child: Text(f.replaceAll('_', ' ')),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _field = v ?? _field),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _valueCtrl,
            decoration: _sheetFieldDecoration('Proposed value'),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: _sheetFieldDecoration('Your name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtrl,
            decoration: _sheetFieldDecoration('Your email (optional)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonCtrl,
            decoration: _sheetFieldDecoration('Reason (optional)'),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Submit',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared layout widgets ──────────────────────────────────────────────────────

/// Truncates [text] to ~300 words with a "Continue Reading" expander when
/// longer; shows the full text as-is when already within the cap.
class _ExpandableDescription extends StatefulWidget {
  final String text;
  const _ExpandableDescription({required this.text});

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  static const int _kWordCap = 300;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final words = widget.text.split(RegExp(r'\s+'));
    final overLimit = words.length > _kWordCap;
    final shown = (_expanded || !overLimit)
        ? widget.text
        : '${words.take(_kWordCap).join(' ')}…';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          shown,
          style: GoogleFonts.montserrat(
            fontSize: 13.5,
            color: _kDark,
            height: 1.6,
          ),
        ),
        if (overLimit) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'Show less' : 'Continue Reading',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.headingSlate,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Renders `GET /projects/{id}/updates` chronologically. Hides itself
/// entirely (no empty-state card) when there are no approved updates yet.
class _ProgressUpdatesSection extends StatefulWidget {
  final Project project;
  const _ProgressUpdatesSection({required this.project});

  @override
  State<_ProgressUpdatesSection> createState() =>
      _ProgressUpdatesSectionState();
}

class _ProgressUpdatesSectionState extends State<_ProgressUpdatesSection> {
  final _service = ProjectsService();
  List<ProjectUpdate> _updates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _service.getProjectUpdates(widget.project.id);
    if (!mounted) return;
    setState(() {
      _updates = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _updates.isEmpty) return const SizedBox.shrink();

    return _InfoCard(
      title: 'Progress Updates',
      child: Column(
        children: [
          for (int i = 0; i < _updates.length; i++) ...[
            if (i > 0)
              const Divider(height: 24, thickness: 0.8, color: _kDivider),
            _ProgressUpdateCard(update: _updates[i]),
          ],
        ],
      ),
    );
  }
}

/// Pulls a YouTube video id out of any of the common URL shapes
/// (`youtube.com/watch?v=`, `youtu.be/`, `youtube.com/embed/`, `youtube.com/shorts/`).
String? _youtubeId(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  final match = RegExp(
    r'(?:youtube\.com/(?:watch\?v=|embed/|shorts/)|youtu\.be/)([A-Za-z0-9_-]{6,})',
  ).firstMatch(url);
  return match?.group(1);
}

class _ProgressUpdateCard extends StatelessWidget {
  final ProjectUpdate update;
  const _ProgressUpdateCard({required this.update});

  @override
  Widget build(BuildContext context) {
    final youtubeId = _youtubeId(update.externalVideoUrl);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.borderSlate,
              backgroundImage:
                  (update.authorAvatar != null &&
                      update.authorAvatar!.isNotEmpty)
                  ? NetworkImage(update.authorAvatar!)
                  : null,
              child:
                  (update.authorAvatar == null || update.authorAvatar!.isEmpty)
                  ? const Icon(Icons.person_rounded, size: 14, color: _kSubtext)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                update.authorName ?? 'Mjengo Hub',
                style: GoogleFonts.montserrat(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _kDark,
                ),
              ),
            ),
            if (update.createdAt != null)
              Text(
                update.createdAt!.split('T').first,
                style: GoogleFonts.montserrat(fontSize: 11, color: _kSubtext),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          update.content,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: _kDark,
            height: 1.5,
          ),
        ),
        if (youtubeId != null) ...[
          const SizedBox(height: 10),
          _UpdateYoutubeEmbed(videoId: youtubeId),
        ],
        if (update.media.isNotEmpty) ...[
          const SizedBox(height: 10),
          if (update.media.length > 1)
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              children: update.media
                  .map(
                    (m) => ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sharp),
                      child: m.mediaType == 'image'
                          ? NetImage(
                              url: m.url,
                              fit: BoxFit.cover,
                              placeholderColor: _kDivider,
                            )
                          : Container(
                              color: _kDark,
                              child: const Icon(
                                Icons.play_circle_fill_rounded,
                                color: Colors.white54,
                                size: 22,
                              ),
                            ),
                    ),
                  )
                  .toList(),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sharp),
              child: update.media.first.mediaType == 'image'
                  ? NetImage(
                      url: update.media.first.url,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      placeholderColor: _kDivider,
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      color: _kDark,
                      child: const Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white54,
                        size: 24,
                      ),
                    ),
            ),
        ],
      ],
    );
  }
}

/// Inline YouTube embed for a Documented Progress update — owns its own
/// controller so it can be disposed when this update card is removed from
/// the tree (the list re-fetches on every screen load, nothing keeps this
/// alive longer than the section itself).
class _UpdateYoutubeEmbed extends StatefulWidget {
  final String videoId;
  const _UpdateYoutubeEmbed({required this.videoId});

  @override
  State<_UpdateYoutubeEmbed> createState() => _UpdateYoutubeEmbedState();
}

class _UpdateYoutubeEmbedState extends State<_UpdateYoutubeEmbed> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(showControls: true, mute: false),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sharp),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: YoutubePlayer(controller: _controller),
      ),
    );
  }
}

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
  final VoidCallback? onTap;

  /// When set (contractor/consultant/financier — occasionally a joint
  /// venture, e.g. "CRBC, China Roads"), each parsed name renders as its own
  /// tappable chip via [onTapChip] instead of one chip over the raw string.
  final List<String>? chips;
  final void Function(String name)? onTapChip;

  const _DetailRow(this.label, this.value, {this.onTap})
    : chips = null,
      onTapChip = null;

  const _DetailRow.entities(
    this.label,
    this.value, {
    required this.chips,
    required this.onTapChip,
  }) : onTap = null;

  Widget _chip(String text, VoidCallback? onTap) {
    // Matches the website's own `.pd-chip` treatment for Contractor/Status
    // links.
    if (onTap == null) {
      return Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _kDark,
        ),
      );
    }
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF0284C7)),
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
          child: Text(
            text,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0284C7),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entityChips = chips;
    final valueWidget = entityChips != null
        ? Wrap(
            spacing: 6,
            runSpacing: 6,
            children: entityChips.isEmpty
                ? [_chip(value, null)]
                : entityChips
                      .map((name) => _chip(name, () => onTapChip!(name)))
                      .toList(),
          )
        : _chip(value, onTap);
    // Stacked (label above value) — fits the 2-column Project Details grid
    // far better than the old label-column-fixed-at-130px Row, which left
    // almost no room for the value at half card width.
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(fontSize: 11, color: _kSubtext),
          ),
          const SizedBox(height: 4),
          valueWidget,
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
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.headingSlate,
            ),
          ),
          const SizedBox(height: 14),
          for (final entry in byRole.entries) ...[
            Text(
              entry.key,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.captionSlate,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entry.value
                  .map(
                    (m) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.sharp),
                        border: Border.all(color: AppColors.borderSlate),
                      ),
                      child: Text(
                        m.name,
                        style: GoogleFonts.montserrat(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.bodyCharcoal,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

// ── Small pill badge shared by the financiers/stakeholders cards ──────────
class _Badge extends StatelessWidget {
  final String label;
  final bool filled;
  const _Badge({required this.label, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? AppColors.headingSlate : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: AppColors.headingSlate),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: filled ? Colors.white : AppColors.headingSlate,
        ),
      ),
    );
  }
}

// ── Financiers — `project.financiers`, each with a real entity slug ───────
class _FinanciersCard extends StatelessWidget {
  final Project project;
  final void Function(String name, [String? realSlug]) onTapEntity;
  const _FinanciersCard({required this.project, required this.onTapEntity});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Financiers',
      child: Column(
        children: project.financiers.map((f) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => onTapEntity(f.name, f.slug),
              borderRadius: BorderRadius.circular(AppRadius.sharp),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderSlate),
                  borderRadius: BorderRadius.circular(AppRadius.sharp),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.name,
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.bodyCharcoal,
                            ),
                          ),
                          if (f.contributionDisplay != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              f.contributionDisplay!,
                              style: GoogleFonts.montserrat(
                                fontSize: 11.5,
                                color: AppColors.captionSlate,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.end,
                      children: [
                        if ((f.fundingType ?? '').isNotEmpty)
                          _Badge(label: f.fundingType!),
                        if (f.sharePercentage != null)
                          _Badge(label: '${f.sharePercentage}%', filled: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Entity-linked stakeholders, grouped into consortium cards when several
// share a `consortiumName` — separate from `_TeamStakeholdersCard` above
// (`team_members`), which has no slug/consortium concept ──────────────────
class _StakeholdersCard extends StatelessWidget {
  final Project project;
  final void Function(String name, [String? realSlug]) onTapEntity;
  const _StakeholdersCard({required this.project, required this.onTapEntity});

  @override
  Widget build(BuildContext context) {
    final consortiums = <String, List<ProjectStakeholder>>{};
    final solo = <ProjectStakeholder>[];
    for (final s in project.stakeholders) {
      final name = s.consortiumName;
      if (name != null && name.isNotEmpty) {
        consortiums.putIfAbsent(name, () => []).add(s);
      } else {
        solo.add(s);
      }
    }

    return _InfoCard(
      title: 'Stakeholders',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in consortiums.entries)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(AppRadius.sharp),
                border: Border.all(color: AppColors.borderSlate),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.headingSlate,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entry.value
                        .map(
                          (s) => _StakeholderChip(
                            stakeholder: s,
                            onTap: () => onTapEntity(s.name, s.slug),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          if (solo.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: solo
                  .map(
                    (s) => _StakeholderChip(
                      stakeholder: s,
                      onTap: () => onTapEntity(s.name, s.slug),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _StakeholderChip extends StatelessWidget {
  final ProjectStakeholder stakeholder;
  final VoidCallback onTap;
  const _StakeholderChip({required this.stakeholder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.sharp),
          border: Border.all(color: AppColors.borderSlate),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              stakeholder.name,
              style: GoogleFonts.montserrat(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.bodyCharcoal,
              ),
            ),
            if (stakeholder.isConsortiumLead) ...[
              const SizedBox(width: 6),
              const _Badge(label: 'LEAD', filled: true),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Attribution line — "Submitted by X · Published by Y · Last Updated D
// MMMM YYYY", directly under the hero title. Replaces the former
// _AttributionBanner (was a standalone card lower in the body). Names are
// tappable only when the backend actually gave us a resolvable user id
// (`UserProfileSummary.id`) — most sampled projects only carry a bare name
// string via `ProjectAttribution`, with no id/slug to route to, so those
// render as plain text rather than a dead link (see project memory: entity/
// user taps only go live once a real identifier is confirmed present).
class _AttributionLine extends StatelessWidget {
  final Project project;
  const _AttributionLine({required this.project});

  @override
  Widget build(BuildContext context) {
    final attribution = project.attribution;
    final submittedName = attribution?.isAnonymous == true
        ? null
        : (attribution?.submittedBy ?? project.submittedByProfile?.name);
    final publishedName =
        attribution?.publishedBy ?? project.publishedByProfile?.name;
    final isAnonymous = attribution?.isAnonymous == true;

    if (submittedName == null && publishedName == null && !isAnonymous) {
      return const SizedBox.shrink();
    }

    final updated =
        project.updatedAt ?? DateTime.tryParse(project.createdAt ?? '');
    final submittedUserId = int.tryParse(project.submittedByProfile?.id ?? '');
    final publishedUserId = int.tryParse(project.publishedByProfile?.id ?? '');

    final nameStyle = GoogleFonts.montserrat(
      color: const Color(0xFF0284C7),
      fontWeight: FontWeight.w600,
      fontSize: 13,
    );
    final plainStyle = GoogleFonts.montserrat(
      color: const Color(0xFF64748B),
      fontSize: 13,
    );

    InlineSpan nameSpan(String label, String name, int? userId) {
      if (userId == null) {
        return TextSpan(text: '$label $name', style: nameStyle);
      }
      return TextSpan(
        text: '$label $name',
        style: nameStyle,
        recognizer: TapGestureRecognizer()
          ..onTap = () =>
              Get.toNamed(AppRoutes.publicProfile, arguments: userId),
      );
    }

    final spans = <InlineSpan>[];
    if (isAnonymous) {
      spans.add(TextSpan(text: 'Submitted anonymously', style: plainStyle));
    } else if (submittedName != null) {
      spans.add(nameSpan('Submitted by', submittedName, submittedUserId));
    }
    if (publishedName != null) {
      if (spans.isNotEmpty) spans.add(TextSpan(text: ' · ', style: plainStyle));
      spans.add(nameSpan('Published by', publishedName, publishedUserId));
    }
    if (updated != null) {
      if (spans.isNotEmpty) spans.add(TextSpan(text: ' · ', style: plainStyle));
      spans.add(
        TextSpan(
          text: 'Last Updated ${_formatFullDate(updated)}',
          style: plainStyle,
        ),
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

const _kMonthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _formatFullDate(DateTime dt) =>
    '${dt.day} ${_kMonthNames[dt.month - 1]} ${dt.year}';

// ── Quick Facts strip — compact stat chips under the hero ──────────────────
//
// There's no `sector`/`category` field on Project — project_type
// ('infrastructure' / 'private_development') stands in for it. Hidden
// entirely when none of the three facts are present rather than showing an
// empty shell.
class _QuickFactsStrip extends StatelessWidget {
  final Project project;
  const _QuickFactsStrip({required this.project});

  @override
  Widget build(BuildContext context) {
    final facts = <(String, String)>[
      (
        project.projectType == 'private_development'
            ? 'Private Development'
            : 'Infrastructure',
        'sector',
      ),
      if (project.status != 'completed' && project.expectedEndDate != null)
        (_fmtFactDate(project.expectedEndDate!), 'Est. Completion'),
      if (project.status == 'completed' && project.actualEndDate != null)
        (_fmtFactDate(project.actualEndDate!), 'Completed'),
      if (project.contractValue != null)
        (_fmtFactCurrency(project.contractValue!), 'Budget'),
    ];

    return Container(
      color: _kCard,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: facts.map((f) {
          final (value, label) = f;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sharp),
              border: Border.all(color: AppColors.borderSlate),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.headingSlate,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    color: AppColors.captionSlate,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static String _fmtFactDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  static String _fmtFactCurrency(double value) {
    final s = value.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return 'KSh $buf';
  }
}

// ── Project Documents — dormant until the API sends `documents` ───────────
class _DocumentsCard extends StatelessWidget {
  final Project project;
  const _DocumentsCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kCard,
      padding: _kCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Documents',
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.headingSlate,
            ),
          ),
          const SizedBox(height: 12),
          ...project.documents.map(
            (doc) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => LinkLauncher.openLink(context, doc.url),
                borderRadius: BorderRadius.circular(AppRadius.sharp),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderSlate),
                    borderRadius: BorderRadius.circular(AppRadius.sharp),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.headingSlate,
                          borderRadius: BorderRadius.circular(AppRadius.sharp),
                        ),
                        child: Text(
                          doc.fileType,
                          style: GoogleFonts.montserrat(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.bodyCharcoal,
                              ),
                            ),
                            if ((doc.source ?? '').isNotEmpty)
                              Text(
                                doc.source!,
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  color: AppColors.captionSlate,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.download_rounded,
                        size: 16,
                        color: AppColors.captionSlate,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sidebar discovery: Related → Latest → Trending Projects (Spec 5.8) ─────
class _DiscoverProjectsSection extends StatefulWidget {
  final Project project;
  const _DiscoverProjectsSection({required this.project});

  @override
  State<_DiscoverProjectsSection> createState() =>
      _DiscoverProjectsSectionState();
}

class _DiscoverProjectsSectionState extends State<_DiscoverProjectsSection> {
  final _service = ProjectsService();
  List<Project> _related = const [];
  List<Project> _latest = const [];
  List<Project> _trending = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = widget.project;
    final results = await Future.wait([
      p.sector != null
          ? _service.getProjects(
              sector: p.sector,
              projectType: p.projectType,
              perPage: 6,
            )
          : Future.value(<Project>[]),
      _service.getProjects(projectType: p.projectType, perPage: 6),
      _service.getProjects(
        projectType: p.projectType,
        sort: 'trending',
        perPage: 6,
      ),
    ]);
    if (!mounted) return;
    setState(() {
      _related = results[0].where((x) => x.id != p.id).take(5).toList();
      _latest = results[1].where((x) => x.id != p.id).take(5).toList();
      _trending = results[2].where((x) => x.id != p.id).take(5).toList();
      _loading = false;
    });
  }

  void _viewMore() {
    final route = widget.project.projectType == 'private_development'
        ? AppRoutes.privateProjects
        : AppRoutes.projects;
    Get.toNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_related.isEmpty && _latest.isEmpty && _trending.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        if (_related.isNotEmpty) ...[
          _ProjectStrip(
            title: 'Related Projects',
            projects: _related,
            onViewMore: _viewMore,
          ),
          const SizedBox(height: 8),
        ],
        if (_latest.isNotEmpty) ...[
          _ProjectStrip(
            title: 'Latest Projects',
            projects: _latest,
            onViewMore: _viewMore,
          ),
          const SizedBox(height: 8),
        ],
        if (_trending.isNotEmpty)
          _ProjectStrip(
            title: 'Trending Projects',
            projects: _trending,
            onViewMore: _viewMore,
          ),
      ],
    );
  }
}

class _ProjectStrip extends StatelessWidget {
  final String title;
  final List<Project> projects;
  final VoidCallback onViewMore;
  const _ProjectStrip({
    required this.title,
    required this.projects,
    required this.onViewMore,
  });

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
              color: AppColors.headingSlate,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: projects.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _ProjectStripCard(project: projects[i]),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onViewMore,
            child: Text(
              'View More →',
              style: GoogleFonts.montserrat(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _kBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectStripCard extends StatelessWidget {
  final Project project;
  const _ProjectStripCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Get.toNamed(AppRoutes.projectDetail, arguments: project.slug),
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 130,
                height: 84,
                child: NetImage(
                  url: project.imageUrl,
                  fit: BoxFit.cover,
                  placeholderColor: const Color(0xFF1E3A5F),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              project.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
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
    final results = await _newsService.getArticles(
      categorySlug: categorySlug,
      perPage: 4,
    );
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
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.headingSlate,
            ),
          ),
          const SizedBox(height: 4),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < _articles.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, color: AppColors.borderSlate),
                  _RelatedArticleRow(article: _articles[i]),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

/// Compact 72x72-thumbnail row — no reading-minutes label, just the
/// category badge, title, and a relative date (`Article.timeAgo`).
class _RelatedArticleRow extends StatelessWidget {
  final Article article;
  const _RelatedArticleRow({required this.article});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          Get.toNamed(AppRoutes.articleDetail, arguments: article.slug),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 72,
                height: 72,
                child: NetImage(
                  url: article.imageUrl,
                  fit: BoxFit.cover,
                  placeholderColor: const Color(0xFF1E3A5F),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        article.category!.name.toUpperCase(),
                        style: GoogleFonts.montserrat(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.headingSlate,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.timeAgo,
                    style: GoogleFonts.montserrat(
                      fontSize: 10.5,
                      color: AppColors.captionSlate,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
