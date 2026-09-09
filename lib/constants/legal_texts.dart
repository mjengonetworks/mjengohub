/// Production legal and company copy shared by the About, Terms, and Privacy
/// screens. Keep policy copy in one place so mobile and web wording cannot
/// drift through duplicated widget literals.
class LegalSectionText {
  final String heading;
  final List<String> paragraphs;
  final List<String> bullets;
  final String? callout;

  const LegalSectionText({
    required this.heading,
    this.paragraphs = const [],
    this.bullets = const [],
    this.callout,
  });
}

abstract final class LegalTexts {
  static const aboutCompanyTitle =
      'Built Environment Intelligence for East Africa';
  static const aboutCompanySubtitle =
      'Mjengo Hub is Kenya and East Africa’s premier built environment info network, tracking infrastructure megaprojects, private developments, construction technology, site safety, built history, industry insights, and news.';
  static const disclaimer =
      'Clarification of Services: Mjengo Hub is an independent media, data, and digital intelligence network. We do not operate as a general construction contractor, architectural practice, engineering consultancy, or provider of direct soil testing and BOQ services.';

  static const termsOfServiceText = <LegalSectionText>[
    LegalSectionText(
      heading: '1. Acceptance and Scope',
      paragraphs: [
        'These Terms of Service govern your use of Mjengo Hub, its website, mobile application, trackers, editorial content, community features, and related services. Mjengo Hub is operated by Mjengo Networks Limited in Kenya. By accessing the platform, creating an account, or submitting content, you agree to these Terms. If you do not agree, do not use the platform.',
        'Mjengo Hub provides built-environment media, data, digital intelligence, and public-interest information. It is not a contractor, architectural practice, engineering consultancy, or direct soil-testing or BOQ provider.',
      ],
    ),
    LegalSectionText(
      heading: '2. Accounts and User Responsibilities',
      paragraphs: [
        'You must provide information that is accurate and current, protect your login credentials, and remain responsible for activity performed through your account. Authentication may be provided through email, Google OAuth, or Supabase-supported services.',
      ],
      bullets: [
        'Do not impersonate another person or misrepresent an affiliation.',
        'Do not upload malware, attempt unauthorised access, or interfere with platform security.',
        'Do not use the platform for unlawful, abusive, defamatory, or discriminatory activity.',
      ],
    ),
    LegalSectionText(
      heading: '3. Submissions, Moderation, and Public-Interest Disclosures',
      paragraphs: [
        'You confirm that project data, incident reports, articles, comments, images, and other material you submit is accurate to the best of your knowledge and that you have the right to share it. You grant Mjengo Networks Limited a non-exclusive licence to host, reproduce, edit for clarity and safety, publish, and distribute approved material on the platform and associated channels.',
        'Submissions may be reviewed, delayed, edited, rejected, or removed. Site-safety and incident material may be published in the public interest, including facts about hazards, accidents, failures, and responsible organisations, subject to moderation, fairness, and applicable law. Do not submit private, confidential, or identifying information about victims or vulnerable people unless you have a lawful basis to do so.',
      ],
    ),
    LegalSectionText(
      heading: '4. Acceptable Use and Anti-Scraping',
      paragraphs: [
        'You may view and use the platform for lawful personal, professional, research, and journalistic purposes. You may not systematically scrape, crawl, harvest, mirror, reproduce, resell, or bulk-download platform data or content without prior written permission. You may not bypass rate limits, access controls, attribution requirements, or technical measures.',
      ],
      bullets: [
        'Do not use automated tools to copy tracker records, images, profiles, or articles at scale.',
        'Do not use platform data to create a competing database or service without permission.',
        'We may suspend access, block automated traffic, or pursue lawful remedies for abuse.',
      ],
    ),
    LegalSectionText(
      heading: '5. Data Accuracy, Disclaimers, and Liability',
      paragraphs: [
        'Tracker records, project costs, locations, timelines, classifications, safety reports, estimates, and editorial material are provided for information, research, journalism, and public awareness. Data may be incomplete, delayed, user-submitted, or changed after publication. It is not a survey, valuation, tender certification, engineering certification, legal opinion, professional advice, or guarantee of procurement, award, safety, quality, or completion.',
        'The platform is provided on an “as available” basis. To the maximum extent permitted by law, Mjengo Networks Limited is not liable for indirect or consequential loss, or for decisions made solely in reliance on platform content. You should obtain independent professional advice before acting on project, construction, investment, or safety information.',
      ],
    ),
    LegalSectionText(
      heading: '6. Intellectual Property, Third Parties, and Changes',
      paragraphs: [
        'The Mjengo Hub name, branding, software, design, and original editorial material belong to Mjengo Networks Limited or its licensors. These Terms do not transfer ownership. Third-party links, services, authentication providers, maps, analytics, and advertising are governed by their own terms and policies, and we are not responsible for their independent content or practices.',
        'We may update the platform or these Terms. The revised version will show a new effective date. Continued use after publication of changes means you accept the revised Terms. We may suspend or terminate access for breach, abuse, security reasons, or legal compliance.',
      ],
    ),
    LegalSectionText(
      heading: '7. Governing Law and Contact',
      paragraphs: [
        'These Terms are governed by the laws of the Republic of Kenya. Disputes are subject to the jurisdiction of the courts of Kenya, unless applicable law requires another forum.',
      ],
      bullets: [
        'Company: Mjengo Networks Limited',
        'Website: mjengohub.co.ke',
        'General contact: info@mjengohub.co.ke',
      ],
    ),
  ];

