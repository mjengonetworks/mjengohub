// lib/shared/widgets/legal_doc_screen.dart
//
// Shared scaffold for the legal/documentation screens (Privacy Policy, Terms
// of Service, Cookie Policy, About Us, Support Us) so they read as one
// consistent, high-contrast document system rather than seven hand-rolled
// pages. Content is passed in as a list of [DocSection]s built from simple
// [DocBlock]s (paragraph / bullets / subheading / callout).
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import 'responsive.dart';

const Color kDocCalloutBg = Color(0xFFF8FAFC);

abstract class DocBlock {
  const DocBlock();
}

class DocParagraph extends DocBlock {
  final String text;
  const DocParagraph(this.text);
}

class DocSubheading extends DocBlock {
  final String text;
  const DocSubheading(this.text);
}

class DocBullets extends DocBlock {
  final List<String> items;
  const DocBullets(this.items);
}

/// A bordered, slate-50 callout box — used for disclaimers and ad/analytics
/// notices that should stand apart from the surrounding body copy.
class DocCallout extends DocBlock {
  final String text;
  const DocCallout(this.text);
}

class DocSection {
  final String heading;
  final List<DocBlock> blocks;
  const DocSection({required this.heading, required this.blocks});
}

class LegalDocScreen extends StatelessWidget {
  final String title;
  final String lastUpdated;
  final List<DocSection> sections;
  final String canonicalPath;

  const LegalDocScreen({
    super.key,
    required this.title,
    required this.lastUpdated,
    required this.sections,
    required this.canonicalPath,
  });

  Future<void> _openCanonical() async {
    final uri = Uri.parse('https://mjengohub.co.ke$canonicalPath');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        foregroundColor: AppColors.headingSlate,
        titleSpacing: 0,
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.headingSlate,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderSlate),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: ContentWidth(
          maxWidth: 760,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.headingSlate,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Last updated: $lastUpdated',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.captionSlate,
                  ),
                ),
                const SizedBox(height: 24),
                for (final section in sections) _SectionView(section: section),
                const SizedBox(height: 8),
                Container(height: 1, color: AppColors.borderSlate),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _openCanonical,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.captionSlate,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 14),
                    label: Text(
                      'View canonical version on mjengohub.co.ke',
                      style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionView extends StatelessWidget {
  final DocSection section;
  const _SectionView({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.heading,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.headingSlate,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          for (final block in section.blocks) _BlockView(block: block),
        ],
      ),
    );
  }
}

class _BlockView extends StatelessWidget {
  final DocBlock block;
  const _BlockView({required this.block});

  static const _bodyStyle = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    color: AppColors.bodyCharcoal,
    height: 1.55,
  );

  @override
  Widget build(BuildContext context) {
    final block = this.block;

    if (block is DocParagraph) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(block.text, style: GoogleFonts.montserrat(textStyle: _bodyStyle)),
      );
    }

    if (block is DocSubheading) {
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: Text(
          block.text,
          style: GoogleFonts.montserrat(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: AppColors.headingSlate,
          ),
        ),
      );
    }

    if (block is DocBullets) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in block.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8, right: 10),
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.captionSlate,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(item, style: GoogleFonts.montserrat(textStyle: _bodyStyle)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    if (block is DocCallout) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kDocCalloutBg,
          border: Border.all(color: AppColors.borderSlate),
          borderRadius: BorderRadius.circular(AppRadius.sharp),
        ),
        child: Text(block.text, style: GoogleFonts.montserrat(textStyle: _bodyStyle)),
      );
    }

    return const SizedBox.shrink();
  }
}
