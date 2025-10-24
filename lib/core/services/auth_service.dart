import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']);

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
    await _googleSignIn.signOut(); // force account chooser every time

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthCancelledException();
    }

    final googleAuth = await googleUser.authentication;
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
      appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthCancelledException();
      }
      rethrow;
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
    required String phoneNumber,
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
      'mobileNumber': phoneNumber.trim(),
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

  Future<void> _ensureUserDocument(User user) async {
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
  }
}
