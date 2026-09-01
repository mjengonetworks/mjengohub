import '../../shared/screens/saved_items_screen.dart';
import '../../safety/screens/report_incident_screen.dart';
// lib/routes/app_routes.dart
import 'package:get/get.dart';

import '../../auth/screens/login_screen.dart';
import '../../auth/screens/reset_password_screen.dart';
import '../../onboarding/onboarding_screen.dart';
import '../../splash/splash_screen.dart';
import '../../navigation/main_navigation.dart';
import '../../news/screens/article_detail_screen.dart';
import '../../projects/screens/projects_screen.dart';
import '../../projects/screens/project_detail_screen.dart';
import '../../incidents/screens/incidents_list_screen.dart';
import '../../incidents/screens/incident_detail_screen.dart';
import '../../mental_health/screens/mshikamano_screen.dart';
import '../../projects/screens/private_projects_screen.dart';
import '../../search/screens/search_screen.dart';
import '../../profile/screens/referral_screen.dart';
import '../../profile/screens/points_screen.dart';
import '../../reports/screens/report_detail_screen.dart';
import '../../reports/screens/reports_screen.dart';
import '../../reports/screens/submit_report_screen.dart';
import '../../reviews/screens/reviews_screen.dart';
import '../../shared/screens/advertise_screen.dart';
import '../../service_catalog/screens/service_detail_screen.dart';
import '../../service_catalog/screens/services_screen.dart';

class AppRoutes {
  static const String splash         = '/splash';
  static const String onboarding     = '/onboarding';
  static const String login          = '/login';
  static const String signup         = '/signup';
  static const String resetPassword  = '/reset-password';
  static const String home           = '/home';
  static const String articleDetail  = '/article';

  // New sections
  static const String projects        = '/projects';
  static const String projectDetail   = '/project';
  static const String shareBarabara   = '/share-barabara';
  static const String siteSafety      = '/site-safety';
  static const String incidentDetail  = '/incident';
  static const String mshikamano      = '/mshikamano';
  static const String privateProjects = '/private-projects';
  static const String search          = '/search';
  static const String referral        = '/referral';
  static const String pointsBreakdown = '/points';

  // Website-parity sections backed by api.py endpoints that the app
  // previously didn't consume at all.
  static const String services        = '/services';
  static const String serviceDetail   = '/service';
  static const String reports         = '/reports';
  static const String reportDetail    = '/report';
  static const String submitReport    = '/submit-report';
  static const String reviews         = '/reviews';
  static const String advertise = '/advertise';
  static const String savedItems = '/saved-items';
  static const String reportIncident = '/report-incident';

  static List<GetPage> routes = [
    GetPage(name: splash,        page: () => const ModernSplashScreen()),
    GetPage(name: onboarding,    page: () => const OnboardingScreen()),
    GetPage(name: login,         page: () => const LoginScreen()),
    GetPage(name: signup,        page: () => const LoginScreen(startOnSignUp: true)),
    GetPage(name: resetPassword, page: () => const ResetPasswordScreen()),
    GetPage(name: home,          page: () => const MainNavigation()),
    GetPage(name: articleDetail, page: () => const ArticleDetailScreen()),

    // Projects
    GetPage(name: projects,       page: () => const ProjectsScreen()),
    GetPage(
      name: projectDetail,
      page: () {
        final slug = Get.arguments as String? ?? '';
        return ProjectDetailScreen(slug: slug);
      },
    ),

    // Incidents
    GetPage(
      name: shareBarabara,
      page: () => const IncidentsListScreen(incidentType: 'road_safety'),
    ),
    GetPage(
      name: siteSafety,
      page: () => const IncidentsListScreen(incidentType: 'site_safety'),
    ),
    GetPage(
      name: incidentDetail,
      page: () {
        final slug = Get.arguments as String? ?? '';
        return IncidentDetailScreen(slug: slug);
      },
    ),

    // Mental Health
    GetPage(name: mshikamano, page: () => const MshikamanoScreen()),

    // Private Projects (renamed from "Private Developments")
    GetPage(name: privateProjects, page: () => const PrivateProjectsScreen()),

    // Global search
    GetPage(name: search, page: () => const SearchScreen()),

    // Gamification / referrals
    GetPage(name: referral, page: () => const ReferralScreen()),
    GetPage(name: pointsBreakdown, page: () => const PointsScreen()),

    // Services catalogue (GET services, GET services/{slug}, POST request)
    GetPage(name: services, page: () => const ServicesScreen()),
    GetPage(
      name: serviceDetail,
      page: () {
        final slug = Get.arguments as String? ?? '';
        return ServiceDetailScreen(slug: slug);
      },
    ),

    // Infrastructure reports (GET/POST reports, vote)
    GetPage(name: reports, page: () => const ReportsScreen()),
    GetPage(
      name: reportDetail,
      page: () {
        final id = Get.arguments is int ? Get.arguments as int : 0;
        return ReportDetailScreen(reportId: id);
      },
    ),
    GetPage(name: submitReport, page: () => const SubmitReportScreen()),

    // Client reviews (GET/POST reviews)
    GetPage(name: reviews, page: () => const ReviewsScreen()),

    // Advertising enquiry (POST advertise)
          // Saved Items and Safety Reporting
      GetPage(name: savedItems, page: () => const SavedItemsScreen()),
      GetPage(name: reportIncident, page: () => const ReportIncidentScreen()),
      GetPage(name: advertise, page: () => const AdvertiseScreen()),
  ];
}

