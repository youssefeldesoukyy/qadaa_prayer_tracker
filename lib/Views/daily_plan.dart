import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DailyTotals {
  final int fajr, dhuhr, asr, maghrib, isha;

  const DailyTotals({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });
}

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

  int _daysNeeded(int total, String perDayText) {
    final per = int.tryParse(perDayText) ?? 0;
    if (per <= 0) return 0;
    return (total / per).ceil();
  }

  String _estimate() {
    final t = widget.totals;
    final nF = _daysNeeded(t.fajr, _fajrPerDay.text);
    final nD = _daysNeeded(t.dhuhr, _dhuhrPerDay.text);
    final nA = _daysNeeded(t.asr, _asrPerDay.text);
    final nM = _daysNeeded(t.maghrib, _maghribPerDay.text);
    final nI = _daysNeeded(t.isha, _ishaPerDay.text);

    final maxDays = [nF, nD, nA, nM, nI]
        .where((e) => e > 0)
        .fold<int>(0, (a, b) => a > b ? a : b);
    if (maxDays == 0) return '—';

    if (maxDays >= 365) {
      final years = (maxDays / 365).toStringAsFixed(0);
      return '$years year${years == '1' ? '' : 's'}';
    } else if (maxDays >= 30) {
      final months = (maxDays / 30).toStringAsFixed(0);
      return '$months month${months == '1' ? '' : 's'}';
    }
    return '$maxDays day${maxDays == 1 ? '' : 's'}';
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.totals;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(title: const Text('Set Your Daily Plan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'How many Qada prayers can you commit to each day?',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              _rowField('Fajr', t.fajr, _fajrPerDay),
              _rowField('Dhuhr', t.dhuhr, _dhuhrPerDay),
              _rowField('Asr', t.asr, _asrPerDay),
              _rowField('Maghrib', t.maghrib, _maghribPerDay),
              _rowField('Isha', t.isha, _ishaPerDay),
              const SizedBox(height: 12),
              _estimateCard(_estimate()),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  // TODO: save the plan
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Plan saved')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Plan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowField(
      String label, int remaining, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('$remaining remaining',
                  style: const TextStyle(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: _digitsOnly,
            decoration: InputDecoration(
              hintText: '1',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (_) => setState(() {}), // recompute estimate live
          ),
        ],
      ),
    );
  }

  Widget _estimateCard(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Estimated completion:',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}