import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qadaa_prayer_tracker/l10n/app_localizations.dart';
import 'package:qadaa_prayer_tracker/models/daily_totals.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatsDashboard extends StatefulWidget {
  final DailyTotals initial;
  final DailyTotals remaining;
  final Map<String, int>? perDay;

  const StatsDashboard({
    super.key,
    required this.initial,
    required this.remaining,
    this.perDay,
  });

  @override
  State<StatsDashboard> createState() => _StatsDashboardState();
}

class _StatsDashboardState extends State<StatsDashboard> {
  bool _isGuest = false;
  Map<String, dynamic> _guestLogs = {};

  @override
  void initState() {
    super.initState();
    _loadGuestLogsIfNeeded();
  }

  Future<void> _loadGuestLogsIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    _isGuest = prefs.getBool('isGuest') ?? false;

    if (_isGuest) {
      final logsString = prefs.getString('guestLogs');
      if (logsString != null) {
        final decoded = jsonDecode(logsString);

        if (decoded is Map) {
          _guestLogs = Map<String, dynamic>.from(decoded);
        } else {
          // Handle corrupted or old data safely
          _guestLogs = {
            'fajr': 0,
            'dhuhr': 0,
            'asr': 0,
            'maghrib': 0,
            'isha': 0,
          };
        }
      }
      setState(() {});
    }
  }


  int _guestCompleted(String key) {
    if (_guestLogs.isEmpty) return 0;

    int total = 0;

    // ✅ Case 1: new nested format (daily entries)
    if (_guestLogs.values.isNotEmpty && _guestLogs.values.first is Map) {
      for (var entry in _guestLogs.values) {
        final day = Map<String, int>.from(entry);
        total += (day[key] ?? 0);
      }
      return total;
    }

    // ✅ Case 2: old flat format { "fajr": 10, "dhuhr": 5, ... }
    if (_guestLogs.containsKey(key)) {
      return _guestLogs[key] ?? 0;
    }

    return 0;
  }


  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final initial = widget.initial;
    final remaining = widget.remaining;
    final perDay = widget.perDay ?? {};

    int getCompleted(int total, int rem) => (total - rem).clamp(0, total);

    final fajrCompleted = _isGuest ? _guestCompleted('fajr') : getCompleted(initial.fajr, remaining.fajr);
    final dhuhrCompleted = _isGuest ? _guestCompleted('dhuhr') : getCompleted(initial.dhuhr, remaining.dhuhr);
    final asrCompleted = _isGuest ? _guestCompleted('asr') : getCompleted(initial.asr, remaining.asr);
    final maghribCompleted = _isGuest ? _guestCompleted('maghrib') : getCompleted(initial.maghrib, remaining.maghrib);
    final ishaCompleted = _isGuest ? _guestCompleted('isha') : getCompleted(initial.isha, remaining.isha);

    final totalCompleted = fajrCompleted + dhuhrCompleted + asrCompleted + maghribCompleted + ishaCompleted;
    final totalRemaining = remaining.sum;

    String percentStr(int completed, int total) {
      if (total <= 0) return '0%';
      final pct = (completed / total * 100).clamp(0, 100).toStringAsFixed(0);
      return '$pct%';
    }

    String fmtDate(DateTime d) {
      final months = [
        loc.january,
        loc.february,
        loc.march,
        loc.april,
        loc.may,
        loc.june,
        loc.july,
        loc.august,
        loc.september,
        loc.october,
        loc.november,
        loc.december
      ];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    }

    DateTime? prayerFinishDate(int remainingCount, int? perDayCount) {
      if (perDayCount == null || perDayCount == 0) return null;
      final days = (remainingCount / perDayCount).ceil();
      return DateTime.now().add(Duration(days: days));
    }

    final fajrFinish = prayerFinishDate(remaining.fajr, perDay['fajr']);
    final dhuhrFinish = prayerFinishDate(remaining.dhuhr, perDay['dhuhr']);
    final asrFinish = prayerFinishDate(remaining.asr, perDay['asr']);
    final maghribFinish = prayerFinishDate(remaining.maghrib, perDay['maghrib']);
    final ishaFinish = prayerFinishDate(remaining.isha, perDay['isha']);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.statistics,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              loc.totalProgress,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                _kpiCard(
                  context,
                  value: '$totalCompleted',
                  label: loc.totalCompleted,
                  icon: Icons.trending_up,
                ),
                const SizedBox(width: 16),
                _kpiCard(
                  context,
                  value: '$totalRemaining',
                  label: loc.remainingPrayers,
                  icon: Icons.access_time,
                  iconColor: const Color(0xFF2563EB),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Removed estimated finish date section here

            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.prayerBreakdown,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _breakdownRow(
                    context,
                    icon: Icons.nights_stay_outlined,
                    label: loc.fajr,
                    count: '$fajrCompleted/${initial.fajr}',
                    percent: percentStr(fajrCompleted, initial.fajr),
                    finishDate: fajrFinish != null ? fmtDate(fajrFinish) : '–',
                  ),
                  _breakdownRow(
                    context,
                    icon: Icons.wb_sunny_outlined,
                    label: loc.dhuhr,
                    count: '$dhuhrCompleted/${initial.dhuhr}',
                    percent: percentStr(dhuhrCompleted, initial.dhuhr),
                    finishDate: dhuhrFinish != null ? fmtDate(dhuhrFinish) : '–',
                  ),
                  _breakdownRow(
                    context,
                    icon: Icons.wb_twilight_outlined,
                    label: loc.asr,
                    count: '$asrCompleted/${initial.asr}',
                    percent: percentStr(asrCompleted, initial.asr),
                    finishDate: asrFinish != null ? fmtDate(asrFinish) : '–',
                  ),
                  _breakdownRow(
                    context,
                    icon: Icons.brightness_3_outlined,
                    label: loc.maghrib,
                    count: '$maghribCompleted/${initial.maghrib}',
                    percent: percentStr(maghribCompleted, initial.maghrib),
                    finishDate: maghribFinish != null ? fmtDate(maghribFinish) : '–',
                  ),
                  _breakdownRow(
                    context,
                    icon: Icons.star_border,
                    label: loc.isha,
                    count: '$ishaCompleted/${initial.isha}',
                    percent: percentStr(ishaCompleted, initial.isha),
                    finishDate: ishaFinish != null ? fmtDate(ishaFinish) : '–',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------
  // UI COMPONENTS
  // -------------------

  Widget _kpiCard(
      BuildContext context, {
        required String value,
        required String label,
        required IconData icon,
        Color iconColor = const Color(0xFF2563EB),
      }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w800)),
                Icon(icon, color: iconColor),
              ],
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: child,
  );

  Widget _breakdownRow(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String count,
        required String percent,
        required String finishDate,
      }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2563EB)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    'Finish: $finishDate',
                    style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 13,
                        fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
            Text(count, style: const TextStyle(color: Colors.black54)),
            const SizedBox(width: 12),
            Text(percent,
                style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );
}