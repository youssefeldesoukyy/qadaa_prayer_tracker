import 'package:flutter/material.dart';
import 'package:qadaa_prayer_tracker/l10n/app_localizations.dart';
import 'package:qadaa_prayer_tracker/main.dart';
import 'package:qadaa_prayer_tracker/models/daily_totals.dart';
import 'package:qadaa_prayer_tracker/Views/daily_plan.dart';
import 'package:qadaa_prayer_tracker/Views/qadaa_missed.dart';

class SettingsDashboard extends StatefulWidget {
  final DailyTotals initial;
  final DailyTotals remaining;
  final Map<String, int>? perDay;

  const SettingsDashboard({
    super.key,
    required this.initial,
    required this.remaining,
    this.perDay,
  });

  @override
  State<SettingsDashboard> createState() => _SettingsDashboardState();
}

class _SettingsDashboardState extends State<SettingsDashboard> {
  String _selectedLanguage = 'English';

  int get _totalCompleted => widget.initial.sum - widget.remaining.sum;
  int get _totalRemaining => widget.remaining.sum;

  // -------------------
  // ACTIONS
  // -------------------

  void _editDailyPlan() async {
    final updatedPlan = await Navigator.push<Map<String, int>>(
      context,
      MaterialPageRoute(
        builder: (_) => DailyPlan(
          totals: widget.initial,
          perDay: widget.perDay,
          fromSettings: true,
        ),
      ),
    );

    if (updatedPlan != null) {
      setState(() {
        widget.perDay?.addAll(updatedPlan);
      });
    }
  }

  void _resetAllData() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.resetTitle),
        content: Text(loc.resetWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const QadaaMissed()),
                    (route) => false,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.allDataReset)),
              );
            },
            child: Text(loc.confirmReset),
          ),
        ],
      ),
    );
  }

  // -------------------
  // MAIN BUILD
  // -------------------

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.settings,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(loc.preferences, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 24),

            _statusCard(loc),
            const SizedBox(height: 16),
            _dailyPlanCard(loc),
            const SizedBox(height: 16),
            _languageCard(loc),
            const SizedBox(height: 16),
            _dangerZoneCard(loc),

            const SizedBox(height: 32),
            _footer(loc),
          ],
        ),
      ),
    );
  }

  // -------------------
  // UI SECTIONS
  // -------------------

  Widget _statusCard(AppLocalizations loc) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.black54),
              const SizedBox(width: 8),
              Text(
                loc.currentStatus,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _statusRow('${loc.totalMissed}', '${widget.initial.sum} ${loc.prayers}', Colors.black),
          const SizedBox(height: 8),
          _statusRow(loc.completed, '$_totalCompleted ${loc.prayers}', Colors.green),
          const SizedBox(height: 8),
          _statusRow(loc.remainingPrayers, '$_totalRemaining ${loc.prayers}', const Color(0xFF2563EB)),
        ],
      ),
    );
  }

  Widget _dailyPlanCard(AppLocalizations loc) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.dailyPlan,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            loc.howManyQadaa,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          _planRow(loc.fajr, widget.perDay?['fajr'] ?? 1, loc),
          _planRow(loc.dhuhr, widget.perDay?['dhuhr'] ?? 1, loc),
          _planRow(loc.asr, widget.perDay?['asr'] ?? 1, loc),
          _planRow(loc.maghrib, widget.perDay?['maghrib'] ?? 1, loc),
          _planRow(loc.isha, widget.perDay?['isha'] ?? 1, loc),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _editDailyPlan,
              icon: const Icon(Icons.edit, size: 18),
              label: Text(loc.editPlan),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _languageCard(AppLocalizations loc) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.language, color: Colors.black54),
              const SizedBox(width: 8),
              Text(
                loc.language,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _languageButton(
                  loc.english,
                  _selectedLanguage == 'English',
                      () {
                    setState(() => _selectedLanguage = 'English');
                    MyApp.setLocale(context, const Locale('en'));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _languageButton(
                  loc.arabic,
                  _selectedLanguage == 'Arabic',
                      () {
                    setState(() => _selectedLanguage = 'Arabic');
                    MyApp.setLocale(context, const Locale('ar'));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dangerZoneCard(AppLocalizations loc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.dangerZone,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _resetAllData,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(loc.resetAllData),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(AppLocalizations loc) {
    return Column(
      children: [
        Text(
          loc.appVersion,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          loc.footerSubtitle,
          style: const TextStyle(color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // -------------------
  // REUSABLE WIDGETS
  // -------------------

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _statusRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _planRow(String prayer, int count, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(prayer, style: const TextStyle(fontSize: 16)),
          Text(
            '$count ${loc.perDay}',
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _languageButton(
      String language,
      bool isSelected,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          language,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}