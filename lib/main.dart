// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'point/core/firebase_initializer.dart';
import 'point/core/dependency_injection.dart';
import 'point/routes/app_routes.dart';



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
    return GetMaterialApp(
      title: 'Mjengo Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      getPages: AppRoutes.routes,
      initialRoute: AppRoutes.splash,
    );
  }
}