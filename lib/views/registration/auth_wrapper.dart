import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qadaa_prayer_tracker/core/app_colors.dart';
import 'package:qadaa_prayer_tracker/l10n/app_localizations.dart';
import 'package:qadaa_prayer_tracker/models/daily_totals.dart';
import 'package:qadaa_prayer_tracker/views/dashboard/home_dashboard.dart';
import 'package:qadaa_prayer_tracker/views/qadaa_missed.dart';
import 'package:qadaa_prayer_tracker/views/registration/sign_in_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<bool> _checkUserProfileExists(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();
    return doc.exists;
  }

  Future<Widget> _determineStartScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    // CASE 1: Guest mode
    final isGuest = prefs.getBool('isGuest') ?? false;
    if (isGuest) {
      final isGuestFirstTime = prefs.getBool('isGuestFirstTime') ?? true;

      if (isGuestFirstTime) {
        return const QadaaMissed(); // first-time guest setup
      }

      final totalsData = prefs.getString('guestTotals');
      final perDayData = prefs.getString('guestPerDay');

      if (totalsData != null) {
        try {
          final totals = DailyTotals.fromMap(jsonDecode(totalsData));
          final perDay = perDayData != null
              ? Map<String, int>.from(jsonDecode(perDayData))
              : null;
          return HomeDashboard(initial: totals, perDay: perDay);
        } catch (e) {
          debugPrint('Failed to decode guest data: $e');
          return const QadaaMissed(); // corrupted guest data
        }
      }

      return const QadaaMissed(); // no guest data at all
    }

    // CASE 2: Firebase signed-in user
    if (user != null) {
      final hasProfile = await _checkUserProfileExists(user.uid);
      if (hasProfile) {
        final userDoc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
        final data = userDoc.data() ?? {};
        final prayerPlan = data['prayerPlan'] as Map<String, dynamic>?;

        if (prayerPlan == null || prayerPlan['missedPrayers'] == null) {
          return const QadaaMissed();
        }

        final missedPrayers = Map<String, dynamic>.from(prayerPlan['missedPrayers'] ?? {});
        final totals = DailyTotals.fromMap(missedPrayers);

        final dailyPlanRaw = prayerPlan['dailyPlan'] as Map<String, dynamic>? ?? {};
        final perDay = dailyPlanRaw.map((key, value) => MapEntry(key, (value as num).toInt()));

        return HomeDashboard(initial: totals, perDay: perDay);
      } else {
        await FirebaseAuth.instance.signOut();
        return const SignInScreen();
      }
    }

    // CASE 3: No Firebase user and not a guest
    return const SignInScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _determineStartScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          );
        } else if (snapshot.hasError) {
          debugPrint('❌ Error: ${snapshot.error}');
          final loc = AppLocalizations.of(context);
          return Scaffold(
            body: Center(
              child: Text(loc?.errorLoadingUserData ?? "Error loading user data."),
            ),
          );
        } else {
          return snapshot.data ?? const SignInScreen();
        }
      },
    );
  }
}