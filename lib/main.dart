import 'package:campus_baloncesto_app/core/constants/supabase_constants.dart';
import 'package:campus_baloncesto_app/core/constants/firebase_constants.dart';
import 'package:campus_baloncesto_app/core/router/app_router.dart';
import 'package:campus_baloncesto_app/core/theme/app_theme.dart';
import 'package:campus_baloncesto_app/core/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// This MUST be a top-level function for background notifications
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Background notification is automatically shown by the system
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase ONLY on native platforms (Android/iOS)
    if (!kIsWeb) {
      await Firebase.initializeApp();
      // Register background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
  } catch (e) {
    if (kDebugMode) print('Error initializing Firebase: $e');
  }

  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: SupabaseConstants.supabaseUrl,
      anonKey: SupabaseConstants.supabaseAnonKey,
    );
  } catch (e) {
    if (kDebugMode) print('Error initializing Supabase: $e');
  }

  try {
    // Load Firebase service account credentials for sending notifications
    NotificationService.setServiceAccountCredentials(
      FirebaseConstants.serviceAccountCredentials,
    );

    // Initialize notifications (permissions + topic subscription)
    final notificationService = NotificationService();
    await notificationService.initialize();
  } catch (e) {
    if (kDebugMode) print('Error initializing Notifications: $e');
  }

  runApp(
    // ProviderScope is required for Riverpod
    const ProviderScope(
      child: CampusBaloncestoApp(),
    ),
  );
}

class CampusBaloncestoApp extends ConsumerWidget {
  const CampusBaloncestoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Campus Baloncesto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
