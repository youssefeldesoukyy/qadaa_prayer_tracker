import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qadaa_prayer_tracker/Views/daily_plan.dart';

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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Qada Tracker',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Track and complete your missed prayers with clarity and peace.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),
                _buildModeSwitch(),
                const SizedBox(height: 20),
                if (_mode == QadaMode.timePeriod)
                  _buildTimeFields()
                else
                  _buildManualFields(),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade400,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    final y = int.tryParse(_years.text) ?? 0;
                    final m = int.tryParse(_months.text) ?? 0;
                    final d = int.tryParse(_days.text) ?? 0;
                    final totalDays = y * 365 + m * 30 + d;

                    final totals = DailyTotals(
                      fajr: totalDays,
                      dhuhr: totalDays,
                      asr: totalDays,
                      maghrib: totalDays,
                      isha: totalDays,
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => DailyPlan(totals: totals)),
                    );
                  },
                  child: const Text(
                    'Create My Plan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSwitch() {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<QadaMode>(
        segments: const [
          ButtonSegment<QadaMode>(
              value: QadaMode.timePeriod, label: Text('Time Period')),
          ButtonSegment<QadaMode>(
              value: QadaMode.manual, label: Text('Manual Entry')),
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

  Widget _buildTimeFields() {
    return Column(
      children: [
        _textField('Years', _years),
        _textField('Months', _months),
        _textField('Days', _days),
      ],
    );
  }

  Widget _buildManualFields() {
    return Column(
      children: [
        _textField('Fajr', _fajr),
        _textField('Dhuhr', _dhuhr),
        _textField('Asr', _asr),
        _textField('Maghrib', _maghrib),
        _textField('Isha', _isha),
      ],
    );
  }

  Widget _textField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: _digitsOnly,
        decoration: InputDecoration(
          labelText: label,
          hintText: '0',
          hintStyle: const TextStyle(color: Colors.grey),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.deepPurple),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.deepPurple, width: 2),
          ),
        ),
      ),
    );
  }
}
