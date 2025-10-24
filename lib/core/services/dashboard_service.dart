import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qadaa_prayer_tracker/models/daily_totals.dart';

class DashboardLoadResult {
  final DailyTotals initial;
  final DailyTotals remaining;
  final int totalCompleted;
  final bool isGuest;
  final Map<String, dynamic> guestLogs;

  const DashboardLoadResult({
    required this.initial,
    required this.remaining,
    required this.totalCompleted,
    required this.isGuest,
    Map<String, dynamic>? guestLogs,
  }) : guestLogs = guestLogs ?? const {};
}

class DashboardService {
  DashboardService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<DashboardLoadResult> loadDashboardData(DailyTotals fallbackInitial) async {
    final prefs = await SharedPreferences.getInstance();
    final isGuest = prefs.getBool('isGuest') ?? false;

    if (isGuest) {
      final totalsString = prefs.getString('guestTotals');
      final initial = totalsString != null
          ? DailyTotals.fromJson(jsonDecode(totalsString))
          : fallbackInitial;

      Map<String, dynamic> guestLogs = const {};
      final logsString = prefs.getString('guestLogs');
      if (logsString != null) {
        try {
          guestLogs = jsonDecode(logsString);
        } catch (e) {
          debugPrint('❌ Error decoding guest logs: $e');
          guestLogs = const {};
        }
      }

      final completed = _aggregateLogs(guestLogs);
      final remaining = _remainingFrom(initial, completed);
      final totalCompleted = _totalCompleted(completed);

      return DashboardLoadResult(
        initial: initial,
        remaining: remaining,
        totalCompleted: totalCompleted,
        isGuest: true,
        guestLogs: guestLogs,
      );
    }

    final user = _auth.currentUser;
    if (user == null) {
      return DashboardLoadResult(
        initial: fallbackInitial,
        remaining: fallbackInitial,
        totalCompleted: 0,
        isGuest: false,
      );
    }

    try {
      final doc = await _firestore.collection('Users').doc(user.uid).get();
      if (!doc.exists) {
        return DashboardLoadResult(
          initial: fallbackInitial,
          remaining: fallbackInitial,
          totalCompleted: 0,
          isGuest: false,
        );
      }

      final data = doc.data() ?? {};
      final prayerPlan = Map<String, dynamic>.from(data['prayerPlan'] ?? {});
      final missed =
          Map<String, dynamic>.from(prayerPlan['missedPrayers'] ?? {});
      final logs = Map<String, dynamic>.from(data['logs'] ?? {});

      final initial = DailyTotals(
        fajr: _asInt(missed['fajr']),
        dhuhr: _asInt(missed['dhuhr']),
        asr: _asInt(missed['asr']),
        maghrib: _asInt(missed['maghrib']),
        isha: _asInt(missed['isha']),
      );

      final completed = _aggregateLogs(logs);
      final remaining = _remainingFrom(initial, completed);
      final totalCompleted = _totalCompleted(completed);

      return DashboardLoadResult(
        initial: initial,
        remaining: remaining,
        totalCompleted: totalCompleted,
        isGuest: false,
      );
    } catch (e) {
      debugPrint('❌ Error loading dashboard data: $e');
      return DashboardLoadResult(
        initial: fallbackInitial,
        remaining: fallbackInitial,
        totalCompleted: 0,
        isGuest: false,
      );
    }
  }

  Future<Map<String, int>> loadGuestCompletionTotals() async {
    final prefs = await SharedPreferences.getInstance();
    final logsString = prefs.getString('guestLogs');

    if (logsString == null) {
      return {
        'fajr': 0,
        'dhuhr': 0,
        'asr': 0,
        'maghrib': 0,
        'isha': 0,
      };
    }

    try {
      final decoded = jsonDecode(logsString);
      if (decoded is Map<String, dynamic>) {
        return _aggregateLogs(decoded);
      }
    } catch (e) {
      debugPrint('❌ Error decoding guest logs: $e');
    }

    return {
      'fajr': 0,
      'dhuhr': 0,
      'asr': 0,
      'maghrib': 0,
      'isha': 0,
    };
  }

