import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qadaa_prayer_tracker/models/daily_totals.dart';

class GuestRepository {
  Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  Future<bool> isGuest() async {
    final prefs = await _prefs;
    return prefs.getBool('isGuest') ?? false;
  }

  Future<void> enableGuestMode() async {
    final prefs = await _prefs;
    await prefs.setBool('isGuest', true);
  }

  Future<void> markProgress() async {
    final prefs = await _prefs;
    await prefs.setBool('isGuest', true);
    await prefs.setBool('isGuestFirstTime', false);
  }

  Future<Map<String, dynamic>> loadLogs() async {
    final prefs = await _prefs;
    final logsString = prefs.getString('guestLogs');
    if (logsString == null) return const {};
    try {
      final decoded = jsonDecode(logsString);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return const {};
  }

  Future<void> saveLogs(Map<String, dynamic> logs) async {
    final prefs = await _prefs;
    await prefs.setString('guestLogs', jsonEncode(logs));
  }

  Future<DailyTotals?> loadMissedTotals() async {
    final prefs = await _prefs;
    final totalsString = prefs.getString('guestTotals');
    if (totalsString == null) return null;
    try {
      final decoded = jsonDecode(totalsString);
      if (decoded is Map<String, dynamic>) {
        return DailyTotals.fromJson(decoded);
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveMissedTotals(DailyTotals totals) async {
    final prefs = await _prefs;
    await prefs.setString('guestTotals', jsonEncode(totals.toJson()));
  }

  Future<Map<String, int>> loadDailyPlan() async {
    final prefs = await _prefs;
    final planString = prefs.getString('guestPerDay');
    if (planString == null) return {};
    try {
      final decoded = jsonDecode(planString);
      if (decoded is Map<String, dynamic>) {
        return decoded.map((key, value) => MapEntry(key, (value as num).toInt()));
      }
    } catch (_) {}
    return {};
  }

  Future<void> saveDailyPlan(Map<String, int> dailyPlan) async {
    final prefs = await _prefs;
    await prefs.setString('guestPerDay', jsonEncode(dailyPlan));
  }

  Future<String?> loadLanguageCode() async {
    final prefs = await _prefs;
    return prefs.getString('language_code');
  }

  Future<void> saveLanguageCode(String code) async {
    final prefs = await _prefs;
    await prefs.setString('language_code', code);
  }

  Future<void> resetData() async {
    final prefs = await _prefs;
    final lang = prefs.getString('language_code') ?? 'ar';
    await prefs.clear();
    await prefs.setBool('isGuest', true);
    await prefs.setString('language_code', lang);
    await prefs.remove('guestTotals');
    await prefs.remove('guestPerDay');
    await prefs.remove('guestLogs');
  }

  Future<void> clearStorage({bool keepGuestFlag = false}) async {
    final prefs = await _prefs;
    final lang = prefs.getString('language_code');
    await prefs.clear();
    if (lang != null) {
      await prefs.setString('language_code', lang);
    }
    if (keepGuestFlag) {
      await prefs.setBool('isGuest', true);
    }
  }
}