  static const privacyPolicyText = <LegalSectionText>[
    LegalSectionText(
      heading: '1. Who We Are and This Policy',
      paragraphs: [
        'Mjengo Hub is operated by Mjengo Networks Limited. This Privacy Policy explains how we collect, use, share, retain, and protect personal data when you use our website and Flutter mobile application. It is intended to comply with the Kenya Data Protection Act, 2019 and applicable regulations.',
      ],
    ),
    LegalSectionText(
      heading: '2. Data We Collect and Why',
      paragraphs: [
        'We collect account and profile information you provide, including your name, email address, phone number, profile details, submissions, comments, media, and correspondence. We also receive authentication information when you use Google OAuth or Supabase authentication.',
        'We collect device, log, approximate location, usage, and diagnostic information needed to secure, operate, measure, and improve the service. Google Analytics 4 (GA4), Cloudflare, hosting providers, and similar infrastructure may process technical telemetry such as IP address, browser or device type, pages viewed, performance events, and security signals.',
      ],
      bullets: [
        'Provide accounts, trackers, submissions, notifications, support, and moderation.',
        'Protect the service, prevent fraud and abuse, and investigate security events.',
        'Understand usage and improve features, reliability, content, and accessibility.',
        'Meet legal, regulatory, safety, and public-interest obligations.',
      ],
    ),
    LegalSectionText(
      heading: '3. Cookies, Analytics, and Similar Technologies',
      paragraphs: [
        'We use essential storage and cookies for login sessions, security, preferences, and core functionality. With appropriate controls, analytics and measurement technologies such as GA4 and Cloudflare telemetry help us understand traffic, errors, performance, and aggregate product usage. Your browser or device may provide controls for cookies and tracking technologies; disabling essential storage may affect functionality.',
      ],
    ),
    LegalSectionText(
      heading: '4. Sharing, Transfers, and Public Content',
      paragraphs: [
        'We do not sell personal data. We share data with trusted processors that provide authentication, hosting, databases, analytics, content delivery, communications, security, and support, under appropriate contractual or technical safeguards. We may disclose information where required by law, court order, lawful authority, emergency, fraud investigation, or protection of rights.',
        'Approved project, article, incident, comment, and other community submissions are public by design and may display your name, profile, media, or other information included in the submission. Consider carefully what you publish, especially in site-safety and public-interest reports.',
      ],
    ),
    LegalSectionText(
      heading: '5. Security, Retention, and Children',
      paragraphs: [
        'We use reasonable administrative, organisational, and technical safeguards, including encrypted transmission, access controls, monitoring, and trusted infrastructure. No online service is completely secure. We retain information only for as long as reasonably necessary for the purposes described here, legal obligations, dispute resolution, safety, moderation, and legitimate business records.',
        'The service is not directed to children under 18. If you believe a child has provided personal data, contact us so we can assess and delete it where appropriate.',
      ],
    ),
    LegalSectionText(
      heading: '6. Your Rights and Contact',
      paragraphs: [
        'Subject to the Kenya Data Protection Act, 2019 and applicable limits, you may request access to, correction of, deletion of, restriction of, or portability of your personal data; object to certain processing; withdraw consent where processing is based on consent; and complain to the Office of the Data Protection Commissioner. We may need to verify your identity before responding.',
        'To exercise your rights or ask a privacy question, email privacy@mjengohub.co.ke. We will handle requests within the periods required by applicable law. This policy may change; the September 2026 version is the current production version when displayed in the app.',
      ],
      bullets: [
        'Privacy contact: privacy@mjengohub.co.ke',
        'Company: Mjengo Networks Limited, Nairobi, Kenya',
      ],
    ),
  ];
}
