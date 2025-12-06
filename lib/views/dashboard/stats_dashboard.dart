import 'package:flutter/material.dart';
import 'package:qadaa_prayer_tracker/core/app_colors.dart';
import 'package:qadaa_prayer_tracker/l10n/app_localizations.dart';
import 'package:qadaa_prayer_tracker/models/daily_totals.dart';
import 'package:qadaa_prayer_tracker/core/services/dashboard_service.dart';

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
  Map<String, int> _completedTotals = {
    'fajr': 0,
    'dhuhr': 0,
    'asr': 0,
    'maghrib': 0,
    'isha': 0,
  };
  final DashboardService _dashboardService = DashboardService();

  @override
  void initState() {
    super.initState();
    _loadCompletionTotals();
  }

  Future<void> _loadCompletionTotals() async {
    setState(() => _isGuest = false);

    try {
      final prefsTotals = await _dashboardService.loadGuestCompletionTotals();
      final userTotals = await _dashboardService.loadUserCompletionTotals();
      if (!mounted) return;

      // Detect guest based on local storage flag
      final result = await _dashboardService.loadDashboardData(widget.initial);
      if (!mounted) return;

      setState(() {
        _isGuest = result.isGuest;
        _completedTotals = _isGuest ? prefsTotals : userTotals;
      });
    } catch (e) {
      debugPrint('❌ Error loading stats totals: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final initial = widget.initial;
    final remaining = widget.remaining;
    final perDay = widget.perDay ?? {};

    int getCompleted(int total, int rem) => (total - rem).clamp(0, total);

    final fajrCompleted = _isGuest
        ? _completedTotals['fajr'] ?? 0
        : getCompleted(initial.fajr, remaining.fajr);
    final dhuhrCompleted = _isGuest
        ? _completedTotals['dhuhr'] ?? 0
        : getCompleted(initial.dhuhr, remaining.dhuhr);
    final asrCompleted = _isGuest
        ? _completedTotals['asr'] ?? 0
        : getCompleted(initial.asr, remaining.asr);
    final maghribCompleted = _isGuest
        ? _completedTotals['maghrib'] ?? 0
        : getCompleted(initial.maghrib, remaining.maghrib);
    final ishaCompleted = _isGuest
        ? _completedTotals['isha'] ?? 0
        : getCompleted(initial.isha, remaining.isha);

    final totalCompleted =
        fajrCompleted + dhuhrCompleted + asrCompleted + maghribCompleted + ishaCompleted;
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
      if (remainingCount == 0) return null; // Already finished
      final days = (remainingCount / perDayCount).ceil();
      return DateTime.now().add(Duration(days: days));
    }

    String getFinishDateString(int remainingCount, int? perDayCount) {
      if (remainingCount == 0) return loc.finished;
      final date = prayerFinishDate(remainingCount, perDayCount);
      if (date == null) return '–';
      return fmtDate(date);
    }

    final fajrFinish = getFinishDateString(remaining.fajr, perDay['fajr']);
    final dhuhrFinish = getFinishDateString(remaining.dhuhr, perDay['dhuhr']);
    final asrFinish = getFinishDateString(remaining.asr, perDay['asr']);
    final maghribFinish =
        getFinishDateString(remaining.maghrib, perDay['maghrib']);
    final ishaFinish = getFinishDateString(remaining.isha, perDay['isha']);

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.statistics,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              loc.totalProgress,
              style: const TextStyle(color: AppColors.text),
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
                  iconColor: AppColors.secondary,
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
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _breakdownRow(
                    context,
                    icon: Icons.nights_stay_outlined,
                    label: loc.fajr,
                    count: '$fajrCompleted/${initial.fajr}',
                    percent: percentStr(fajrCompleted, initial.fajr),
                    finishDate: fajrFinish,
                    isFinished: remaining.fajr == 0,
                  ),
                  _breakdownRow(
                    context,
                    icon: Icons.wb_sunny_outlined,
                    label: loc.dhuhr,
                    count: '$dhuhrCompleted/${initial.dhuhr}',
                    percent: percentStr(dhuhrCompleted, initial.dhuhr),
                    finishDate: dhuhrFinish,
                    isFinished: remaining.dhuhr == 0,
                  ),
                  _breakdownRow(
                    context,
                    icon: Icons.wb_twilight_outlined,
                    label: loc.asr,
                    count: '$asrCompleted/${initial.asr}',
                    percent: percentStr(asrCompleted, initial.asr),
                    finishDate: asrFinish,
                    isFinished: remaining.asr == 0,
                  ),
                  _breakdownRow(
                    context,
                    icon: Icons.brightness_3_outlined,
                    label: loc.maghrib,
                    count: '$maghribCompleted/${initial.maghrib}',
                    percent: percentStr(maghribCompleted, initial.maghrib),
                    finishDate: maghribFinish,
                    isFinished: remaining.maghrib == 0,
                  ),
                  _breakdownRow(
                    context,
                    icon: Icons.star_border,
                    label: loc.isha,
                    count: '$ishaCompleted/${initial.isha}',
                    percent: percentStr(ishaCompleted, initial.isha),
                    finishDate: ishaFinish,
                    isFinished: remaining.isha == 0,
                  ),
                ],
              ),
            ),
          ],
        ),
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
        Color iconColor = AppColors.primary,
      }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                Icon(icon, color: iconColor),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: AppColors.text),
            ),
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
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: AppColors.secondary.withValues(alpha: 0.3),
      ),
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
        required bool isFinished,
      }) {
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isFinished ? finishDate : '${loc.finish}: $finishDate',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Text(
            count,
            style: const TextStyle(color: AppColors.text),
          ),
          const SizedBox(width: 12),
          Text(
            percent,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

}