  Future<Map<String, int>> loadUserCompletionTotals() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {
        'fajr': 0,
        'dhuhr': 0,
        'asr': 0,
        'maghrib': 0,
        'isha': 0,
      };
    }

    try {
      final snapshot = await _firestore.collection('Users').doc(user.uid).get();
      final data = snapshot.data() ?? {};
      final logs = Map<String, dynamic>.from(data['logs'] ?? {});
      return _aggregateLogs(logs);
    } catch (e) {
      debugPrint('❌ Error loading user completion totals: $e');
      return {
        'fajr': 0,
        'dhuhr': 0,
        'asr': 0,
        'maghrib': 0,
        'isha': 0,
      };
    }
  }

  Future<Map<String, dynamic>> logGuestPrayer(
    String prayerKey,
    Map<String, dynamic> currentLogs,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final todayLog = Map<String, dynamic>.from(currentLogs[dateKey] ?? {
      'fajr': 0,
      'dhuhr': 0,
      'asr': 0,
      'maghrib': 0,
      'isha': 0,
    });

    todayLog[prayerKey] = (todayLog[prayerKey] ?? 0) + 1;
    final updatedLogs = Map<String, dynamic>.from(currentLogs);
    updatedLogs[dateKey] = todayLog;

    await prefs.setString('guestLogs', jsonEncode(updatedLogs));
    return updatedLogs;
  }

  Future<void> logUserPrayer(String prayerKey) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userRef = _firestore.collection('Users').doc(user.uid);
      final snapshot = await userRef.get();
      final data = snapshot.data() ?? {};
      final logs = Map<String, dynamic>.from(data['logs'] ?? {});
      final dateKey = DateFormat('dd-MM-yyyy').format(DateTime.now());
      final todayLog = Map<String, dynamic>.from(logs[dateKey] ?? {
        'fajr': 0,
        'dhuhr': 0,
        'asr': 0,
        'maghrib': 0,
        'isha': 0,
      });

      todayLog[prayerKey] = (todayLog[prayerKey] ?? 0) + 1;
      logs[dateKey] = todayLog;
      await userRef.update({'logs': logs});
    } catch (e) {
      debugPrint('❌ Error logging prayer: $e');
    }
  }

  Map<String, int> _aggregateLogs(Map<String, dynamic> rawLogs) {
    int loggedFajr = 0,
        loggedDhuhr = 0,
        loggedAsr = 0,
        loggedMaghrib = 0,
        loggedIsha = 0;

    if (rawLogs.isEmpty) {
      return {
        'fajr': loggedFajr,
        'dhuhr': loggedDhuhr,
        'asr': loggedAsr,
        'maghrib': loggedMaghrib,
        'isha': loggedIsha,
      };
    }

    try {
      if (rawLogs.values.isNotEmpty && rawLogs.values.first is Map) {
        for (final entry in rawLogs.values) {
          final day = Map<String, dynamic>.from(entry as Map);
          loggedFajr += _asInt(day['fajr']);
          loggedDhuhr += _asInt(day['dhuhr']);
          loggedAsr += _asInt(day['asr']);
          loggedMaghrib += _asInt(day['maghrib']);
          loggedIsha += _asInt(day['isha']);
        }
      } else if (rawLogs.containsKey('fajr')) {
        loggedFajr = _asInt(rawLogs['fajr']);
        loggedDhuhr = _asInt(rawLogs['dhuhr']);
        loggedAsr = _asInt(rawLogs['asr']);
        loggedMaghrib = _asInt(rawLogs['maghrib']);
        loggedIsha = _asInt(rawLogs['isha']);
      }
    } catch (e) {
      debugPrint('❌ Error aggregating logs: $e');
    }

    return {
      'fajr': loggedFajr,
      'dhuhr': loggedDhuhr,
      'asr': loggedAsr,
      'maghrib': loggedMaghrib,
      'isha': loggedIsha,
    };
  }

  DailyTotals _remainingFrom(
    DailyTotals initial,
    Map<String, int> completed,
  ) {
    return DailyTotals(
      fajr: (initial.fajr - (completed['fajr'] ?? 0)).clamp(0, initial.fajr),
      dhuhr:
          (initial.dhuhr - (completed['dhuhr'] ?? 0)).clamp(0, initial.dhuhr),
      asr: (initial.asr - (completed['asr'] ?? 0)).clamp(0, initial.asr),
      maghrib:
          (initial.maghrib - (completed['maghrib'] ?? 0)).clamp(0, initial.maghrib),
      isha: (initial.isha - (completed['isha'] ?? 0)).clamp(0, initial.isha),
    );
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}
  Future<void> resetGuestData() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language_code') ?? 'ar';
    await prefs.clear();
    await prefs.setBool('isGuest', true);
    await prefs.setString('language_code', lang);
    await prefs.remove('guestTotals');
    await prefs.remove('guestPerDay');
    await prefs.remove('guestLogs');
  }

  Future<void> resetUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userRef = _firestore.collection('Users').doc(user.uid);
      await userRef.update({
        'prayerPlan.missedPrayers': {
          'fajr': 0,
          'dhuhr': 0,
          'asr': 0,
          'maghrib': 0,
          'isha': 0,
        },
        'prayerPlan.dailyPlan': {
          'fajr': 0,
          'dhuhr': 0,
          'asr': 0,
          'maghrib': 0,
          'isha': 0,
        },
        'logs': {},
      });
    } catch (e) {
      debugPrint('❌ Error resetting user data: $e');
    }
  }

  Future<void> clearLocalStorage({bool keepGuestFlag = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language_code') ?? 'ar';
    await prefs.clear();
    if (keepGuestFlag) {
      await prefs.setBool('isGuest', true);
      await prefs.setString('language_code', lang);
    }
  }

  Future<void> saveMissedPrayers(DailyTotals totals, {required bool isGuest}) async {
    if (isGuest) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('guestTotals', jsonEncode(totals.toJson()));
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('Users').doc(user.uid).update({
        'prayerPlan.missedPrayers': totals.toMap(),
      });
    } catch (e) {
      debugPrint('❌ Error saving missed prayers: $e');
    }
  }

  Future<Map<String, int>> loadCompletedCounts({required bool isGuest}) async {
    if (isGuest) {
      return loadGuestCompletionTotals();
    }
    return loadUserCompletionTotals();
  }

  int _totalCompleted(Map<String, int> completed) {
    return completed.values.fold(0, (a, b) => a + b);
  }
