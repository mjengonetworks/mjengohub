// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'point/core/firebase_initializer.dart';
import 'point/core/dependency_injection.dart';
import 'point/routes/app_routes.dart';
import 'shared/theme/theme_controller.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await FirebaseInitializer.initialize();
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  try {
    // Initialize dependencies
    await DependencyInjection.init();
  } catch (e) {
    print('Dependency injection failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Apply Montserrat as the app-wide font via the text theme.
    final lightBase = ThemeData.light();
    final darkBase = ThemeData.dark();
    final theme = Get.find<ThemeController>();

    return Obx(() => GetMaterialApp(
          title: 'Mjengo Hub',
          debugShowCheckedModeBanner: false,
          theme: lightBase.copyWith(
            textTheme: GoogleFonts.montserratTextTheme(lightBase.textTheme),
          ),
          darkTheme: darkBase.copyWith(
            textTheme: GoogleFonts.montserratTextTheme(darkBase.textTheme),
          ),
          themeMode: theme.themeMode,
          getPages: AppRoutes.routes,
          initialRoute: AppRoutes.splash,
        ));
  }
}