import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io' show Platform;
import '../auth/controllers/user_controller.dart';
import '../auth/controllers/mjengo_auth_controller.dart';
import '../point/routes/app_routes.dart';

class ModernSplashScreen extends StatefulWidget {
  const ModernSplashScreen({Key? key}) : super(key: key);

  @override
  State<ModernSplashScreen> createState() => _ModernSplashScreenState();
}

class _ModernSplashScreenState extends State<ModernSplashScreen>
    with TickerProviderStateMixin {
  // Controllers for state management
  UserController? _userController;

  // Animation controllers
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  /// Matches home hero / app chrome (see `HomeScreen`).
  static const Color _brandPrimary = Color(0xFF22C55E);

  @override
  void initState() {
    super.initState();

    // On web, skip splash screen entirely and navigate immediately
    if (kIsWeb) {
      _startAppInitialization();
      return;
    }

    // Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    _logoController.forward();
    _startAppInitialization();
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _logoController.dispose();
    }
    super.dispose();
  }

  Future<void> _startAppInitialization() async {
    // Step 1: Initialize app state — failures here must NOT skip location check.
    try {
      await _initializeAppState();

      // Mobile: Wait for MjengoAuthController + UserController to finish initializing (max 5s)
      if (!kIsWeb) {
        final startTime = DateTime.now();
        MjengoAuthController? mjengoAuth;
        try { mjengoAuth = Get.find<MjengoAuthController>(); } catch (_) {}
        while (mjengoAuth != null && !mjengoAuth.isInitialized) {
          await Future.delayed(const Duration(milliseconds: 100));
          if (DateTime.now().difference(startTime).inMilliseconds >= 5000) break;
        }
        if (_userController != null) {
          while (!_userController!.isInitialized) {
            await Future.delayed(const Duration(milliseconds: 100));
            if (DateTime.now().difference(startTime).inMilliseconds >= 5000) break;
          }
        }
        final elapsed = DateTime.now().difference(startTime).inMilliseconds;
        if (elapsed < 2500) {
          await Future.delayed(Duration(milliseconds: 2500 - elapsed));
        }
      }
    } catch (e) {
      print('Initialization error: $e');
      // Continue — location check must still run.
    }

    // Step 2: Navigate based on app state.
    if (mounted) {
      _navigateBasedOnState();
    }
  }

  Future<void> _initializeAppState() async {
    try {
      _userController = Get.find<UserController>();
    } catch (e) {
      print('UserController not found: $e');
    }
  }

  bool _isMjengoUserLoggedIn() {
    try {
      final auth = Get.find<MjengoAuthController>();
      return auth.isAuthenticated;
    } catch (_) {
      return false;
    }
  }

  // Check if running on web or desktop
  bool _isWebOrDesktop() {
    if (kIsWeb) return true;
    try {
      return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    } catch (e) {
      return false;
    }
  }

  void _navigateBasedOnState() {
    String targetRoute = AppRoutes.login;

    try {
      if (_isMjengoUserLoggedIn()) {
        targetRoute = AppRoutes.home;
      } else if (_isWebOrDesktop()) {
        targetRoute = AppRoutes.login;
      } else {
        targetRoute = AppRoutes.onboarding;
      }
    } catch (e) {
      print('Error determining navigation state: $e');
      // Default to login on any error determining state
      targetRoute = AppRoutes.login;
    }

    // Navigate in a separate try-catch so a navigation failure doesn't silently swallow the error
    try {
      print('Navigating to: $targetRoute');
      Get.offAllNamed(targetRoute);
    } catch (e) {
      print('Navigation error to $targetRoute: $e');
      // Last resort: use the navigator directly
      try {
        Navigator.of(Get.context!).pushNamedAndRemoveUntil(
          targetRoute,
          (route) => false,
        );
      } catch (e2) {
        print('Fallback navigation also failed: $e2');
      }
    }
  }

  bool _checkIfUserIsLoggedIn() {
    try {
      // Check UserController auth status
      if (_userController != null) {
        return _userController!.isAuthenticated;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // On web, show minimal loading screen while navigating
    if (kIsWeb) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_brandPrimary),
          ),
        ),
      );
    }

    // Mobile: Solid green background with centred logo only.
    return Scaffold(
      backgroundColor: _brandPrimary,
      body: Center(
        child: AnimatedBuilder(
          animation: _logoController,
          builder: (context, child) {
            return Opacity(
              opacity: _logoOpacity.value,
              child: Transform.scale(
                scale: _logoScale.value,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    'assets/icon.jpg',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
