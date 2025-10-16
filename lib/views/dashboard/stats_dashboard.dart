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
        _guestLogs = jsonDecode(logsString);
      }
      setState(() {});
    }
  }

  int _guestCompleted(String key) {
    int total = 0;
    for (var entry in _guestLogs.values) {
      final day = Map<String, int>.from(entry);
      total += (day[key] ?? 0);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // -------------------
    // DATA CALCULATIONS
    // -------------------
    final initial = widget.initial;
    final remaining = widget.remaining;

    // For guests, calculate completed counts from logs
    final fajrCompleted = _isGuest
        ? _guestCompleted('fajr')
        : (initial.fajr - remaining.fajr).clamp(0, initial.fajr);
    final dhuhrCompleted = _isGuest
        ? _guestCompleted('dhuhr')
        : (initial.dhuhr - remaining.dhuhr).clamp(0, initial.dhuhr);
    final asrCompleted = _isGuest
        ? _guestCompleted('asr')
        : (initial.asr - remaining.asr).clamp(0, initial.asr);
    final maghribCompleted = _isGuest
        ? _guestCompleted('maghrib')
        : (initial.maghrib - remaining.maghrib).clamp(0, initial.maghrib);
    final ishaCompleted = _isGuest
        ? _guestCompleted('isha')
        : (initial.isha - remaining.isha).clamp(0, initial.isha);

    final totalCompleted = fajrCompleted +
        dhuhrCompleted +
        asrCompleted +
        maghribCompleted +
        ishaCompleted;
    final totalRemaining = remaining.sum;

    final perDayTotals = widget.perDay ?? const {};
    final perDaySum = (perDayTotals['fajr'] ?? 0) +
        (perDayTotals['dhuhr'] ?? 0) +
        (perDayTotals['asr'] ?? 0) +
        (perDayTotals['maghrib'] ?? 0) +
        (perDayTotals['isha'] ?? 0);

    final daysRemaining =
    perDaySum > 0 ? (totalRemaining / perDaySum).ceil() : null;
    final estimatedFinishDate = daysRemaining != null
        ? DateTime.now().add(Duration(days: daysRemaining))
        : null;

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

    // -------------------
    // MAIN UI
    // -------------------
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.statistics,
              style:
              const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(loc.totalProgress,
                style: const TextStyle(color: Colors.black54)),
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

            _gradientInfoCard(
              title: loc.estimatedFinishDate,
              value: estimatedFinishDate != null
                  ? fmtDate(estimatedFinishDate)
                  : loc.noDailyPlan,
              subtitle: perDaySum > 0
                  ? loc.atCurrentPace
                  : loc.setDailyPlanToEstimate,
            ),
            const SizedBox(height: 20),

            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.prayerBreakdown,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  _breakdownRow(
                    context,
                    icon: Icons.nights_stay_outlined,
                    label: loc.fajr,
                    count: '$fajrCompleted/${initial.fajr}',
                    percent: percentStr(fajrCompleted, initial.fajr),
                  ),
                  _breakdownRow(
                    context,
                    icon: Icons.wb_sunny_outlined,
                    label: loc.dhuhr,
                    count: '$dhuhrCompleted/${initial.dhuhr}',
                    percent: percentStr(dhuhrCompleted, initial.dhuhr),
                  ),
                  _breakdownRow(
                    context,
                    icon: Icons.wb_twilight_outlined,
                    label: loc.asr,
                    count: '$asrCompleted/${initial.asr}',
                    percent: percentStr(asrCompleted, initial.asr),
                  ),
                  _breakdownRow(
                    context,
                    icon: Icons.brightness_3_outlined,
                    label: loc.maghrib,
                    count: '$maghribCompleted/${initial.maghrib}',
                    percent: percentStr(maghribCompleted, initial.maghrib),
                  ),
                  _breakdownRow(
                    context,
                    icon: Icons.star_border,
                    label: loc.isha,
                    count: '$ishaCompleted/${initial.isha}',
                    percent: percentStr(ishaCompleted, initial.isha),
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

  Widget _gradientInfoCard({
    required String title,
    required String value,
    required String subtitle,
  }) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEFF5FF), Color(0xFFFFFFFF)],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_today_rounded,
                  color: Color(0xFF2563EB), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: Colors.black87)),
                  const SizedBox(height: 6),
                  Text(value,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Color(0xFF2563EB))),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _breakdownRow(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String count,
        required String percent,
      }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2563EB)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16)),
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
