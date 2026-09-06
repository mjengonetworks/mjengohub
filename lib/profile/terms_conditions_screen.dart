// lib/profile/terms_conditions_screen.dart
import 'package:flutter/material.dart';

import '../shared/widgets/legal_doc_screen.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LegalDocScreen(
      title: 'Terms of Service',
      lastUpdated: 'September 6, 2026',
      canonicalPath: '/terms-of-service',
      sections: [
        const DocSection(
          heading: '1. Acceptance of Terms',
          blocks: [
            DocParagraph(
              'These Terms of Service ("Terms") govern your use of Mjengo Hub — the website at '
              'mjengohub.co.ke and its companion mobile app — operated by Mjengo Networks Limited, '
              'a company registered in Nairobi, Kenya. By creating an account, submitting content, or '
              'otherwise using the platform, you agree to be bound by these Terms. If you do not agree, '
              'please do not use Mjengo Hub.',
            ),
          ],
        ),
        const DocSection(
          heading: '2. What Mjengo Hub Provides',
          blocks: [
            DocParagraph('Mjengo Hub is a Kenyan construction-industry platform offering:'),
            DocBullets([
              'Six core trackers: Infrastructure, Private Developments, Built History, Africa & World, Site Safety, and Merch',
              'Construction industry news, articles, and video content',
              'Road-safety and site-safety incident reporting',
              'Mshikamano, a mental-health support community for industry professionals',
              'A citizen infrastructure-reports channel and a services catalogue',
              'A points, referral, and reviewer-reputation (gamification) system',
            ]),
            DocCallout(
              'Tracker data, cost indices, and any estimates shown on the platform are provided for '
              'journalistic and informational purposes only. They are not legal or engineering '
              'certifications, and they are not guarantees relating to tender procurement or contract award.',
            ),
          ],
        ),
        const DocSection(
          heading: '3. Accounts',
          blocks: [
            DocParagraph(
              'You may create an account with an email and password or by signing in with Google. You '
              'agree to provide accurate information, keep your credentials secure, and accept '
              'responsibility for activity under your account. We may suspend or terminate accounts that '
              'violate these Terms.',
            ),
          ],
        ),
        const DocSection(
          heading: '4. User Submissions & Content',
          blocks: [
            DocParagraph(
              'When you submit a project, incident, report, article, comment, or review, you confirm the '
              'content is accurate to your knowledge and that you have the right to share it. You grant '
              'Mjengo Networks Limited a non-exclusive, worldwide licence to host, display, and distribute '
              'that content on the platform. Submissions go through moderation before publication and may '
              'be edited, rejected, or removed at our discretion — including content that is false, unsafe, '
              'defamatory, or infringes another party\'s rights.',
            ),
          ],
        ),
        const DocSection(
          heading: '5. Acceptable Use',
          blocks: [
            DocParagraph('You agree not to:'),
            DocBullets([
              'Use the platform for any unlawful purpose',
              'Impersonate another person or misrepresent your affiliation',
              'Upload malicious code or attempt to breach platform security',
              'Scrape or extract data from the platform without permission',
              'Post spam, harassment, or abusive content',
              'Submit knowingly false incident reports or project information',
              'Infringe the intellectual property rights of others',
            ]),
          ],
        ),
        const DocSection(
          heading: '6. Gamification, Points & Referrals',
          blocks: [
            DocParagraph(
              'Points, referral rewards, and leaderboard rankings have no cash value and are awarded at our '
              'discretion for approved activity on the platform. We may adjust, correct, or revoke points '
              'that result from abuse, fraud, or a system error.',
            ),
          ],
        ),
        const DocSection(
          heading: '7. Advertising & Third-Party Content',
          blocks: [
            DocParagraph(
              'Mjengo Hub displays advertising, including through Journey by Mediavine and Google AdSense, '
              'and may link to third-party websites and services. We are not responsible for the content, '
              'accuracy, or practices of third-party advertisers, sites, or services linked from the platform.',
            ),
          ],
        ),
        const DocSection(
          heading: '8. Intellectual Property',
          blocks: [
            DocParagraph(
              'The Mjengo Hub name, logo, design, and platform software are owned by Mjengo Networks Limited '
              'and protected by applicable intellectual property laws. Nothing in these Terms transfers '
              'ownership of our intellectual property to you.',
            ),
          ],
        ),
        const DocSection(
          heading: '9. Disclaimers & Limitation of Liability',
          blocks: [
            DocParagraph(
              'The platform and its content are provided "as is," without warranties of any kind. To the '
              'maximum extent permitted by Kenyan law, Mjengo Networks Limited is not liable for indirect, '
              'incidental, or consequential damages arising from your use of the platform, including '
              'decisions made in reliance on tracker data, cost indices, or user-submitted content.',
            ),
          ],
        ),
        const DocSection(
          heading: '10. Termination',
          blocks: [
            DocParagraph(
              'We may suspend or terminate your access to Mjengo Hub at any time for violation of these '
              'Terms. You may stop using the platform at any time; published content you submitted may '
              'remain unless you request its removal.',
            ),
          ],
        ),
        const DocSection(
          heading: '11. Changes to These Terms',
          blocks: [
            DocParagraph(
              'We may update these Terms from time to time. Continued use of Mjengo Hub after a change '
              'takes effect constitutes acceptance of the revised Terms.',
            ),
          ],
        ),
        const DocSection(
          heading: '12. Governing Law & Contact',
          blocks: [
            DocParagraph(
              'These Terms are governed by the laws of Kenya, and any disputes are subject to the exclusive '
              'jurisdiction of the courts of Kenya.',
            ),
            DocBullets([
              'Company: Mjengo Networks Limited',
              'Email: info@mjengohub.com',
              'Address: Nairobi, Kenya',
              'Website: mjengohub.co.ke',
            ]),
          ],
        ),
      ],
    );
  }
}
