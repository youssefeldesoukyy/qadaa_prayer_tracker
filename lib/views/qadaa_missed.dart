import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qadaa_prayer_tracker/l10n/app_localizations.dart';
import 'package:qadaa_prayer_tracker/models/daily_totals.dart';
import 'package:qadaa_prayer_tracker/Views/daily_plan.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QadaaMissed extends StatefulWidget {
  const QadaaMissed({super.key});

  @override
  State<QadaaMissed> createState() => _QadaaMissedState();
}

enum QadaMode { timePeriod, manual }

class _QadaaMissedState extends State<QadaaMissed> {
  QadaMode _mode = QadaMode.timePeriod;

  final _years = TextEditingController();
  final _months = TextEditingController();
  final _days = TextEditingController();
  final _fajr = TextEditingController();
  final _dhuhr = TextEditingController();
  final _asr = TextEditingController();
  final _maghrib = TextEditingController();
  final _isha = TextEditingController();

  final _digitsOnly = [FilteringTextInputFormatter.digitsOnly];

  @override
  void dispose() {
    for (final c in [
      _years,
      _months,
      _days,
      _fajr,
      _dhuhr,
      _asr,
      _maghrib,
      _isha
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  loc.qadaaTracker,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.qadaaDescription,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),
                _buildModeSwitch(loc),
                const SizedBox(height: 20),
                if (_mode == QadaMode.timePeriod)
                  _buildTimeFields(loc)
                else
                  _buildManualFields(loc),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _onCreatePlanPressed,
                  child: Text(
                    loc.createMyPlan,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSwitch(AppLocalizations loc) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<QadaMode>(
        segments: [
          ButtonSegment<QadaMode>(
            value: QadaMode.timePeriod,
            label: Text(loc.timePeriod),
          ),
          ButtonSegment<QadaMode>(
            value: QadaMode.manual,
            label: Text(loc.manualEntry),
          ),
        ],
        selected: {_mode},
        onSelectionChanged: (s) => setState(() => _mode = s.first),
        showSelectedIcon: false,
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size.fromHeight(48)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeFields(AppLocalizations loc) {
    return Column(
      children: [
        _textField(loc.years, _years),
        _textField(loc.months, _months),
        _textField(loc.days, _days),
      ],
    );
  }

  Widget _buildManualFields(AppLocalizations loc) {
    return Column(
      children: [
        _textField(loc.fajr, _fajr),
        _textField(loc.dhuhr, _dhuhr),
        _textField(loc.asr, _asr),
        _textField(loc.maghrib, _maghrib),
        _textField(loc.isha, _isha),
      ],
    );
  }

  // 🔹 Unified text field style (blue border, blue cursor)
  Widget _textField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: _digitsOnly,
        cursorColor: const Color(0xFF2563EB),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54),
          floatingLabelStyle: const TextStyle(color: Color(0xFF2563EB)),
          hintText: '0',
          hintStyle: const TextStyle(color: Colors.grey),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            const BorderSide(color: Color(0xFF2563EB), width: 2),
          ),
        ),
      ),
    );
  }

  Future<void> _onCreatePlanPressed() async {
    final loc = AppLocalizations.of(context)!;
    late DailyTotals totals;

    if (_mode == QadaMode.timePeriod) {
      final y = int.tryParse(_years.text) ?? 0;
      final m = int.tryParse(_months.text) ?? 0;
      final d = int.tryParse(_days.text) ?? 0;

      final totalDays = (y * 365) + (m * 30) + d;

      if (totalDays == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.pleaseEnterValidPeriod)),
        );
        return;
      }

      totals = DailyTotals(
        fajr: totalDays,
        dhuhr: totalDays,
        asr: totalDays,
        maghrib: totalDays,
        isha: totalDays,
      );
    } else {
      final f = int.tryParse(_fajr.text) ?? 0;
      final d = int.tryParse(_dhuhr.text) ?? 0;
      final a = int.tryParse(_asr.text) ?? 0;
      final m = int.tryParse(_maghrib.text) ?? 0;
      final i = int.tryParse(_isha.text) ?? 0;

      totals = DailyTotals(
        fajr: f,
        dhuhr: d,
        asr: a,
        maghrib: m,
        isha: i,
      );
    }

    // 🔥 Save missed prayers to Firestore
    await _saveMissedPrayersToFirestore(totals);

    // Then navigate to DailyPlan screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DailyPlan(totals: totals)),
    );
  }

  Future<void> _saveMissedPrayersToFirestore(DailyTotals totals) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;

    final missedMap = {
      'fajr': totals.fajr,
      'dhuhr': totals.dhuhr,
      'asr': totals.asr,
      'maghrib': totals.maghrib,
      'isha': totals.isha,
    };

    try {
      await firestore.collection('Users').doc(user.uid).update({
        'prayerPlan.createdAt': FieldValue.serverTimestamp(),
        'prayerPlan.missedPrayers': missedMap,
      });

      debugPrint('✅ Missed prayers saved for ${user.email}');
    } catch (e) {
      debugPrint('❌ Error saving missed prayers: $e');
    }
  }
}
