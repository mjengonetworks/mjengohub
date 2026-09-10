// lib/profile/cookie_policy_screen.dart
import 'package:flutter/material.dart';

import '../shared/widgets/legal_doc_screen.dart';

class CookiePolicyScreen extends StatelessWidget {
  const CookiePolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalDocScreen(
      title: 'Cookie Policy',
      lastUpdated: 'September 6, 2026',
      canonicalPath: '/cookie-policy',
      sections: [
        const DocSection(
          heading: '1. What This Policy Covers',
          blocks: [
            DocParagraph(
              'This Cookie Policy explains how Mjengo Hub, operated by Mjengo Networks Limited, uses '
              'cookies and similar tracking technologies on mjengohub.co.ke and in the Mjengo Hub app '
              '(where the platform equivalent — local storage and device identifiers — applies).',
            ),
          ],
        ),
        const DocSection(
          heading: '2. What Are Cookies',
          blocks: [
            DocParagraph(
              'Cookies are small data files stored on your device when you visit a website. First-party '
              'cookies are set by us; third-party cookies are set by our advertising, analytics, and other '
              'partners to enable their own features.',
            ),
          ],
        ),
        const DocSection(
          heading: '3. Types of Cookies We Use',
          blocks: [
            DocSubheading('Essential Cookies'),
            DocParagraph(
              'Required for core functionality such as signing in, keeping your session active, and '
              'security. Retention: session to 1 year.',
            ),
            DocSubheading('Analytics Cookies'),
            DocParagraph(
              'Help us understand how visitors use the platform (page views, popular content) via Google '
              'Analytics. Retention: up to 2 years. Legal basis: your consent.',
            ),
            DocSubheading('Advertising Cookies'),
            DocParagraph(
              'Used by our ad partners to deliver and measure advertising. Retention: up to 2 years. '
              'Legal basis: your consent.',
            ),
            DocSubheading('Functional Cookies'),
            DocParagraph(
              'Remember preferences such as theme and display settings. Retention: up to 1 year.',
            ),
          ],
        ),
        const DocSection(
          heading: '4. Third-Party Advertising & Analytics Partners',
          blocks: [
            DocCallout(
              'We work with Journey by Mediavine and Google AdSense to serve advertising, and Google '
              'Analytics to measure traffic. These partners may set their own cookies and collect '
              'information about your visits to this and other websites in order to serve relevant ads and '
              'report on their performance. Review each partner\'s own privacy policy for details on how '
              'they process this data.',
            ),
          ],
        ),
        const DocSection(
          heading: '5. Managing Your Cookie Preferences',
          blocks: [
            DocParagraph('You can control cookies through your browser settings at any time:'),
            DocBullets([
              'Chrome: Settings → Privacy and security → Cookies and other site data',
              'Firefox: Settings → Privacy & Security → Cookies and Site Data',
              'Safari: Settings → Privacy → Manage Website Data',
              'Edge: Settings → Cookies and site permissions',
              'Mobile app: cookies apply to embedded web content only; most in-app preferences are stored locally on your device and can be cleared by signing out or clearing app storage',
            ]),
            DocParagraph(
              'Disabling essential cookies may prevent parts of the platform, such as sign-in, from '
              'working correctly.',
            ),
          ],
        ),
        const DocSection(
          heading: '6. Changes to This Policy',
          blocks: [
            DocParagraph(
              'We may update this Cookie Policy from time to time. We will reflect changes with a new '
              '"Last updated" date above.',
            ),
          ],
        ),
        const DocSection(
          heading: '7. Contact Us',
          blocks: [
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
