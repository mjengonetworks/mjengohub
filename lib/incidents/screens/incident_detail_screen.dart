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
import '../../news/widgets/net_image.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/coming_soon.dart';
import '../../shared/widgets/form_fields.dart';

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

              // ── Suggest a correction / claim copyright (parity with
              // templates/incident_detail.html's two sidebar cards) ────────
              Container(
                color: _kCard,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionChip(
                        icon: Icons.edit_note_rounded,
                        label: 'Suggest Edit',
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => _IncidentSuggestEditSheet(incident: incident),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionChip(
                        icon: Icons.copyright_rounded,
                        label: 'Claim Copyright',
                        onTap: () => showComingSoonSnack(
                            'Copyright claims aren\'t available in the app yet.'),
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

// ── Suggest a Correction / Claim Copyright action row ───────────────────────

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
            Icon(icon, size: 16, color: AppColors.primaryBlue),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.montserrat(
                    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryBlue)),
          ],
        ),
      ),
    );
  }
}

/// Bottom-sheet shell shared by both forms below — matches the rounded
/// white-card look already used across the app's other submission sheets.
class _IncidentSheetShell extends StatelessWidget {
  final String title;
  final Widget child;
  const _IncidentSheetShell({required this.title, required this.child});

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
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
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
                  fontWeight: FontWeight.w800,
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

/// Mirrors templates/incident_detail.html's "Suggest a Correction" card,
/// via `POST incidents/{id}/suggest-edit`.
class _IncidentSuggestEditSheet extends StatefulWidget {
  final Incident incident;
  const _IncidentSuggestEditSheet({required this.incident});

  @override
  State<_IncidentSuggestEditSheet> createState() => _IncidentSuggestEditSheetState();
}

class _IncidentSuggestEditSheetState extends State<_IncidentSuggestEditSheet> {
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
      Get.snackbar('Missing info', 'Please enter your name and the corrected value.',
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return;
    }
    setState(() => _submitting = true);
    final ok = await IncidentsService().suggestEdit(
      incidentId: widget.incident.id,
      fieldName: _field,
      proposedValue: _valueCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
      reason: _reasonCtrl.text.trim().isNotEmpty ? _reasonCtrl.text.trim() : null,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.of(context).pop();
    Get.snackbar(
      ok ? 'Thanks!' : 'Couldn\'t submit',
      ok ? 'Your correction has been sent for review.' : 'Please try again.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _IncidentSheetShell(
      title: 'Suggest a Correction',
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
          AppTextField(controller: _valueCtrl, hint: 'Proposed value', maxLines: 2),
          const SizedBox(height: 12),
          const FieldLabel('Reason / source'),
          AppTextField(controller: _reasonCtrl, hint: 'Optional', maxLines: 2),
          const SizedBox(height: 16),
          AppSubmitButton(label: 'Submit Correction', busy: _submitting, onPressed: _submit),
        ],
      ),
    );
  }
}

