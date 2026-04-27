import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shared_preferences/shared_preferences.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  FirebaseMessaging? _messaging;

  // Project ID from google-services.json
  static const String _projectId = 'campus-baloncesto';

  // Service account credentials - loaded from embedded JSON
  // The user must provide the service account JSON from Firebase Console
  static Map<String, dynamic>? _serviceAccountCredentials;

  /// Initialize Firebase and request notification permissions
  Future<void> initialize() async {
    if (kIsWeb) return; // FCM not configured for web yet

    _messaging = FirebaseMessaging.instance;

    try {
      // Request permissions (iOS needs explicit permission, Android 13+ too)
      // This is fast and local (shows a system dialog), so we can await it
      await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // Only subscribe to topics if we haven't done it before.
      // This avoids the SERVICE_NOT_AVAILABLE error on every startup.
      final prefs = await SharedPreferences.getInstance();
      final alreadySubscribed = prefs.getBool('fcm_general_subscribed') ?? false;

      if (!alreadySubscribed) {
        _messaging!.subscribeToTopic('campus_general').then((_) {
          prefs.setBool('fcm_general_subscribed', true);
          if (kDebugMode) print('FCM: Subscribed to campus_general');
        }).catchError((e) {
          if (kDebugMode) print('Error subscribing to general topic: $e');
        });
      }

      if (kDebugMode) {
        _messaging!.getToken().then((token) {
          print('FCM Token: $token');
        }).catchError((e) {
          // Silently ignore - token will be fetched when Play Services are ready
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Firebase Messaging permissions: $e');
      }
    }
  }

  /// Subscribe to staff topic (call this for admin/entrenador users)
  Future<void> subscribeToStaffTopic() async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadySubscribed = prefs.getBool('fcm_staff_subscribed') ?? false;
      if (alreadySubscribed) return;

      FirebaseMessaging.instance.subscribeToTopic('campus_staff').then((_) {
        prefs.setBool('fcm_staff_subscribed', true);
        if (kDebugMode) print('FCM: Subscribed to campus_staff');
      }).catchError((e) {
        if (kDebugMode) print('Error subscribing to staff topic: $e');
      });
    } catch (e) {
      if (kDebugMode) print('Error subscribing to staff topic: $e');
    }
  }

  /// Unsubscribe from staff topic (call if user role changes)
  Future<void> unsubscribeFromStaffTopic() async {
    if (kIsWeb) return;
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic('campus_staff');
    } catch (e) {
      if (kDebugMode) print('Error unsubscribing from staff topic: $e');
    }
  }

  /// Set the service account credentials
  static void setServiceAccountCredentials(Map<String, dynamic> credentials) {
    _serviceAccountCredentials = credentials;
  }

  Future<String?> _getAccessToken() async {
    if (_serviceAccountCredentials == null) return null;

    final email = _serviceAccountCredentials!['client_email'];
    final privateKey = _serviceAccountCredentials!['private_key'];

    final jwt = JWT({
      'iss': email,
      'scope': 'https://www.googleapis.com/auth/firebase.messaging',
      'aud': 'https://oauth2.googleapis.com/token',
      'exp': (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600,
      'iat': (DateTime.now().millisecondsSinceEpoch ~/ 1000),
    });

    final token = jwt.sign(
      RSAPrivateKey(privateKey),
      algorithm: JWTAlgorithm.RS256,
    );

    final response = await http.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': token,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['access_token'];
    }
    return null;
  }

  /// Send a push notification to a FCM topic using the V1 API
  /// [topic] can be 'campus_general' or 'campus_staff'
  Future<void> sendNotificationToTopic({
    required String title,
    required String body,
    required bool isStaffOnly,
  }) async {
    if (_serviceAccountCredentials == null) {
      if (kDebugMode)
        print(
          'Service account credentials not configured. Skipping notification.',
        );
      return;
    }

    final topic = isStaffOnly ? 'campus_staff' : 'campus_general';

    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) throw Exception('Failed to get access token');

      final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send',
      );

      final payload = {
        'message': {
          'topic': topic,
          'notification': {'title': title, 'body': body},
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'campus_notifications',
              'sound': 'default',
            },
          },
          'apns': {
            'payload': {
              'aps': {'sound': 'default', 'badge': 1},
            },
          },
        },
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );

      if (kDebugMode) {
        print('FCM Response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Error sending notification: $e');
    }
  }
}
