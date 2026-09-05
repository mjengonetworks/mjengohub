// lib/news/widgets/tagged_project_card.dart
//
// High-contrast card shown directly above the in-article map when an
// article carries a `tagged_project` (Spec 6). No-op today — the current
// backend never sends `tagged_project`, so `article.taggedProject` is
// always null — but the app is ready to render it the moment it does.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../point/routes/app_routes.dart';
import '../../shared/theme/app_theme.dart';
import '../models/article_model.dart';
import '../widgets/net_image.dart';

class TaggedProjectCard extends StatelessWidget {
  final Article article;
  const TaggedProjectCard({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final project = article.taggedProject;
    if (project == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.projectDetail, arguments: project.slug),
        child: Container(
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
                    NetImage(url: project.imageUrl, fit: BoxFit.cover, placeholderColor: const Color(0xFF1E3A5F)),
                    if (project.trackerLabel?.isNotEmpty == true)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.headingSlate, borderRadius: BorderRadius.circular(AppRadius.sharp)),
                          child: Text(
                            project.trackerLabel!.toUpperCase(),
                            style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w500, color: Colors.white, letterSpacing: 0.4),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.headingSlate, height: 1.3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('View Tracker Project',
                        style: GoogleFonts.montserrat(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.accentBlue)),
                    const Icon(Icons.arrow_forward, size: 14, color: AppColors.accentBlue),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
