import 'package:flutter/material.dart';
import 'package:qadaa_prayer_tracker/l10n/app_localizations.dart';
import 'package:qadaa_prayer_tracker/Views/Dashboard/settings_dashboard.dart';
import 'package:qadaa_prayer_tracker/Views/Dashboard/stats_dashboard.dart';
import 'package:qadaa_prayer_tracker/models/daily_totals.dart';
import 'package:qadaa_prayer_tracker/core/services/dashboard_service.dart';

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

class _HomeDashboardState extends State<HomeDashboard>
    with SingleTickerProviderStateMixin {
  int _tabIndex = 0;
  late DailyTotals _initial;
  late DailyTotals _remaining;
  int _totalCompleted = 0;
  bool _isLoading = true;
  bool _isGuest = false;
  Map<String, dynamic> _guestLogs = {};
  final DashboardService _dashboardService = DashboardService();

  @override
  void initState() {
    super.initState();
    _initial = widget.initial;
    _remaining = widget.initial;
    _loadDashboardData();
  }

  // ✅ Reload data from storage when called from settings
  void _reloadData() async {
    await _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final result = await _dashboardService.loadDashboardData(widget.initial);
      if (!mounted) return;
      setState(() {
        _initial = result.initial;
        _remaining = result.remaining;
        _totalCompleted = result.totalCompleted;
        _isGuest = result.isGuest;
        _guestLogs = result.guestLogs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading dashboard data: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  int get _totalInitial => _initial.sum;
  int get _totalRemaining => _remaining.sum;
  double get _progress =>
      _totalInitial == 0 ? 0 : _totalCompleted / _totalInitial;

  // ---------------- LOGIC ----------------
  void _logOne(String prayerKey) async {
    final loc = AppLocalizations.of(context)!;
    bool logged = false;

    setState(() {
      switch (prayerKey) {
        case 'fajr':
          if (_remaining.fajr > 0) {
            _remaining = _remaining.copyWith(fajr: _remaining.fajr - 1);
            _totalCompleted++;
            logged = true;
          }
          break;
        case 'dhuhr':
          if (_remaining.dhuhr > 0) {
            _remaining = _remaining.copyWith(dhuhr: _remaining.dhuhr - 1);
            _totalCompleted++;
            logged = true;
          }
          break;
        case 'asr':
          if (_remaining.asr > 0) {
            _remaining = _remaining.copyWith(asr: _remaining.asr - 1);
            _totalCompleted++;
            logged = true;
          }
          break;
        case 'maghrib':
          if (_remaining.maghrib > 0) {
            _remaining = _remaining.copyWith(maghrib: _remaining.maghrib - 1);
            _totalCompleted++;
            logged = true;
          }
          break;
        case 'isha':
          if (_remaining.isha > 0) {
            _remaining = _remaining.copyWith(isha: _remaining.isha - 1);
            _totalCompleted++;
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

    if (logged) {
      try {
        if (_isGuest) {
          final updatedLogs =
              await _dashboardService.logGuestPrayer(prayerKey, _guestLogs);
          if (!mounted) return;
          setState(() => _guestLogs = updatedLogs);
        } else {
          await _dashboardService.logUserPrayer(prayerKey);
        }
      } catch (e) {
        debugPrint('❌ Error persisting prayer log: $e');
      }
    }
  }

  void _showCenteredNotice({required String title, required String subtitle}) {
    final loc = AppLocalizations.of(context)!;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: loc.barrierDismiss,
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, _, __) {
        Future.delayed(const Duration(milliseconds: 750), () {
          if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
        });
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: Colors.black)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------- UI ----------------
  Widget _homePage() {
    final loc = AppLocalizations.of(context)!;
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final percentText = '${(_progress * 100).floor()}%';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          children: [
            Text(loc.qadaaTracker,
                style:
                const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(loc.totalProgress,
                style: const TextStyle(color: Colors.black54)),
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
                      Text(percentText,
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w800)),
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
                Expanded(child: _statCard(loc.totalMissed, '$_totalInitial')),
                const SizedBox(width: 10),
                Expanded(
                    child: _statCard(loc.totalCompleted, '$_totalCompleted',
                        valueColor: Colors.green)),
                const SizedBox(width: 10),
                Expanded(
                    child: _statCard(loc.remainingPrayers, '$_totalRemaining',
                        valueColor: const Color(0xFF2563EB))),
              ],
            ),
            const SizedBox(height: 20),
            _breakdownContainer(loc),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, {Color? valueColor}) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: valueColor ?? Colors.black)),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(color: Colors.black54)),
      ],
    ),
  );

  Widget _breakdownContainer(AppLocalizations loc) => Container(
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
        Text(loc.prayerBreakdown,
            style:
            const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        _breakdownRow(Icons.nights_stay_outlined, loc.fajr, _initial.fajr,
            _remaining.fajr, 'fajr'),
        _breakdownRow(Icons.wb_sunny_outlined, loc.dhuhr, _initial.dhuhr,
            _remaining.dhuhr, 'dhuhr'),
        _breakdownRow(Icons.wb_twilight_outlined, loc.asr, _initial.asr,
            _remaining.asr, 'asr'),
        _breakdownRow(Icons.brightness_3_outlined, loc.maghrib,
            _initial.maghrib, _remaining.maghrib, 'maghrib'),
        _breakdownRow(Icons.star_border, loc.isha, _initial.isha,
            _remaining.isha, 'isha'),
      ],
    ),
  );

  Widget _breakdownRow(
      IconData icon, String label, int initial, int remaining, String key) {
    final completed = (initial - remaining).clamp(0, initial);
    final pct = initial == 0 ? 0.0 : completed / initial;

    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () => _logOne(key),
        borderRadius: BorderRadius.circular(12),
        splashColor: const Color(0xFF2563EB).withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6E8EC)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF2563EB)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ),
                  Text(
                    '$completed/$initial',
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 10),
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
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsPage() => StatsDashboard(
      key: ValueKey(_totalCompleted),
      initial: _initial,
      remaining: _remaining,
      perDay: widget.perDay);

  Widget _settingsPage() => SettingsDashboard(
    initial: _initial,
    remaining: _remaining,
    perDay: widget.perDay,
    onDataChanged: _reloadData,
  );

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
