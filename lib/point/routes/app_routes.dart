// lib/routes/app_routes.dart
import 'package:get/get.dart';

import '../../auth/screens/login_screen.dart';
import '../../auth/screens/reset_password_screen.dart';
import '../../auth/screens/verify_otp_screen.dart';
import '../../auth/screens/two_factor_screen.dart';
import '../../onboarding/onboarding_screen.dart';
import '../../splash/splash_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String resetPassword = '/reset-password';
  static const String verifyOtp = '/verify-otp';
  static const String mfaEnroll = '/mfa-enroll';

  static List<GetPage> routes = [
    GetPage(
      name: splash,
      page: () => const ModernSplashScreen(),
    ),
    GetPage(
      name: onboarding,
      page: () => const OnboardingScreen(),
    ),
    GetPage(
      name: login,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: signup,
      page: () => const LoginScreen(startOnSignUp: true),
    ),
    GetPage(
      name: resetPassword,
      page: () => const ResetPasswordScreen(),
    ),
    GetPage(
      name: verifyOtp,
      page: () => const VerifyOtpScreen(),
    ),
    GetPage(
      name: mfaEnroll,
      page: () => const MfaEnrollScreen(),
    ),
  ];
}
