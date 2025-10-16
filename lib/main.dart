import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:qadaa_prayer_tracker/l10n/app_localizations.dart';
import 'package:qadaa_prayer_tracker/Views/sign_in_screen.dart';
import 'package:qadaa_prayer_tracker/Views/Dashboard/home_dashboard.dart';
import 'package:qadaa_prayer_tracker/Views/qadaa_missed.dart';
import 'package:qadaa_prayer_tracker/models/daily_totals.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Load saved language before running app
  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString('language_code') ?? 'ar';
  runApp(MyApp(initialLang: savedLang));
}

class MyApp extends StatefulWidget {
  final String initialLang;

  const MyApp({super.key, this.initialLang = 'ar'});

  static void setLocale(BuildContext context, Locale newLocale) {
    final _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?._changeLanguage(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = Locale(widget.initialLang);
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString('language_code');
    if (savedLocale != null) {
      setState(() => _locale = Locale(savedLocale));
    }
  }

  void _changeLanguage(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<bool> _checkUserProfileExists(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();
    return doc.exists;
  }

  Future<Widget> _determineStartScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    // 🟢 CASE 1: Guest mode
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
          debugPrint('❌ Failed to decode guest data: $e');
          return const QadaaMissed(); // corrupted guest data
        }
      }

      return const QadaaMissed(); // no guest data at all
    }

    // 🟣 CASE 2: Firebase signed-in user
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

    // 🔴 CASE 3: No Firebase user and not a guest
    return const SignInScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _determineStartScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          debugPrint('❌ Error: ${snapshot.error}');
          return const Scaffold(
            body: Center(child: Text("Error loading user data.")),
          );
        } else {
          return snapshot.data ?? const SignInScreen();
        }
      },
    );
  }
}