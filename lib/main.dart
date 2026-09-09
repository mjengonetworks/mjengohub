// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'point/core/firebase_initializer.dart';
import 'point/core/dependency_injection.dart';
import 'point/routes/app_routes.dart';
import 'shared/theme/app_theme.dart';
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
    // Apply a crisp, compact sans-serif hierarchy across native surfaces.
    final lightBase = ThemeData.light();
    final darkBase = ThemeData.dark();
    final theme = Get.find<ThemeController>();

    return Obx(() => GetMaterialApp(
          title: 'Mjengo Hub',
          debugShowCheckedModeBanner: false,
          theme: lightBase.copyWith(
            scaffoldBackgroundColor: AppColors.canvas,
            canvasColor: AppColors.canvas,
            cardColor: AppColors.surface,
            dividerColor: AppColors.divider,
            cardTheme: CardTheme(
              color: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
                side: const BorderSide(color: AppColors.divider),
              ),
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryBlue,
              primary: AppColors.primaryBlue,
              secondary: AppColors.accentBlue,
              surface: AppColors.surface,
              brightness: Brightness.light,
            ),
            textTheme: GoogleFonts.montserratTextTheme(lightBase.textTheme).apply(
              bodyColor: AppColors.bodyCharcoal,
              displayColor: AppColors.headingSlate,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.canvas,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              shape: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.canvas,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppColors.divider)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppColors.divider)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppColors.accentBlue, width: 1.5)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppColors.danger)),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppColors.danger, width: 1.5)),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(elevation: 0, backgroundColor: AppColors.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
          // Slate palette matching the website's footer aesthetic — not
          // pure black, so typography/icons/card boundaries stay legible.
          // Note: this sets the *default* Material theme (dialogs, base
          // scaffold/card colors, switches, ...); most screens in this
          // codebase hardcode AppColors.*/Colors.white rather than reading
          // Theme.of(context), so they won't visually follow this yet.
          darkTheme: darkBase.copyWith(
            textTheme: GoogleFonts.montserratTextTheme(darkBase.textTheme),
            scaffoldBackgroundColor: AppColorsDark.background,
            canvasColor: AppColorsDark.background,
            cardColor: AppColorsDark.card,
            dividerColor: AppColorsDark.border,
            colorScheme: darkBase.colorScheme.copyWith(
              surface: AppColorsDark.surface,
              onSurface: AppColorsDark.bodyText,
            ),
            appBarTheme: darkBase.appBarTheme.copyWith(
              backgroundColor: AppColorsDark.surface,
              foregroundColor: AppColorsDark.headingText,
              surfaceTintColor: AppColorsDark.surface,
            ),
          ),
          themeMode: theme.themeMode,
          getPages: AppRoutes.routes,
          initialRoute: AppRoutes.splash,
          // Required by flutter_quill's toolbar (unified rich-text editor,
          // Submit/Edit Project) for its own localized tooltips/labels.
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
        ));
  }
}
