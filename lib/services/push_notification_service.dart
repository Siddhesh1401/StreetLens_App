import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
    required GlobalKey<ScaffoldMessengerState> messengerKey,
  }) async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    final token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenForCurrentUser(token);
    }

    _messaging.onTokenRefresh.listen((token) async {
      await _saveTokenForCurrentUser(token);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? 'StreetLens update';
      final body = message.notification?.body ?? 'You have a new notification.';

      messengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('$title: $body'),
            duration: const Duration(seconds: 4),
            backgroundColor: const Color(0xFF1565C0),
          ),
        );
    });
  }

  Future<void> syncCurrentUserToken() async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenForCurrentUser(token);
    }
  }

  Future<void> _saveTokenForCurrentUser(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set(
      {
        'fcm_tokens': FieldValue.arrayUnion([token]),
      },
      SetOptions(merge: true),
    );
  }
}