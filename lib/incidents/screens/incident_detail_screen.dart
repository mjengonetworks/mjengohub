// lib/incidents/screens/incident_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/incidents_controller.dart';
import '../models/incident_model.dart';
import '../services/incidents_service.dart';
import '../../comments/services/comments_service.dart';
import '../../comments/widgets/comments_section.dart';
import '../../news/models/article_model.dart';
import '../../news/services/news_api_service.dart';
import '../../news/widgets/net_image.dart';
import '../../point/routes/app_routes.dart';
import '../../projects/models/project_model.dart';
import '../../projects/screens/project_detail_screen.dart';
import '../../projects/services/projects_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/breadcrumb_bar.dart';
import '../../shared/widgets/form_fields.dart';
import 'incidents_list_screen.dart';

const _kDark = Color(0xFF1A1A2E);
const _kSubtext = Color(0xFF8888AA);
const _kDivider = Color(0xFFEEEEF5);
const _kCard = Colors.white;
const _kBg = Color(0xFFF8FAFC);

/// Suppresses placeholder/unset values ("N/A", "TBD", "-", ...) instead of
/// rendering them as if they were real data — matches the guard used by
/// project_detail_screen.dart for the same class of admin-editable fields.
bool _isValidInfo(String? value) {
  if (value == null) return false;
  final v = value.trim().toLowerCase();
  return v.isNotEmpty &&
      v != 'n/a' &&
      v != 'tbd' &&
      v != 'null' &&
      v != 'none' &&
      v != '-';
}

