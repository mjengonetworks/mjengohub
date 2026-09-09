import 'package:flutter/material.dart';

import '../constants/legal_texts.dart';
import '../shared/widgets/legal_doc_screen.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) => LegalDocScreen(
    title: 'Terms of Service',
    lastUpdated: 'September 2026',
    canonicalPath: '/terms-of-service',
    sections: _sections(LegalTexts.termsOfServiceText),
  );

  static List<DocSection> _sections(List<LegalSectionText> source) => source
      .map(
        (section) => DocSection(
          heading: section.heading,
          blocks: [
            ...section.paragraphs.map((text) => DocParagraph(text)),
            if (section.bullets.isNotEmpty) DocBullets(section.bullets),
            if (section.callout != null) DocCallout(section.callout!),
          ],
        ),
      )
      .toList();
}
