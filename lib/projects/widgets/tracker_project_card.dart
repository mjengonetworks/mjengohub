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
import '../../shared/theme/app_theme.dart';
import '../models/project_model.dart';
import '../screens/project_detail_screen.dart';

class TrackerProjectCard extends StatelessWidget {
  final Project project;

  /// Overrides the default bottom-left caption (status). Built History uses
  /// the decade, Africa & World uses the country — whichever is more useful
  /// than a status pill for that tracker.
  final String? captionOverride;
  final double width;

  const TrackerProjectCard({super.key, required this.project, this.captionOverride, this.width = 220});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => ProjectDetailScreen(slug: project.slug), transition: Transition.cupertino),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
          boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 3))],
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
                  NetImage(url: project.imageUrl, fit: BoxFit.cover, width: double.infinity, placeholderColor: const Color(0xFF1E3A5F)),
                  if (project.isLegacy)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _pill('LANDMARK', const Color(0xFFF59E0B)),
                    ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: _pill((captionOverride ?? project.statusLabel).toUpperCase(), AppColors.accentBlue),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                  ),
                  if ((project.county ?? project.location ?? project.country) != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 11, color: AppColors.textSubtle),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            project.county ?? project.location ?? project.country!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(fontSize: 10.5, color: AppColors.textSubtle),
                          ),
                        ),
                      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: GoogleFonts.montserrat(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white)),
      );
}
