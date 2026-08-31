// lib/projects/screens/project_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/controllers/mjengo_auth_controller.dart';
import '../../comments/services/comments_service.dart';
import '../../comments/widgets/comments_section.dart';
import '../../point/services/gamification_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/badges.dart';
import '../controllers/projects_controller.dart';
import '../models/project_model.dart';
import '../services/projects_service.dart';

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
            background: Stack(
              fit: StackFit.expand,
              children: [
                project.imageUrl != null
                    ? Image.network(project.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _heroPlaceholder())
                    : _heroPlaceholder(),
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
                            fontWeight: FontWeight.w800,
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
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        if (project.county != null || project.location != null)
                          Text(
                            '📍 ${project.county ?? project.location}',
                            style: GoogleFonts.montserrat(
                                fontSize: 13, color: _kSubtext),
                          ),
                        AddOnGooglePill(onTap: () => _openGoogleMaps(project)),
                      ],
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
                    const SizedBox(height: 14),

                    // Compact rating row
                    _CompactRatingRow(ctrl: ctrl, project: project),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Details card (primary section) ─────────────────────────
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

              // ── Renders (architectural impressions) ─────────────────────
              if (project.renderGallery.isNotEmpty)
                _buildGalleryCard('Architectural Renders', project.renderGallery),

              const SizedBox(height: 8),

              // ── Media / progress photos ──────────────────────────────────
              if (project.media.isNotEmpty)
                _buildGalleryCard(
                  'Photos & Media',
                  project.renderGallery.isNotEmpty ? project.progressGallery : project.media,
                ),

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

  Widget _heroPlaceholder() => Container(
        color: const Color(0xFF1E3A5F),
        child: const Center(
          child: Icon(Icons.business_rounded,
              color: Colors.white30, size: 64),
        ),
      );

  Future<void> _openGoogleMaps(Project project) async {
    final query = Uri.encodeComponent(
        '${project.title} ${project.county ?? project.location ?? ''}'.trim());
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

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

// ── Status dot (used in the hero badge) ───────────────────────────────────────

class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  Color get _color {
    switch (status) {
      case 'completed': return const Color(0xFF4ADE80);
      case 'ongoing': return const Color(0xFF60A5FA);
      case 'suspended':
      case 'stalled': return const Color(0xFFF87171);
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
              style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: _kDark)),
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
                            fontWeight: FontWeight.w700,
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
        title: Text('Sign in required', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
        content: Text('Please sign in to your Mjengo Hub account to continue.',
            style: GoogleFonts.montserrat(fontSize: 13.5, color: _kSubtext)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.montserrat(color: _kSubtext))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () { Navigator.pop(ctx); Get.toNamed('/login'); },
            child: Text('Sign In', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w700)),
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
              onTap: () => _requireAuth(context, () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _CopyrightClaimSheet(project: project),
                  )),
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
            Text(label, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700, color: _kBlue)),
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
              Text(title, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: _kDark)),
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
    setState(() => _submitting = true);
    final result = await ProjectsService().suggestEdit(
      projectId: widget.project.id,
      fieldName: _field,
      proposedValue: _valueCtrl.text.trim(),
      submitterName: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : null,
      submitterEmail: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
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
          TextField(controller: _nameCtrl, decoration: _sheetFieldDecoration('Your name (optional)')),
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
                  : Text('Submit', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyrightClaimSheet extends StatefulWidget {
  final Project project;
  const _CopyrightClaimSheet({required this.project});

  @override
  State<_CopyrightClaimSheet> createState() => _CopyrightClaimSheetState();
}

class _CopyrightClaimSheetState extends State<_CopyrightClaimSheet> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  XFile? _proof;
  bool _submitting = false;

  Future<void> _pickProof() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) setState(() => _proof = file);
  }

  Future<void> _submit() async {
    if (_descCtrl.text.trim().isEmpty || _nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) {
      Get.snackbar('Missing info', 'Please fill in your name, email, and description.',
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return;
    }
    setState(() => _submitting = true);
    final bytes = _proof != null ? await _proof!.readAsBytes() : null;
    final ok = await GamificationService().submitCopyrightClaim(
      contentType: 'project',
      contentId: widget.project.id,
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      proofBytes: bytes,
      proofFilename: _proof?.name,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.of(context).pop();
    Get.snackbar(ok ? 'Claim submitted' : 'Couldn\'t submit', ok ? 'Our team will review your claim shortly.' : 'Please try again later.',
        snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Claim Copyright / Report Content',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(controller: _nameCtrl, decoration: _sheetFieldDecoration('Your name')),
          const SizedBox(height: 12),
          TextField(controller: _emailCtrl, decoration: _sheetFieldDecoration('Your email')),
          const SizedBox(height: 12),
          TextField(controller: _descCtrl, decoration: _sheetFieldDecoration('Describe the issue'), maxLines: 3),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickProof,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.attach_file_rounded, size: 16, color: _kSubtext),
                  const SizedBox(width: 6),
                  Text(_proof == null ? 'Attach proof (optional)' : _proof!.name,
                      style: GoogleFonts.montserrat(fontSize: 12, color: _kSubtext)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Submit Claim', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w700)),
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
