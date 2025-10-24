import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:qadaa_prayer_tracker/models/daily_totals.dart';

class UserRepository {
  UserRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;

  Future<Map<String, dynamic>> loadUserDocument() async {
    final user = currentUser;
    if (user == null) return const {};
    final snapshot = await _firestore.collection('Users').doc(user.uid).get();
    return snapshot.data() ?? const {};
  }

  Future<Map<String, dynamic>> loadLogs() async {
    final data = await loadUserDocument();
    return Map<String, dynamic>.from(data['logs'] ?? {});
  }

  Future<Map<String, dynamic>> loadPrayerPlan() async {
    final data = await loadUserDocument();
    return Map<String, dynamic>.from(data['prayerPlan'] ?? {});
  }

  Future<DailyTotals?> loadMissedTotals() async {
    final plan = await loadPrayerPlan();
    final missed = Map<String, dynamic>.from(plan['missedPrayers'] ?? {});
    if (missed.isEmpty) return null;
    return DailyTotals.fromMap(missed);
  }

  Future<Map<String, int>> loadDailyPlan() async {
    final plan = await loadPrayerPlan();
    final dailyPlan = Map<String, dynamic>.from(plan['dailyPlan'] ?? {});
    return dailyPlan.map((key, value) => MapEntry(key, (value as num).toInt()));
  }

  Future<void> saveMissedTotals(DailyTotals totals) async {
    final user = currentUser;
    if (user == null) return;
    await _firestore.collection('Users').doc(user.uid).update({
      'prayerPlan.createdAt': FieldValue.serverTimestamp(),
      'prayerPlan.missedPrayers': totals.toMap(),
    });
  }

  Future<void> saveDailyPlan(Map<String, int> plan) async {
    final user = currentUser;
    if (user == null) return;
    await _firestore.collection('Users').doc(user.uid).update({
      'prayerPlan.createdAt': FieldValue.serverTimestamp(),
      'prayerPlan.dailyPlan': plan,
    });
  }

  Future<void> updateLogs(Map<String, dynamic> logs) async {
    final user = currentUser;
    if (user == null) return;
    await _firestore.collection('Users').doc(user.uid).update({'logs': logs});
  }

  Future<void> appendLogEntry(String prayerKey) async {
    final user = currentUser;
    if (user == null) return;
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
  }

  Future<void> resetData() async {
    final user = currentUser;
    if (user == null) return;
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
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
