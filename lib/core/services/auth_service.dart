import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:qadaa_prayer_tracker/core/services/auth_exceptions.dart';
import 'package:qadaa_prayer_tracker/core/services/auth_flow_result.dart';
import 'package:qadaa_prayer_tracker/models/daily_totals.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email'],
              // iOS client ID from Firebase - only needed on iOS
              // Android reads from google-services.json automatically
              clientId: Platform.isIOS
                  ? '749140650336-s1canm71ntv7qc020qjlr1mcfnlqk0pk.apps.googleusercontent.com'
                  : null,
            );

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  Future<User> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut(); // force account chooser every time
    } catch (e) {
      // Ignore sign out errors - user might not be signed in
      debugPrint('Google sign out error (ignored): $e');
    }

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthCancelledException();
    }

    final googleAuth = await googleUser.authentication;
    
    if (googleAuth.accessToken == null || googleAuth.idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-credentials',
        message: 'Google authentication failed: missing tokens',
      );
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'Unable to resolve the signed-in Google user.',
      );
    }

    await _ensureUserDocument(user);
    return user;
  }

  Future<User> signInWithApple() async {
    late AuthorizationCredentialAppleID appleCredential;
    try {
      if (Platform.isAndroid) {
        // Android requires webAuthenticationOptions
        appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          webAuthenticationOptions: WebAuthenticationOptions(
            clientId: 'com.itmam.app',
            redirectUri: Uri.parse(
              'https://itmam-9c9db.firebaseapp.com/__/auth/handler',
            ),
          ),
        );
      } else {
        // iOS doesn't need webAuthenticationOptions
        appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthCancelledException();
      }
      rethrow;
    }

    if (appleCredential.identityToken == null) {
      throw FirebaseAuthException(
        code: 'missing-credentials',
        message: 'Apple authentication failed: missing identity token',
      );
    }

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final userCredential = await _auth.signInWithCredential(oauthCredential);
    final user = userCredential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'Unable to resolve the signed-in Apple user.',
      );
    }

    await _ensureUserDocument(user);
    return user;
  }

  Future<AuthFlowResult> continueAsGuest(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuest', true);
    await prefs.setString('language_code', languageCode);

    final isFirstTime = prefs.getBool('isGuestFirstTime') ?? true;
    if (isFirstTime) {
      await prefs.setBool('isGuestFirstTime', true);
      return const AuthFlowResult.qadaaSetup();
    }

    final totalsData = prefs.getString('guestTotals');
    final perDayData = prefs.getString('guestPerDay');

    if (totalsData != null) {
      final totals = DailyTotals.fromJson(jsonDecode(totalsData));
      final perDay = perDayData != null
          ? Map<String, int>.from(jsonDecode(perDayData))
          : null;
      return AuthFlowResult.dashboard(totals: totals, perDay: perDay);
    }

    return const AuthFlowResult.qadaaSetup();
  }

  Future<AuthFlowResult> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'Unable to resolve the newly created user.',
      );
    }

    await _firestore.collection('Users').doc(user.uid).set({
      'id': user.uid,
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'email': email.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'prayerPlan': {
        'createdAt': FieldValue.serverTimestamp(),
        'dailyPlan': const <String, dynamic>{},
        'missedPrayers': const <String, dynamic>{},
      },
    });

    return const AuthFlowResult.qadaaSetup();
  }

  Future<AuthFlowResult> determinePostSignIn(User user) async {
    final doc = await _firestore.collection('Users').doc(user.uid).get();
    if (!doc.exists) {
      return const AuthFlowResult.qadaaSetup();
    }

    final data = doc.data() ?? {};
    final prayerPlan = data['prayerPlan'] as Map<String, dynamic>?;
    if (prayerPlan == null || prayerPlan['missedPrayers'] == null) {
      return const AuthFlowResult.qadaaSetup();
    }

    final missedPrayers =
        Map<String, dynamic>.from(prayerPlan['missedPrayers'] ?? {});
    final totals = DailyTotals.fromMap(missedPrayers);

    final dailyPlanRaw =
        prayerPlan['dailyPlan'] as Map<String, dynamic>? ?? {};
    final perDay = dailyPlanRaw.map(
      (key, value) => MapEntry(key, (value as num).toInt()),
    );

    return AuthFlowResult.dashboard(totals: totals, perDay: perDay);
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// Deletes the user account from Firebase Auth and Firestore
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No user is currently signed in.',
      );
    }

    final uid = user.uid;

    // Delete Firestore document first
    try {
      await _firestore.collection('Users').doc(uid).delete();
    } catch (e) {
      debugPrint('Error deleting Firestore document: $e');
      // Continue with auth deletion even if Firestore deletion fails
    }

    // Delete Firebase Auth user account
    await user.delete();
  }

  Future<void> _ensureUserDocument(User user) async {
    try {
      final userRef = _firestore.collection('Users').doc(user.uid);
      final snapshot = await userRef.get();
      if (snapshot.exists) return;

      final displayName = user.displayName?.trim() ?? '';
      final parts = displayName.isEmpty ? <String>[] : displayName.split(' ');
      final firstName = parts.isNotEmpty ? parts.first : '';
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      await userRef.set({
        'id': user.uid,
        'email': user.email,
        'firstName': firstName,
        'lastName': lastName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        debugPrint('⚠️ Firestore permission denied when ensuring user document. '
            'This might be due to security rules. Error: ${e.message}');
        // Continue anyway - the user is authenticated, they just can't access Firestore yet
        // This will be handled by determinePostSignIn which will return qadaaSetup
      } else {
        rethrow;
      }
    } catch (e) {
      debugPrint('Error ensuring user document: $e');
      // Don't rethrow - allow sign-in to continue
    }
  }
}
