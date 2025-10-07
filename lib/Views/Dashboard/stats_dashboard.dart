import 'package:flutter/material.dart';
import 'package:qadaa_prayer_tracker/models/daily_totals.dart';

class StatsDashboard extends StatelessWidget {
  final DailyTotals initial;
  final DailyTotals remaining;
  final Map<String, int>? perDay;

  const StatsDashboard({super.key, required this.initial, required this.remaining, this.perDay});

  @override
  Widget build(BuildContext context) {
    final fajrCompleted = (initial.fajr - remaining.fajr).clamp(0, initial.fajr);
    final dhuhrCompleted = (initial.dhuhr - remaining.dhuhr).clamp(0, initial.dhuhr);
    final asrCompleted = (initial.asr - remaining.asr).clamp(0, initial.asr);
    final maghribCompleted = (initial.maghrib - remaining.maghrib).clamp(0, initial.maghrib);
    final ishaCompleted = (initial.isha - remaining.isha).clamp(0, initial.isha);

    final totalCompleted = fajrCompleted + dhuhrCompleted + asrCompleted + maghribCompleted + ishaCompleted;
    final totalRemaining = remaining.sum;

    final perDayTotals = perDay ?? const {};
    final perDaySum = (perDayTotals['fajr'] ?? 0) +
        (perDayTotals['dhuhr'] ?? 0) +
        (perDayTotals['asr'] ?? 0) +
        (perDayTotals['maghrib'] ?? 0) +
        (perDayTotals['isha'] ?? 0);

    final daysRemaining = perDaySum > 0 ? (totalRemaining / perDaySum).ceil() : null;
    final estimatedFinishDate = daysRemaining != null ? DateTime.now().add(Duration(days: daysRemaining)) : null;

    final now = DateTime.now();
    final weekdayIndexFromMonday = (now.weekday + 6) % 7 + 1; // Mon=1..Sun=7
    final expectedSoFarThisWeek = perDaySum * weekdayIndexFromMonday;
    final completedThisWeek = perDaySum == 0 ? 0 : totalCompleted.clamp(0, expectedSoFarThisWeek);
    final currentStreak = totalCompleted > 0 ? 1 : 0;

    String percentStr(int completed, int total) {
      if (total <= 0) return '0%';
      final pct = (completed / total * 100).clamp(0, 100).toStringAsFixed(0);
      return '$pct%';
    }

    String fmtDate(DateTime d) {
      const months = [
        'January','February','March','April','May','June','July','August','September','October','November','December'
      ];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Statistics',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Total Progress',
                style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 20),

            Row(
              children: [
                _kpiCard(
                  context,
                  value: '$currentStreak',
                  label: 'Current Streak',
                  icon: Icons.trending_up,
                ),
                const SizedBox(width: 16),
                _kpiCard(
                  context,
                  value: '$completedThisWeek',
                  label: 'Completed this week',
                  icon: Icons.adjust_rounded,
                  iconColor: const Color(0xFF16A34A),
                ),
              ],
            ),

            const SizedBox(height: 20),

            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Weekly Progress',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 120),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Thu', style: TextStyle(color: Colors.black54)),
                      Text('Fri', style: TextStyle(color: Colors.black54)),
                      Text('Sat', style: TextStyle(color: Colors.black54)),
                      Text('Sun', style: TextStyle(color: Colors.black54)),
                      Text('Mon', style: TextStyle(color: Colors.black54)),
                      Text('Tue', style: TextStyle(color: Colors.black54)),
                      Text('Wed', style: TextStyle(color: Colors.black54)),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            _gradientInfoCard(
              title: 'Estimated Finish Date',
              value: estimatedFinishDate != null ? fmtDate(estimatedFinishDate) : 'No daily plan',
              subtitle: perDaySum > 0 ? 'At your current pace' : 'Set a daily plan to estimate finish date',
            ),

            const SizedBox(height: 20),

            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Prayer Breakdown',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  _breakdownRow(
                    context,
                    icon: Icons.nights_stay_outlined,
                    label: 'Fajr',
                    count: '${fajrCompleted}/${initial.fajr}',
                    percent: percentStr(fajrCompleted, initial.fajr)
                  ),
                  _breakdownRow(
                    context,
                    icon: Icons.wb_sunny_outlined,
                    label: 'Dhuhr',
                    count: '${dhuhrCompleted}/${initial.dhuhr}',
                    percent: percentStr(dhuhrCompleted, initial.dhuhr)
                  ),
                  _breakdownRow(
                    context,
                    icon: Icons.wb_twilight_outlined,
                    label: 'Asr',
                    count: '${asrCompleted}/${initial.asr}',
                    percent: percentStr(asrCompleted, initial.asr)
                  ),
                  _breakdownRow(
                    context,
                    icon: Icons.brightness_3_outlined,
                    label: 'Maghrib',
                    count: '${maghribCompleted}/${initial.maghrib}',
                    percent: percentStr(maghribCompleted, initial.maghrib)
                  ),
                  _breakdownRow(
                    context,
                    icon: Icons.star_border,
                    label: 'Isha',
                    count: '${ishaCompleted}/${initial.isha}',
                    percent: percentStr(ishaCompleted, initial.isha)
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(BuildContext context,
      {required String value,
      required String label,
      required IconData icon,
      Color iconColor = const Color(0xFF2563EB)}) {
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

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: child,
    );
  }

  Widget _gradientInfoCard({
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
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
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(BuildContext context,
      {required IconData icon,
      required String label,
      required String count,
      required String percent}) {
    return Padding(
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
                  color: Color(0xFF2563EB), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}


