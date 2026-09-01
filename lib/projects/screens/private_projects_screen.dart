// lib/projects/screens/private_projects_screen.dart
//
// "Private Projects" tracker (renamed from "Private Developments"). The
// backend's `Project` table has no field distinguishing infrastructure from
// private-development projects (verified against models.py/api.py — no
// `project_type` column exists), so there is currently no way to filter a
// distinct list here. Rather than show a duplicate of the public Projects
// list mislabeled as "Private", this is gated until the backend adds a real
// discriminator.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/coming_soon.dart';

class PrivateProjectsScreen extends StatelessWidget {
  const PrivateProjectsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 20, color: AppColors.textDark),
                ),
                const SizedBox(width: 12),
                Text(
                  'Private Projects',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            child: ComingSoonPlaceholder(
              icon: Icons.apartment_rounded,
              title: 'Private Projects tracking is coming soon',
              message:
                  'This tracker needs a backend update to distinguish private '
                  'developments from public infrastructure projects. Check '
                  'back soon.',
            ),
          ),
        ],
      ),
    );
  }
}
