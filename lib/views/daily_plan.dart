import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qadaa_prayer_tracker/core/app_colors.dart';
import 'package:qadaa_prayer_tracker/l10n/app_localizations.dart';
import 'package:qadaa_prayer_tracker/models/daily_totals.dart';
import 'Dashboard/home_dashboard.dart';
import 'package:qadaa_prayer_tracker/core/services/dashboard_service.dart';

class DailyPlan extends StatefulWidget {
  final DailyTotals totals;
  final Map<String, int>? perDay;
  final bool fromSettings;

  const DailyPlan({
    super.key,
    required this.totals,
    this.perDay,
    this.fromSettings = false,
  });

  @override
  State<DailyPlan> createState() => _DailyPlanState();
}

class _DailyPlanState extends State<DailyPlan> {
  final _digitsOnly = [FilteringTextInputFormatter.digitsOnly];

  final _fajrPerDay = TextEditingController();
  final _dhuhrPerDay = TextEditingController();
  final _asrPerDay = TextEditingController();
  final _maghribPerDay = TextEditingController();
  final _ishaPerDay = TextEditingController();
  final DashboardService _dashboardService = DashboardService();

  @override
  void initState() {
    super.initState();
    _fajrPerDay.text = widget.perDay?['fajr']?.toString() ?? '';
    _dhuhrPerDay.text = widget.perDay?['dhuhr']?.toString() ?? '';
    _asrPerDay.text = widget.perDay?['asr']?.toString() ?? '';
    _maghribPerDay.text = widget.perDay?['maghrib']?.toString() ?? '';
    _ishaPerDay.text = widget.perDay?['isha']?.toString() ?? '';
  }

  @override
  void dispose() {
    for (final c in [
      _fajrPerDay,
      _dhuhrPerDay,
      _asrPerDay,
      _maghribPerDay,
      _ishaPerDay
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  int _int(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  /// 🕌 Get localized name for each prayer
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

  Future<void> _saveAndGo() async {
    final loc = AppLocalizations.of(context)!;

    final perDay = {
      'fajr': _int(_fajrPerDay),
      'dhuhr': _int(_dhuhrPerDay),
      'asr': _int(_asrPerDay),
      'maghrib': _int(_maghribPerDay),
      'isha': _int(_ishaPerDay),
    };

    // 🔹 Validation
    final isAllZero = perDay.values.every((v) => v == 0);
    if (isAllZero) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppColors.styledSnackBar(loc.pleaseEnterValidPeriod),
      );
      return;
    }

    // 🔹 Check if within allowed limits
    final remaining = {
      'fajr': widget.totals.fajr,
      'dhuhr': widget.totals.dhuhr,
      'asr': widget.totals.asr,
      'maghrib': widget.totals.maghrib,
      'isha': widget.totals.isha,
    };

    for (final entry in perDay.entries) {
      final key = entry.key;
      final value = entry.value;
      final maxAllowed = remaining[key] ?? 0;

      if (value > maxAllowed) {
        final prayerName = _localizedPrayerName(key, loc);
        ScaffoldMessenger.of(context).showSnackBar(
          AppColors.styledSnackBar(
            loc.validationCantExceed(
              prayerName,
              maxAllowed.toString(),
            ),
          ),
        );
        return;
      }
    }

    // 🔹 Determine mode (guest or user)
    final useGuestFlow = await _dashboardService.useGuestFlow();
    await _dashboardService.saveDailyPlan(perDay, isGuest: useGuestFlow);

    if (widget.fromSettings) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppColors.styledSnackBar(loc.dailyPlanUpdated),
        );
        Navigator.pop(context, perDay);
      }
    } else {
      if (!mounted) return;
      final route = MaterialPageRoute(
        builder: (_) => HomeDashboard(
          initial: widget.totals,
          perDay: perDay,
        ),
      );
      Navigator.pushReplacement(context, route);
    }
  }

  Widget _rowField(String label, int remaining, TextEditingController c) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.text,
                ),
              ),
              const Spacer(),
              Text(
                '$remaining ${loc.remaining}',
                style: const TextStyle(color: AppColors.text),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: c,
            keyboardType: TextInputType.number,
            inputFormatters: _digitsOnly,
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(
                color: AppColors.text.withValues(alpha: 0.5),
                fontSize: 13,
              ),
              filled: true,
              fillColor: AppColors.accent.withValues(alpha: 0.1),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final t = widget.totals;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back button and title - same level
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.text),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Expanded(
                        child: Text(
                          loc.setYourDailyPlan,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the back button width
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.howManyQadaa,
                    style: const TextStyle(color: AppColors.text),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _rowField(loc.fajr, t.fajr, _fajrPerDay),
                  _rowField(loc.dhuhr, t.dhuhr, _dhuhrPerDay),
                  _rowField(loc.asr, t.asr, _asrPerDay),
                  _rowField(loc.maghrib, t.maghrib, _maghribPerDay),
                  _rowField(loc.isha, t.isha, _ishaPerDay),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveAndGo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      loc.savePlan,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
