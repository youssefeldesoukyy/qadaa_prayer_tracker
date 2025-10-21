import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qadaa_prayer_tracker/l10n/app_localizations.dart';

class EditLoggedPrayers extends StatefulWidget {
  const EditLoggedPrayers({super.key});

  @override
  State<EditLoggedPrayers> createState() => _EditLoggedPrayersState();
}

class _EditLoggedPrayersState extends State<EditLoggedPrayers> {
  bool _isGuest = false;
  Map<String, dynamic> _guestLogs = {};

  // total logged prayers so far
  Map<String, int> _currentTotals = {
    'fajr': 0,
    'dhuhr': 0,
    'asr': 0,
    'maghrib': 0,
    'isha': 0,
  };

  // total missed prayers (entered earlier)
  Map<String, int> _missedTotals = {
    'fajr': 0,
    'dhuhr': 0,
    'asr': 0,
    'maghrib': 0,
    'isha': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadInitialLogs();
  }

  Future<void> _loadInitialLogs() async {
    final prefs = await SharedPreferences.getInstance();
    _isGuest = prefs.getBool('isGuest') ?? false;

    if (_isGuest) {
      final logsString = prefs.getString('guestLogs');
      final missedString = prefs.getString('guestTotals'); // ✅ correct key

      if (logsString != null) {
        final data = jsonDecode(logsString);
        if (data is Map) _guestLogs = Map<String, dynamic>.from(data);
      }

      if (missedString != null) {
        final missedData = jsonDecode(missedString);
        _missedTotals = Map<String, int>.from(missedData.map(
              (key, value) => MapEntry(key, (value as num).toInt()),
        ));
      }

      _currentTotals = _calculateTotals(_guestLogs);
    } else {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data() ?? {};
          final logs = Map<String, dynamic>.from(data['logs'] ?? {});
          final missed = Map<String, dynamic>.from(
            (data['prayerPlan']?['missedPrayers']) ?? {},
          ); // ✅ correct Firestore path

          _currentTotals = _calculateTotals(logs);
          _missedTotals =
              missed.map((k, v) => MapEntry(k, (v as num).toInt()));
        }
      }
    }

    setState(() {});
    debugPrint('_missedTotals: $_missedTotals');
    debugPrint('_currentTotals: $_currentTotals');
  }

  Map<String, int> _calculateTotals(Map<String, dynamic> logs) {
    final totals = {
      'fajr': 0,
      'dhuhr': 0,
      'asr': 0,
      'maghrib': 0,
      'isha': 0,
    };

    for (var value in logs.values) {
      if (value is Map) {
        totals['fajr'] = totals['fajr']! + ((value['fajr'] ?? 0) as num).toInt();
        totals['dhuhr'] = totals['dhuhr']! + ((value['dhuhr'] ?? 0) as num).toInt();
        totals['asr'] = totals['asr']! + ((value['asr'] ?? 0) as num).toInt();
        totals['maghrib'] =
            totals['maghrib']! + ((value['maghrib'] ?? 0) as num).toInt();
        totals['isha'] = totals['isha']! + ((value['isha'] ?? 0) as num).toInt();
      }
    }

    return totals;
  }

  String _localizedPrayerName(String key, AppLocalizations loc) {
    switch (key) {
      case 'fajr':
        return loc.fajr;
      case 'dhuhr':
        return loc.dhuhr;
      case 'asr':
        return loc.asr;
      case 'maghrib':
        return loc.maghrib;
      case 'isha':
        return loc.isha;
      default:
        return key;
    }
  }


  // ✅ Only allow increment up to missed prayers total
  void _increment(String key) {
    final currentLogged = _currentTotals[key] ?? 0;
    final missedTotal = _missedTotals[key] ?? 0;

    if (currentLogged < missedTotal) {
      setState(() => _currentTotals[key] = currentLogged + 1);
    } else {
      final loc = AppLocalizations.of(context)!;
      final prayerName = _localizedPrayerName(key, loc);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.youAlreadyLoggedAll(prayerName),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _decrement(String key) => setState(() {
    if ((_currentTotals[key] ?? 0) > 0) {
      _currentTotals[key] = _currentTotals[key]! - 1;
    }
  });

  Future<void> _saveChanges() async {
    final dateKey = DateFormat('dd-MM-yyyy').format(DateTime.now());

    if (_isGuest) {
      final prefs = await SharedPreferences.getInstance();
      final logsString = prefs.getString('guestLogs');
      Map<String, dynamic> guestLogs = {};
      if (logsString != null) guestLogs = jsonDecode(logsString);

      final totalsBefore = _calculateTotals(guestLogs);
      final todayLog = Map<String, dynamic>.from(guestLogs[dateKey] ?? {
        'fajr': 0,
        'dhuhr': 0,
        'asr': 0,
        'maghrib': 0,
        'isha': 0,
      });

      for (final key in _currentTotals.keys) {
        final diff = _currentTotals[key]! - (totalsBefore[key] ?? 0);
        if (diff != 0) todayLog[key] = (todayLog[key] ?? 0) + diff;
      }

      guestLogs[dateKey] = todayLog;
      await prefs.setString('guestLogs', jsonEncode(guestLogs));
    } else {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userRef =
        FirebaseFirestore.instance.collection('Users').doc(user.uid);
        final snapshot = await userRef.get();
        final data = snapshot.data() ?? {};
        final logs = Map<String, dynamic>.from(data['logs'] ?? {});
        final totalsBefore = _calculateTotals(logs);
        final todayLog = Map<String, dynamic>.from(logs[dateKey] ?? {
          'fajr': 0,
          'dhuhr': 0,
          'asr': 0,
          'maghrib': 0,
          'isha': 0,
        });

        for (final key in _currentTotals.keys) {
          final diff = _currentTotals[key]! - (totalsBefore[key] ?? 0);
          if (diff != 0) todayLog[key] = (todayLog[key] ?? 0) + diff;
        }

        logs[dateKey] = todayLog;
        await userRef.update({'logs': logs});
      }
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc.editLogs,
          style: const TextStyle(color: Colors.black87),
        ),
      ),
      body: _currentTotals.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCard(loc),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(loc.saveChanges),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(AppLocalizations loc) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Column(
      children: [
        _counterRow(loc.fajr, 'fajr'),
        _counterRow(loc.dhuhr, 'dhuhr'),
        _counterRow(loc.asr, 'asr'),
        _counterRow(loc.maghrib, 'maghrib'),
        _counterRow(loc.isha, 'isha'),
      ],
    ),
  );

  Widget _counterRow(String label, String key) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Row(
          children: [
            _circleBtn(Icons.remove, () => _decrement(key)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                '${_currentTotals[key] ?? 0}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            _circleBtn(Icons.add, () => _increment(key)),
          ],
        ),
      ],
    ),
  );

  Widget _circleBtn(IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF1F2F4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Icon(icon, size: 20, color: const Color(0xFF2563EB)),
    ),
  );
}