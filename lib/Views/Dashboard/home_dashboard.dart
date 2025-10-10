import 'package:flutter/material.dart';
import 'package:qadaa_prayer_tracker/l10n/app_localizations.dart';
import 'package:qadaa_prayer_tracker/Views/Dashboard/settings_dashboard.dart';
import 'package:qadaa_prayer_tracker/Views/Dashboard/stats_dashboard.dart';
import 'package:qadaa_prayer_tracker/models/daily_totals.dart';

class HomeDashboard extends StatefulWidget {
  final DailyTotals initial;
  final Map<String, int>? perDay;

  const HomeDashboard({
    super.key,
    required this.initial,
    this.perDay,
  });

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  int _tabIndex = 0;
  late DailyTotals _initial;
  late DailyTotals _remaining;
  int _totalCompleted = 0;

  @override
  void initState() {
    super.initState();
    _initial = widget.initial;
    _remaining = widget.initial;
    _totalCompleted = 0;
  }

  int get _totalInitial => _initial.sum;
  int get _totalRemaining => _remaining.sum;
  double get _progress =>
      _totalInitial == 0 ? 0 : _totalCompleted / _totalInitial;

  // -------------------
  // LOGIC FUNCTIONS
  // -------------------

  void _logOne(String prayerKey) {
    final loc = AppLocalizations.of(context)!;
    bool logged = false;

    setState(() {
      switch (prayerKey) {
        case 'fajr':
          if (_remaining.fajr > 0) {
            _remaining = _remaining.copyWith(fajr: _remaining.fajr - 1);
            _totalCompleted += 1;
            logged = true;
          }
          break;
        case 'dhuhr':
          if (_remaining.dhuhr > 0) {
            _remaining = _remaining.copyWith(dhuhr: _remaining.dhuhr - 1);
            _totalCompleted += 1;
            logged = true;
          }
          break;
        case 'asr':
          if (_remaining.asr > 0) {
            _remaining = _remaining.copyWith(asr: _remaining.asr - 1);
            _totalCompleted += 1;
            logged = true;
          }
          break;
        case 'maghrib':
          if (_remaining.maghrib > 0) {
            _remaining = _remaining.copyWith(maghrib: _remaining.maghrib - 1);
            _totalCompleted += 1;
            logged = true;
          }
          break;
        case 'isha':
          if (_remaining.isha > 0) {
            _remaining = _remaining.copyWith(isha: _remaining.isha - 1);
            _totalCompleted += 1;
            logged = true;
          }
          break;
      }
    });

    final prayerNames = {
      'fajr': loc.fajr,
      'dhuhr': loc.dhuhr,
      'asr': loc.asr,
      'maghrib': loc.maghrib,
      'isha': loc.isha,
    };

    final label = prayerNames[prayerKey] ?? prayerKey;
    final title = logged ? loc.prayerLogged : loc.nothingToLog;
    final subtitle =
    logged ? loc.prayerCompleted(label) : loc.noPrayerRemaining(label);

    _showCenteredNotice(title: title, subtitle: subtitle);
  }

  void _showCenteredNotice({
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final loc = AppLocalizations.of(context)!;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: loc.barrierDismiss,
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
        });

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(color: Colors.black54)),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(ctx).maybePop();
                          onAction();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                        ),
                        child: Text(actionLabel),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim, secondary, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void _openLogDialog() {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.logQadaaPrayer,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              loc.whichPrayer,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _logTile(ctx,
                      icon: Icons.nights_stay_outlined,
                      label: loc.fajr,
                      remaining: _remaining.fajr,
                      keyName: 'fajr'),
                  _logTile(ctx,
                      icon: Icons.wb_sunny_outlined,
                      label: loc.dhuhr,
                      remaining: _remaining.dhuhr,
                      keyName: 'dhuhr'),
                  _logTile(ctx,
                      icon: Icons.wb_twilight_outlined,
                      label: loc.asr,
                      remaining: _remaining.asr,
                      keyName: 'asr'),
                  _logTile(ctx,
                      icon: Icons.brightness_3_outlined,
                      label: loc.maghrib,
                      remaining: _remaining.maghrib,
                      keyName: 'maghrib'),
                  _logTile(ctx,
                      icon: Icons.star_border,
                      label: loc.isha,
                      remaining: _remaining.isha,
                      keyName: 'isha'),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _logTile(
      BuildContext ctx, {
        required IconData icon,
        required String label,
        required int remaining,
        required String keyName,
      }) {
    final loc = AppLocalizations.of(ctx)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () {
          Navigator.pop(ctx);
          _logOne(keyName);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6E8EC)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF2563EB)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                '$remaining ${loc.remaining}',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------
  // HOME UI
  // -------------------

  Widget _statCard(String title, String value, {Color? valueColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: valueColor ?? Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _breakdownRow({
    required IconData icon,
    required String label,
    required int initial,
    required int remaining,
  }) {
    final loc = AppLocalizations.of(context)!;
    final completed = (initial - remaining).clamp(0, initial);
    final pct = initial == 0 ? 0.0 : completed / initial;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Text('$completed/$initial'),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F2F4),
              color: const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$remaining ${loc.remaining}',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _homePage() {
    final loc = AppLocalizations.of(context)!;
    final percentText = '${(_progress * 100).toStringAsFixed(0)}%';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          children: [
            Text(
              loc.qadaaTracker,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(loc.totalProgress, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 24),
            SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 14,
                      backgroundColor: const Color(0xFFF1F2F4),
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        percentText,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(loc.complete,
                          style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _statCard(loc.totalMissed, '$_totalInitial'),
                const SizedBox(width: 10),
                _statCard(loc.totalCompleted, '$_totalCompleted',
                    valueColor: Colors.green),
                const SizedBox(width: 10),
                _statCard(loc.remainingPrayers, '$_totalRemaining',
                    valueColor: const Color(0xFF2563EB)),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.prayerBreakdown,
                    style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  _breakdownRow(
                      icon: Icons.nights_stay_outlined,
                      label: loc.fajr,
                      initial: _initial.fajr,
                      remaining: _remaining.fajr),
                  _breakdownRow(
                      icon: Icons.wb_sunny_outlined,
                      label: loc.dhuhr,
                      initial: _initial.dhuhr,
                      remaining: _remaining.dhuhr),
                  _breakdownRow(
                      icon: Icons.wb_twilight_outlined,
                      label: loc.asr,
                      initial: _initial.asr,
                      remaining: _remaining.asr),
                  _breakdownRow(
                      icon: Icons.brightness_3_outlined,
                      label: loc.maghrib,
                      initial: _initial.maghrib,
                      remaining: _remaining.maghrib),
                  _breakdownRow(
                      icon: Icons.star_border,
                      label: loc.isha,
                      initial: _initial.isha,
                      remaining: _remaining.isha),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _openLogDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '+ ${loc.logQadaaPrayer}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------
  // OTHER PAGES
  // -------------------

  Widget _statsPage() => StatsDashboard(
    initial: _initial,
    remaining: _remaining,
    perDay: widget.perDay,
  );

  Widget _settingsPage() => SettingsDashboard(
    initial: _initial,
    remaining: _remaining,
    perDay: widget.perDay,
  );

  // -------------------
  // MAIN BUILD
  // -------------------

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _homePage(),
          _statsPage(),
          _settingsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: Colors.black54,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined), label: loc.home),
          BottomNavigationBarItem(
              icon: const Icon(Icons.bar_chart_rounded), label: loc.stats),
          BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined), label: loc.settings),
        ],
      ),
    );
  }
}
