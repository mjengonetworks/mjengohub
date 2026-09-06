// lib/profile/privacy_policy_screen.dart
import 'package:flutter/material.dart';

import '../shared/widgets/legal_doc_screen.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LegalDocScreen(
      title: 'Privacy Policy',
      lastUpdated: 'September 6, 2026',
      canonicalPath: '/privacy-policy',
      sections: [
        const DocSection(
          heading: '1. Introduction',
          blocks: [
            DocParagraph(
              'Mjengo Hub ("we," "our," or "us") is operated by Mjengo Networks Limited, '
              'a company registered in Nairobi, Kenya. This Privacy Policy explains how we '
              'collect, use, disclose, and safeguard information when you use the Mjengo Hub '
              'website (mjengohub.co.ke) and mobile app, and it is written to comply with the '
              'Kenya Data Protection Act, 2019.',
            ),
          ],
        ),
        const DocSection(
          heading: '2. Information We Collect',
          blocks: [
            DocSubheading('2.1 Information you provide'),
            DocParagraph('We collect information you give us directly when you:'),
            DocBullets([
              'Register an account (email, name, and password, or a Google sign-in)',
              'Complete your profile (bio, company, avatar and cover photo)',
              'Submit a project, incident report, article, review, comment, or infrastructure report',
              'Report a road safety or site safety incident, including any photos you attach',
              'Post to Mshikamano, our mental-health support community',
              'Contact us, subscribe to the newsletter, or enquire about advertising',
              'Redeem a referral code or file a copyright claim',
            ]),
            DocSubheading('2.2 Information collected automatically'),
            DocParagraph(
              'When you use the platform we automatically collect device and usage information such '
              'as IP address, approximate location, browser or device type, operating system, pages '
              'viewed, and referring links, generally through cookies and similar technologies — see '
              'our Cookie Policy for details.',
            ),
          ],
        ),
        const DocSection(
          heading: '3. How We Use Your Information',
          blocks: [
            DocBullets([
              'To create and secure your account and authenticate you across sessions',
              'To operate the platform\'s trackers, community submissions, and gamification (points, referrals, leaderboards)',
              'To moderate and publish user-submitted content (projects, incidents, reports, reviews, comments)',
              'To respond to enquiries and provide customer support',
              'To send service and, with your consent, marketing communications',
              'To measure usage and improve the platform',
              'To detect, prevent, and address fraud, abuse, and security issues',
              'To comply with legal obligations under Kenyan law',
            ]),
          ],
        ),
        const DocSection(
          heading: '4. How We Share Information',
          blocks: [
            DocParagraph(
              'We do not sell your personal information. We share it only in the following circumstances:',
            ),
            DocBullets([
              'With trusted third-party cloud hosting, database services, authentication providers, and Content Delivery Networks (CDNs) that operate the platform on our behalf, under confidentiality obligations',
              'With advertising and analytics partners — see Section 5',
              'When required by law, court order, or a valid request from a Kenyan government authority',
              'In connection with a merger, acquisition, or sale of some or all of our assets',
              'With your consent, or at your direction (for example, content you choose to make public)',
            ]),
            DocParagraph(
              'Content you submit for publication — project entries, incident reports, articles, reviews, '
              'and comments — is public by design once approved, and may display your name or username.',
            ),
          ],
        ),
        const DocSection(
          heading: '5. Advertising & Analytics Partners',
          blocks: [
            DocCallout(
              'Mjengo Hub displays advertising through Journey by Mediavine and Google AdSense, and measures '
              'traffic with Google Analytics. These partners may use cookies or similar technologies to serve '
              'ads and measure their performance, and may collect information about your visits to this and '
              'other websites. See our Cookie Policy for how to manage these preferences, and each partner\'s '
              'own privacy policy for how they handle data.',
            ),
          ],
        ),
        const DocSection(
          heading: '6. Data Security',
          blocks: [
            DocParagraph(
              'We use industry-standard safeguards — encrypted transmission, access controls, and secure '
              'infrastructure provided by our trusted third-party cloud hosting and database partners — to '
              'protect your information. No method of transmission or storage is completely secure, and we '
              'cannot guarantee absolute security.',
            ),
          ],
        ),
        const DocSection(
          heading: '7. Your Rights',
          blocks: [
            DocParagraph(
              'Under the Kenya Data Protection Act, 2019, you have the right to:',
            ),
            DocBullets([
              'Access the personal data we hold about you',
              'Request correction of inaccurate or incomplete data',
              'Request deletion of your data, subject to legal retention requirements',
              'Object to or restrict certain processing, including marketing',
              'Request a portable copy of your data',
              'Lodge a complaint with the Office of the Data Protection Commissioner, Kenya',
            ]),
            DocParagraph('To exercise any of these rights, contact us at info@mjengohub.com.'),
          ],
        ),
        const DocSection(
          heading: '8. Platform Content Is Informational',
          blocks: [
            DocCallout(
              'Data shown across our trackers — Infrastructure, Private Developments, Built History, Africa '
              '& World, Site Safety, and Merch — as well as any cost indices or estimates, is published for '
              'journalistic and informational purposes only. It is not a legal or engineering certification of '
              'any project, and it is not a guarantee relating to tender procurement or contract award.',
            ),
          ],
        ),
        const DocSection(
          heading: "9. Children's Privacy",
          blocks: [
            DocParagraph(
              'Our services are not directed at individuals under 18, and we do not knowingly collect personal '
              'information from children. If we learn we have done so, we will delete it promptly.',
            ),
          ],
        ),
        const DocSection(
          heading: '10. Changes to This Policy',
          blocks: [
            DocParagraph(
              'We may update this Privacy Policy from time to time. Material changes will be reflected by an '
              'updated "Last updated" date above, and, where appropriate, by direct notice. Continued use of '
              'Mjengo Hub after a change constitutes acceptance of the revised policy.',
            ),
          ],
        ),
        const DocSection(
          heading: '11. Contact & Governing Law',
          blocks: [
            DocParagraph(
              'This Privacy Policy is governed by the laws of Kenya. For any questions about this policy or '
              'our data practices, contact:',
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