class IncidentDetailScreen extends StatelessWidget {
  final String slug;
  const IncidentDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(IncidentDetailController(slug), tag: 'incident_$slug');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBg,
        body: Obx(() {
          if (ctrl.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFDC2626)),
            );
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
                color: const Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, IncidentDetailController ctrl) {
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
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            title: Text(
              incident.title,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                shadows: [const Shadow(color: Colors.black54, blurRadius: 4)],
              ),
              maxLines: 2,
            ),
            background: incident.imageUrl != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      NetImage(
                        url: incident.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_) => Container(color: heroColor),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              heroColor.withValues(alpha: 0.4),
                              heroColor.withValues(alpha: 0.9),
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
              BreadcrumbBar(
                items: [
                  BreadcrumbItem(
                    'Home',
                    onTap: () => Get.until((r) => r.isFirst),
                  ),
                  BreadcrumbItem(
                    'Site Safety',
                    onTap: () => Get.offNamed(AppRoutes.siteSafety),
                  ),
                  BreadcrumbItem(
                    incident.isRoadSafety ? 'Road Safety' : 'Site Safety',
                  ),
                  BreadcrumbItem(incident.title),
                ],
              ),
              // ── Stats bar ───────────────────────────────────────────────
              Container(
                color: const Color(0xFF1A1A2E),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    _SeverityBadge(severity: incident.severity),
                    const SizedBox(width: 12),
                    if (_isValidInfo(incident.county) ||
                        _isValidInfo(incident.location))
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 13,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                _isValidInfo(incident.county)
                                    ? incident.county!
                                    : incident.location!,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    if (incident.formattedDate.isNotEmpty)
                      Text(
                        incident.formattedDate,
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: Colors.white60,
                        ),
                      ),
                  ],
                ),
              ),

              // Casualties row
              if (incident.casualties != null || incident.injuries != null)
                Container(
                  color: const Color(0xFF1A1A2E),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      if (incident.casualties != null)
                        _StatChip(
                          label: '${incident.casualties} fatalities',
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
              if (_isValidInfo(incident.description))
                _buildCard(
                  title: 'What Happened',
                  child: Text(
                    incident.description!
                        .replaceAll(RegExp(r'<[^>]*>'), '')
                        .trim(),
                    style: GoogleFonts.montserrat(
                      fontSize: 13.5,
                      color: _kDark,
                      height: 1.65,
                    ),
                  ),
                ),

              // ── Media ────────────────────────────────────────────────────
              if (incident.media.isNotEmpty)
                _buildCard(
                  title: 'Photos & Videos',
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
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
                            ? NetImage(
                                url: m.url,
                                fit: BoxFit.cover,
                                placeholderColor: _kDivider,
                                placeholderIcon:
                                    Icons.image_not_supported_rounded,
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
                ),

              // ── Lessons Learned ──────────────────────────────────────────
              if (_isValidInfo(incident.lessonsLearned))
                _buildCard(
                  titleIcon: Icons.lightbulb_outline_rounded,
                  title: 'Lessons Learned',
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(8),
                      border: const Border(
                        left: BorderSide(color: Color(0xFFF97316), width: 4),
                      ),
                    ),
                    child: Text(
                      incident.lessonsLearned!
                          .replaceAll(RegExp(r'<[^>]*>'), '')
                          .trim(),
                      style: GoogleFonts.montserrat(
                        fontSize: 13.5,
                        color: _kDark,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),

              // ── Recommendations ──────────────────────────────────────────
              if (_isValidInfo(incident.recommendations))
                _buildCard(
                  titleIcon: Icons.check_circle_outline_rounded,
                  title: 'Recommendations',
                  child: Text(
                    incident.recommendations!
                        .replaceAll(RegExp(r'<[^>]*>'), '')
                        .trim(),
                    style: GoogleFonts.montserrat(
                      fontSize: 13.5,
                      color: _kDark,
                      height: 1.6,
                    ),
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
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _isValidInfo(u.title) ? u.title! : 'Update',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _kDark,
                                  ),
                                ),
                                Text(
                                  u.formattedDate,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 10.5,
                                    color: _kSubtext,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              u.content,
                              style: GoogleFonts.montserrat(
                                fontSize: 12.5,
                                color: _kDark,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // ── Suggest a correction / claim copyright — compact,
              // collapsed accordions right above the comments block so they
              // take zero wasted height when closed. Stacked on mobile
              // (single column) rather than forced side-by-side. ───────────
              Container(
                color: _kCard,
                margin: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    _AccordionRow(
                      icon: Icons.edit_note_rounded,
                      title: 'Submit Correction / Update',
                      child: _IncidentSuggestEditForm(incident: incident),
                    ),
                    const Divider(height: 1, color: _kDivider),
                    _AccordionRow(
                      icon: Icons.copyright_rounded,
                      title: 'Copyright Claim',
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: Text(
                          'Copyright claims aren\'t available in the app yet.',
                          style: GoogleFonts.montserrat(
                            fontSize: 12.5,
                            color: _kSubtext,
                          ),
                        ),
                      ),
                    ),
                  ],
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

              // ── Discovery feed: related reports, browse by category,
              // tracker quick-links ─────────────────────────────────────
              _DiscoveryFeed(incident: incident),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required Widget child,
    IconData? titleIcon,
  }) {
    return Container(
      color: _kCard,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (titleIcon != null) ...[
                Icon(titleIcon, size: 16, color: _kDark),
                const SizedBox(width: 6),
              ],
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _kDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Color _severityColor(String s) {
    switch (s) {
      case 'fatal':
        return const Color(0xFF7F1D1D);
      case 'serious':
        return const Color(0xFFDC2626);
      case 'moderate':
        return const Color(0xFFF97316);
      default:
        return const Color(0xFF22C55E);
    }
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _SeverityBadge extends StatelessWidget {
  final String severity;
  const _SeverityBadge({required this.severity});

  Color get _color {
    switch (severity) {
      case 'fatal':
        return const Color(0xFF7F1D1D);
      case 'serious':
        return const Color(0xFFDC2626);
      case 'moderate':
        return const Color(0xFFF97316);
      case 'minor':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF8888AA);
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
          fontWeight: FontWeight.w500,
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
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }
}

// ── Suggest a Correction / Claim Copyright accordions ───────────────────────

/// Collapsed-by-default `ExpansionTile` row — zero wasted height when
/// closed, matching the compact accordion treatment on the incident detail
/// page (mirrors templates/incident_detail.html's collapsed `<details>`).
class _AccordionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _AccordionRow({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(
        context,
      ).copyWith(dividerColor: Colors.transparent, splashColor: _kBg),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20),
        childrenPadding: EdgeInsets.zero,
        leading: Icon(icon, size: 18, color: AppColors.primaryBlue),
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kDark,
          ),
        ),
        children: [child],
      ),
    );
  }
}


/// Inline correction form rendered inside the collapsed accordion above the
/// comments block, via `POST incidents/{id}/suggest-edit`.
class _IncidentSuggestEditForm extends StatefulWidget {
  final Incident incident;
  const _IncidentSuggestEditForm({required this.incident});

  @override
  State<_IncidentSuggestEditForm> createState() =>
      _IncidentSuggestEditFormState();
}

class _IncidentSuggestEditFormState extends State<_IncidentSuggestEditForm> {
  String _field = kIncidentSuggestEditFields.first;
  final _valueCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _valueCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _valueCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'Missing info',
        'Please enter your name and the corrected value.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }
    setState(() => _submitting = true);
    final ok = await IncidentsService().suggestEdit(
      incidentId: widget.incident.id,
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
    Get.snackbar(
      ok ? 'Thanks!' : 'Couldn\'t submit',
      ok ? 'Your correction has been sent for review.' : 'Please try again.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
    if (ok) {
      _valueCtrl.clear();
      _reasonCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Have better information? Submit an edit for admin review.',
            style: GoogleFonts.montserrat(fontSize: 12.5, color: _kSubtext),
          ),
          const SizedBox(height: 14),
          const FieldLabel('Field to correct', required: true),
          AppDropdown<String>(
            value: _field,
            items: kIncidentSuggestEditFields,
            labelOf: (f) => f.replaceAll('_', ' '),
            hint: 'Select field',
            onChanged: (v) => setState(() => _field = v ?? _field),
          ),
          const SizedBox(height: 12),
          const FieldLabel('Your name', required: true),
          AppTextField(controller: _nameCtrl, hint: 'Your name'),
          const SizedBox(height: 12),
          const FieldLabel('Email'),
          AppTextField(
            controller: _emailCtrl,
            hint: 'Optional',
            keyboard: TextInputType.emailAddress,
            textCapitalization: TextCapitalization.none,
          ),
          const SizedBox(height: 12),
          const FieldLabel('Corrected value', required: true),
          AppTextField(
            controller: _valueCtrl,
            hint: 'Proposed value',
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          const FieldLabel('Reason / source'),
          AppTextField(controller: _reasonCtrl, hint: 'Optional', maxLines: 2),
          const SizedBox(height: 16),
          AppSubmitButton(
            label: 'Submit Correction',
            busy: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

// ── Discovery feed — Related / Latest / Trending reports, browse-by-
// category, latest articles/projects, and tracker quick-links, in that
// order, mirroring the website's incident detail sidebar. ──────────────────

class _DiscoveryFeed extends StatefulWidget {
  final Incident incident;
  const _DiscoveryFeed({required this.incident});

  @override
  State<_DiscoveryFeed> createState() => _DiscoveryFeedState();
}

class _DiscoveryFeedState extends State<_DiscoveryFeed> {
  late final Future<_DiscoveryData> _future = _load();

  Future<_DiscoveryData> _load() async {
    final incident = widget.incident;
    final results = await Future.wait([
      IncidentsService().getIncidents(
        type: incident.incidentType,
        severity: incident.severity,
        perPage: 6,
      ),
      IncidentsService().getIncidents(type: incident.incidentType, perPage: 8),
      NewsApiService().getArticles(perPage: 4),
      ProjectsService().getProjects(perPage: 4),
    ]);
    final related = (results[0] as List<Incident>)
        .where((i) => i.id != incident.id)
        .take(5)
        .toList();
    final latestPool = (results[1] as List<Incident>)
        .where((i) => i.id != incident.id)
        .toList();
    final latest = latestPool.take(5).toList();
    final trending = [...latestPool]
      ..sort((a, b) => b.views.compareTo(a.views));
    return _DiscoveryData(
      related: related,
      latest: latest,
      trending: trending.take(5).toList(),
      articles: results[2] as List<Article>,
      projects: results[3] as List<Project>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DiscoveryData>(
      future: _future,
      builder: (context, snap) {
        final data = snap.data;
        if (data == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data.related.isNotEmpty)
              _IncidentCarousel(
                title: 'Related Reports',
                incidents: data.related,
              ),
            if (data.latest.isNotEmpty)
              _IncidentCarousel(title: 'Latest Reports', incidents: data.latest),
            if (data.trending.isNotEmpty)
              _IncidentCarousel(
                title: 'Trending Reports',
                incidents: data.trending,
              ),
            _BrowseByCategoryChips(incident: widget.incident),
            if (data.articles.isNotEmpty) _LatestArticles(articles: data.articles),
            if (data.projects.isNotEmpty) _LatestProjects(projects: data.projects),
            const _TrackerQuickLinks(),
          ],
        );
      },
    );
  }
}

class _DiscoveryData {
  final List<Incident> related;
  final List<Incident> latest;
  final List<Incident> trending;
  final List<Article> articles;
  final List<Project> projects;
  const _DiscoveryData({
    required this.related,
    required this.latest,
    required this.trending,
    required this.articles,
    required this.projects,
  });
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: _kDark,
        ),
      ),
    );
  }
}

/// A horizontal scroll of 16:9 incident cards, used for Related/Latest/
/// Trending Reports.
class _IncidentCarousel extends StatelessWidget {
  final String title;
  final List<Incident> incidents;
  const _IncidentCarousel({required this.title, required this.incidents});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kCard,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              itemCount: incidents.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _IncidentCard(incident: incidents[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final Incident incident;
  const _IncidentCard({required this.incident});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.off(
        () => IncidentDetailScreen(slug: incident.slug),
        transition: Transition.cupertino,
      ),
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: NetImage(
                  url: incident.imageUrl,
                  fit: BoxFit.cover,
                  placeholderColor: _kBg,
                  placeholderIcon: incident.isRoadSafety
                      ? Icons.report_problem_rounded
                      : Icons.engineering_rounded,
                  placeholderIconColor: _kSubtext,
                  placeholderIconSize: 22,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              incident.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: _kDark,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal, swipeable severity chips — "Browse Reports by Category".
class _BrowseByCategoryChips extends StatelessWidget {
  final Incident incident;
  const _BrowseByCategoryChips({required this.incident});

  static const _severities = ['minor', 'moderate', 'serious', 'fatal'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kCard,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Browse Reports by Category'),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              itemCount: _severities.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final s = _severities[i];
                return GestureDetector(
                  onTap: () => Get.off(
                    () => IncidentsListScreen(
                      incidentType: incident.incidentType,
                    ),
                    transition: Transition.cupertino,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _kBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      s[0].toUpperCase() + s.substring(1),
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kDark,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestArticles extends StatelessWidget {
  final List<Article> articles;
  const _LatestArticles({required this.articles});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kCard,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Latest Articles'),
          ...articles.map(
            (a) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: NetImage(url: a.imageUrl, fit: BoxFit.cover),
                ),
              ),
              title: Text(
                a.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                a.timeAgo,
                style: GoogleFonts.montserrat(fontSize: 11, color: _kSubtext),
              ),
              onTap: () =>
                  Get.toNamed(AppRoutes.articleDetail, arguments: a.slug),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LatestProjects extends StatelessWidget {
  final List<Project> projects;
  const _LatestProjects({required this.projects});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kCard,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Latest Projects'),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              itemCount: projects.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final p = projects[i];
                return GestureDetector(
                  onTap: () => Get.to(
                    () => ProjectDetailScreen(slug: p.slug),
                    transition: Transition.cupertino,
                  ),
                  child: SizedBox(
                    width: 150,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: NetImage(
                              url: p.imageUrl,
                              fit: BoxFit.cover,
                              placeholderColor: _kBg,
                              placeholderIcon: Icons.apartment_rounded,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _kDark,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Four modern tracker quick-link cards — Infrastructure, Private Projects,
/// Africa & World, Built History — no emoji icons, subtle gradient + 1px
/// border, semi-bold label and a trailing arrow.
class _TrackerQuickLinks extends StatelessWidget {
  const _TrackerQuickLinks();

  @override
  Widget build(BuildContext context) {
    final links = [
      (
        'Infrastructure',
        Icons.foundation_rounded,
        () => Get.toNamed(AppRoutes.projects),
      ),
      (
        'Private Projects',
        Icons.apartment_rounded,
        () => Get.toNamed(AppRoutes.privateProjects),
      ),
      (
        'Africa & World',
        Icons.public_rounded,
        () => Get.toNamed(AppRoutes.africaWorld),
      ),
      (
        'Built History',
        Icons.account_balance_rounded,
        () => Get.toNamed(AppRoutes.builtHistory),
      ),
    ];
    return Container(
      color: _kCard,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore Other Trackers',
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kDark,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: links
                .map(
                  (l) => GestureDetector(
                    onTap: l.$3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_kBg, Colors.white],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kDivider),
                      ),
                      child: Row(
                        children: [
                          Icon(l.$2, size: 18, color: AppColors.primaryBlue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l.$1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _kDark,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: _kSubtext,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
