import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qadaa_prayer_tracker/models/daily_totals.dart';
import 'home_dashboard.dart';

class DailyPlan extends StatefulWidget {
  final DailyTotals totals;
  const DailyPlan({super.key, required this.totals});

  @override
  State<DailyPlan> createState() => _DailyPlanState();
}

class _DailyPlanState extends State<DailyPlan> {
  final _digitsOnly = [FilteringTextInputFormatter.digitsOnly];

  final _fajrPerDay = TextEditingController(text: '1');
  final _dhuhrPerDay = TextEditingController(text: '1');
  final _asrPerDay = TextEditingController(text: '1');
  final _maghribPerDay = TextEditingController(text: '1');
  final _ishaPerDay = TextEditingController(text: '1');

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
    final perDay = {
      'fajr': _int(_fajrPerDay),
      'dhuhr': _int(_dhuhrPerDay),
      'asr': _int(_asrPerDay),
      'maghrib': _int(_maghribPerDay),
      'isha': _int(_ishaPerDay),
    };

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

  Widget _rowField(String label, int remaining, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const Spacer(),
            Text('$remaining remaining',
                style: const TextStyle(color: Colors.black54)),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: c,
            keyboardType: TextInputType.number,
            inputFormatters: _digitsOnly,
            decoration: InputDecoration(
              hintText: '1',
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  const Text('Set Your Daily Plan',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                      'How many Qada prayers can you commit to each day?',
                      style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 24),
                  _rowField('Fajr', t.fajr, _fajrPerDay),
                  _rowField('Dhuhr', t.dhuhr, _dhuhrPerDay),
                  _rowField('Asr', t.asr, _asrPerDay),
                  _rowField('Maghrib', t.maghrib, _maghribPerDay),
                  _rowField('Isha', t.isha, _ishaPerDay),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveAndGo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Save Plan',
                        style: TextStyle(fontWeight: FontWeight.w600)),
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