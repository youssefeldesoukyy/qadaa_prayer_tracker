import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qadaa_prayer_tracker/main.dart';
import 'package:qadaa_prayer_tracker/models/daily_totals.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'guest_repository.dart';
import 'user_repository.dart';

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
    GuestRepository? guestRepository,
    UserRepository? userRepository,
  })  : _guestRepo = guestRepository ?? GuestRepository(),
        _userRepo = userRepository ??
            UserRepository(
              auth: auth,
              firestore: firestore,
            );

  final GuestRepository _guestRepo;
  final UserRepository _userRepo;

  Future<DashboardLoadResult> loadDashboardData(
    DailyTotals fallbackInitial,
  ) async {
    final useGuest = await _shouldUseGuestFlow();

    if (useGuest) {
      final totals = await _guestRepo.loadMissedTotals() ?? fallbackInitial;
      final logs = await _guestRepo.loadLogs();
      final completed = _aggregateLogs(logs);
      final remaining = _remainingFrom(totals, completed);
      final totalCompleted = _sum(completed);

      return DashboardLoadResult(
        initial: totals,
        remaining: remaining,
        totalCompleted: totalCompleted,
        isGuest: true,
        guestLogs: logs,
      );
    }

    final missedTotals = await _userRepo.loadMissedTotals() ?? fallbackInitial;
    final logs = await _userRepo.loadLogs();
    final completed = _aggregateLogs(logs);
    final remaining = _remainingFrom(missedTotals, completed);
    final totalCompleted = _sum(completed);

    return DashboardLoadResult(
      initial: missedTotals,
      remaining: remaining,
      totalCompleted: totalCompleted,
      isGuest: false,
    );
  }

  Future<Map<String, int>> loadGuestCompletionTotals() async {
    final logs = await _guestRepo.loadLogs();
    return _aggregateLogs(logs);
  }

  Future<Map<String, int>> loadUserCompletionTotals() async {
    final logs = await _userRepo.loadLogs();
    return _aggregateLogs(logs);
  }

  Future<Map<String, dynamic>> logGuestPrayer(
    String prayerKey,
    Map<String, dynamic> currentLogs,
  ) async {
    final dateKey = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final updatedLogs = Map<String, dynamic>.from(currentLogs);
    final todayLog = Map<String, dynamic>.from(updatedLogs[dateKey] ?? {
      'fajr': 0,
      'dhuhr': 0,
      'asr': 0,
      'maghrib': 0,
      'isha': 0,
    });

    todayLog[prayerKey] = (todayLog[prayerKey] ?? 0) + 1;
    updatedLogs[dateKey] = todayLog;

    await _guestRepo.saveLogs(updatedLogs);
    return updatedLogs;
  }

  Future<void> logUserPrayer(String prayerKey) async {
    await _userRepo.appendLogEntry(prayerKey);
  }

  Future<Map<String, dynamic>> loadGuestLogs() => _guestRepo.loadLogs();

  Future<Map<String, dynamic>> loadUserLogs() => _userRepo.loadLogs();

  Future<Map<String, int>> loadMissedTotals({required bool isGuest}) async {
    if (isGuest) {
      final totals = await _guestRepo.loadMissedTotals();
      if (totals == null) {
        return const {
          'fajr': 0,
          'dhuhr': 0,
          'asr': 0,
          'maghrib': 0,
          'isha': 0,
        };
      }
      return totals.toMap();
    }

    final totals = await _userRepo.loadMissedTotals();
    if (totals == null) {
      return const {
        'fajr': 0,
        'dhuhr': 0,
        'asr': 0,
        'maghrib': 0,
        'isha': 0,
      };
    }
    return totals.toMap();
  }

  Future<void> updateGuestLogs(Map<String, dynamic> logs) =>
      _guestRepo.saveLogs(logs);

  Map<String, int> aggregateLogs(Map<String, dynamic> logs) =>
      _aggregateLogs(logs);

  Future<void> resetFirestoreData() => _userRepo.resetData();

  Future<void> resetLocalGuestData() => _guestRepo.resetData();

  Future<void> clearLocalStorage({bool keepGuestFlag = false}) =>
      _guestRepo.clearStorage(keepGuestFlag: keepGuestFlag);

  Future<String> getSelectedLanguage() async {
    final code = await _guestRepo.loadLanguageCode();
    final langCode = code ?? 'ar';
    return langCode == 'ar' ? 'Arabic' : 'English';
  }

  Future<void> setSelectedLanguage(String langCode) =>
      _guestRepo.saveLanguageCode(langCode);

  Future<Map<String, int>> getCompletedCountsByPrayer({
    required bool isGuest,
  }) async {
    final logs = isGuest ? await _guestRepo.loadLogs() : await _userRepo.loadLogs();
    return _aggregateLogs(logs);
  }

  Future<void> saveMissedPrayers(
    DailyTotals totals, {
    bool? isGuest,
  }) async {
    final guestFlow = isGuest ?? await _shouldUseGuestFlow();

    if (guestFlow) {
      await _guestRepo.saveMissedTotals(totals);
      await _guestRepo.markProgress();
      return;
    }

    await _userRepo.saveMissedTotals(totals);
  }

  Future<void> saveDailyPlan(
    Map<String, int> dailyPlan, {
    bool? isGuest,
  }) async {
    final guestFlow = isGuest ?? await _shouldUseGuestFlow();

    if (guestFlow) {
      await _guestRepo.saveDailyPlan(dailyPlan);
      await _guestRepo.markProgress();
      return;
    }

    await _userRepo.saveDailyPlan(dailyPlan);
  }

  Future<Map<String, int>> loadCompletedCounts({required bool isGuest}) async {
    return isGuest
        ? loadGuestCompletionTotals()
        : loadUserCompletionTotals();
  }

  Future<void> enableGuestMode() => _guestRepo.enableGuestMode();

  Future<bool> useGuestFlow() => _shouldUseGuestFlow();

  Future<void> signOut() => _userRepo.signOut();

  Future<void> changeLanguage(BuildContext context, String langCode) async {
    await _guestRepo.saveLanguageCode(langCode);
    MyApp.setLocale(context, Locale(langCode));
  }

  // ------------------------------
  // Internal helpers
  // ------------------------------

  Future<bool> _shouldUseGuestFlow() async {
    final isGuestFlag = await _guestRepo.isGuest();
    return isGuestFlag || !_userRepo.isSignedIn;
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

  int _sum(Map<String, int> values) =>
      values.values.fold<int>(0, (previous, current) => previous + current);
}
