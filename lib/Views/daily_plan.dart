import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:qadaa_prayer_tracker/models/daily_totals.dart';
import 'Dashboard/home_dashboard.dart';

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

  void _saveAndGo() {
    final loc = AppLocalizations.of(context)!;

    final perDay = {
      'fajr': _int(_fajrPerDay),
      'dhuhr': _int(_dhuhrPerDay),
      'asr': _int(_asrPerDay),
      'maghrib': _int(_maghribPerDay),
      'isha': _int(_ishaPerDay),
    };

    // Validation (optional)
    final isAllZero = perDay.values.every((v) => v == 0);
    if (isAllZero) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.pleaseEnterValidPeriod)),
      );
      return;
    }

    if (widget.fromSettings) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.dailyPlanUpdated)),
      );
      Navigator.pop(context, perDay);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeDashboard(
            initial: widget.totals,
            perDay: perDay,
          ),
        ),
      );
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
                ),
              ),
              const Spacer(),
              Text(
                '$remaining ${loc.remaining}',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: c,
            keyboardType: TextInputType.number,
            inputFormatters: _digitsOnly,
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: const TextStyle(color: Colors.grey),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
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
      backgroundColor: const Color(0xFFF6F7FB),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    loc.setYourDailyPlan,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.howManyQadaa,
                    style: const TextStyle(color: Colors.black54),
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
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      loc.savePlan,
                      style: const TextStyle(fontWeight: FontWeight.w600),
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