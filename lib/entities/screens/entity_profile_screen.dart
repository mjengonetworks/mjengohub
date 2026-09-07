// lib/entities/screens/entity_profile_screen.dart
//
// Stakeholder profile screen for `GET entities/{slug}`. Reached from
// ProjectDetailScreen's Client/Contractor/Consultant/Financier tap targets.
// Client always carries a real slug (ProjectClient.slug); the other three
// are plain free-text strings with no entity linkage, so their taps guess a
// slug via shared/utils/slugify.dart. The entities table has exactly one
// populated row today (KeNHA), so a guessed-slug 404 is the common case, not
// an edge case — the not-found state below is written for that.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../news/widgets/net_image.dart';
import '../../point/routes/app_routes.dart';
import '../../shared/services/link_launcher.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/responsive.dart';
import '../models/entity_model.dart';
import '../services/entity_service.dart';

class EntityProfileScreen extends StatefulWidget {
  const EntityProfileScreen({super.key, required this.slug, this.fallbackName});

  final String slug;

  /// The plain-text stakeholder name that was tapped (contractor/consultant/
  /// financier), shown in the loading title and the not-found state since a
  /// guessed slug commonly won't resolve to a real entity yet.
  final String? fallbackName;

  @override
  State<EntityProfileScreen> createState() => _EntityProfileScreenState();
}

class _EntityProfileScreenState extends State<EntityProfileScreen> {
  final _api = EntityService();
  EntityModel? _entity;
  bool _loading = true;

  static const _roleOrder = ['client', 'contractor', 'consultant', 'financier'];
  static const _roleLabels = {
    'client': 'Client',
    'contractor': 'Contractor',
    'consultant': 'Consultant',
    'financier': 'Financier',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final e = await _api.fetchEntity(widget.slug);
    if (!mounted) return;
    setState(() {
      _entity = e;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final e = _entity;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          e?.name ?? widget.fallbackName ?? 'Profile',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.headingSlate,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.headingSlate))
          : e == null
              ? _notFound()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ContentWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _header(e),
                        const SizedBox(height: 16),
                        if ((e.bioText ?? '').isNotEmpty) ...[
                          _bioCard(e),
                          const SizedBox(height: 16),
                        ],
                        if ((e.mjengoNetworksUrl ?? '').isNotEmpty) ...[
                          _fullProfileButton(e),
                          const SizedBox(height: 16),
                        ],
                        if (e.totalLinkedProjects > 0) _projectsSection(e),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _notFound() {
    final name = widget.fallbackName;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.business_outlined, size: 44, color: AppColors.captionSlate),
            const SizedBox(height: 14),
            Text(
              name != null && name.isNotEmpty
                  ? "$name doesn't have a Mjengo Networks profile yet."
                  : 'This profile could not be found.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.headingSlate,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Verified stakeholder profiles are still being added.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontSize: 12.5, color: AppColors.captionSlate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(EntityModel e) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sharpLg),
        border: Border.all(color: AppColors.borderSlate),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sharp),
            child: NetImage(
              url: e.logoUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              placeholderColor: const Color(0xFFF1F5F9),
              placeholderIcon: Icons.business_rounded,
              placeholderIconColor: AppColors.captionSlate,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.name,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.headingSlate,
                    height: 1.25,
                  ),
                ),
                if ((e.originCountry ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _originBadge(e.originCountry!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _originBadge(String country) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(AppRadius.sharp),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.public_rounded, size: 12, color: AppColors.primaryBlue),
          const SizedBox(width: 5),
          Text(
            country,
            style: GoogleFonts.montserrat(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bioCard(EntityModel e) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sharpLg),
        border: Border.all(color: AppColors.borderSlate),
      ),
      child: Text(
        e.bioText!,
        style: GoogleFonts.montserrat(fontSize: 13.5, height: 1.6, color: AppColors.bodyCharcoal),
      ),
    );
  }

  Widget _fullProfileButton(EntityModel e) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => LinkLauncher.openLink(context, e.mjengoNetworksUrl!),
        icon: const Icon(Icons.open_in_new_rounded, size: 16),
        label: Text(
          'View Full Profile on Mjengo Networks',
          style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.headingSlate,
          side: const BorderSide(color: AppColors.borderSlate),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sharp)),
        ),
      ),
    );
  }

  Widget _projectsSection(EntityModel e) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Projects',
          style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.headingSlate),
        ),
        const SizedBox(height: 12),
        for (final role in _roleOrder)
          if ((e.projectsByRole[role] ?? const []).isNotEmpty) ...[
            Text(
              _roleLabels[role] ?? role,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.captionSlate,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            ...e.projectsByRole[role]!.map(_projectRow),
            const SizedBox(height: 14),
          ],
      ],
    );
  }

  Widget _projectRow(EntityProjectRef p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sharp),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sharp),
          onTap: p.slug.isEmpty ? null : () => Get.toNamed(AppRoutes.projectDetail, arguments: p.slug),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sharp),
              border: Border.all(color: AppColors.borderSlate),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sharp),
                  child: NetImage(
                    url: p.imageUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    placeholderColor: const Color(0xFFF1F5F9),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    p.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.bodyCharcoal,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: AppColors.captionSlate, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
