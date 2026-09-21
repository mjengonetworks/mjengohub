// lib/projects/widgets/tracker_project_card.dart
//
// Shared 16:9 full-bleed project card used by every tracker surface: the
// homepage's Built History/Africa & World/Private Developments previews,
// and the two dedicated tracker screens themselves — one card, no
// duplicated markup per screen.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../news/widgets/net_image.dart';
import '../../point/routes/app_routes.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/slugify.dart';
import '../models/project_model.dart';
import '../screens/project_detail_screen.dart';

const Color _kContractorBlue = Color(0xFF0284C7);

class TrackerProjectCard extends StatelessWidget {
  final Project project;

  /// Overrides the default bottom-left caption (status). Built History uses
  /// the decade, Africa & World uses the country — whichever is more useful
  /// than a status pill for that tracker.
  final String? captionOverride;
  final double width;

  const TrackerProjectCard({
    super.key,
    required this.project,
    this.captionOverride,
    this.width = 220,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => Get.to(
        () => ProjectDetailScreen(slug: project.slug),
        transition: Transition.cupertino,
      ),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetImage(
                    url: project.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholderColor: const Color(0xFF1E3A5F),
                  ),
                  if (project.isLegacy)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _pill('LANDMARK', const Color(0xFFF59E0B)),
                    ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: _pill(
                      (captionOverride ?? project.statusLabel).toUpperCase(),
                      AppColors.accentBlue,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      height: 1.3,
                    ),
                  ),
                  if ((project.county ?? project.location ?? project.country) !=
                      null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            project.county ??
                                project.location ??
                                project.country!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              fontSize: 10.5,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      project.sectorLabel,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ),
                  if (project.contractor != null &&
                      project.contractor!.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: () => Get.toNamed(
                        AppRoutes.entityProfile,
                        arguments: {
                          'slug': slugify(project.contractor!),
                          'fallbackName': project.contractor!,
                        },
                      ),
                      child: Text(
                        project.contractor!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: _kContractorBlue,
                        ),
                      ),
                    ),
                  ],
                  if (project.budgetTierBracket != null ||
                      project.costUsdValue != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      project.budgetTier,
                      style: GoogleFonts.montserrat(
                        fontSize: 10.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: GoogleFonts.montserrat(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  );
}
