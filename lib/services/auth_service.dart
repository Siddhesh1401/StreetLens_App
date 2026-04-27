import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'push_notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Register with email & password
  Future<UserModel?> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = UserModel(
        userId: credential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        role: 'citizen',
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(user.toMap());

      await credential.user!.updateDisplayName(name);
      await PushNotificationService.instance.syncCurrentUserToken();
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Login with email & password
  Future<User?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await PushNotificationService.instance.syncCurrentUserToken();
      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      late final UserCredential credential;

      if (kIsWeb) {
        credential = await _auth.signInWithPopup(GoogleAuthProvider());
      } else {
        final googleUser = await GoogleSignIn(scopes: const ['email']).signIn();
        if (googleUser == null) return null;

        final googleAuth = await googleUser.authentication;
        final authCredential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        credential = await _auth.signInWithCredential(authCredential);
      }

      final firebaseUser = credential.user;
      if (firebaseUser == null) return null;

      final docRef = _firestore.collection('users').doc(firebaseUser.uid);
      final doc = await docRef.get();
      final existingData = doc.data();

      final displayName = (firebaseUser.displayName ?? '').trim().isNotEmpty
          ? firebaseUser.displayName!.trim()
          : (firebaseUser.email?.split('@').first ?? 'Google User');

      final user = UserModel(
        userId: firebaseUser.uid,
        name: displayName,
        email: firebaseUser.email ?? '',
        phone: (existingData?['phone'] as String?) ?? '',
        role: (existingData?['role'] as String?) ?? 'citizen',
        createdAt: (existingData?['created_at'] as dynamic)?.toDate() ??
            DateTime.now(),
      );

      await docRef.set(user.toMap(), SetOptions(merge: true));

      if ((firebaseUser.displayName ?? '').trim().isEmpty) {
        await firebaseUser.updateDisplayName(displayName);
      }

      await PushNotificationService.instance.syncCurrentUserToken();

      return firebaseUser;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user data
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
