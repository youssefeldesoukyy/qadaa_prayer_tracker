import 'package:flutter/material.dart';
import 'package:qadaa_prayer_tracker/models/daily_totals.dart';
import 'package:qadaa_prayer_tracker/Views/daily_plan.dart';

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

  void _editDailyPlan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DailyPlan(totals: widget.initial),
      ),
    );
  }

  void _resetAllData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Data'),
        content: const Text(
          'This will permanently delete all your progress and reset the app to its initial state. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Implement actual reset logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data reset (placeholder)')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Settings',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Preferences',
                style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 24),

            // Current Status Card
            _statusCard(),

            const SizedBox(height: 16),

            // Daily Plan Card
            _dailyPlanCard(),

            const SizedBox(height: 16),

            // Language Card
            _languageCard(),

            const SizedBox(height: 16),

            // Danger Zone Card
            _dangerZoneCard(),

            const SizedBox(height: 32),

            // Footer
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _statusCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.black54),
              const SizedBox(width: 8),
              const Text('Current Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          _statusRow('Total Missed', '${widget.initial.sum} prayers', Colors.black),
          const SizedBox(height: 8),
          _statusRow('Completed', '$_totalCompleted prayers', Colors.green),
          const SizedBox(height: 8),
          _statusRow('Remaining', '$_totalRemaining prayers', const Color(0xFF2563EB)),
        ],
      ),
    );
  }

  Widget _dailyPlanCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Plan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('How many Qada prayers can you commit to each day?',
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          _planRow('Fajr', widget.perDay?['fajr'] ?? 1),
          _planRow('Dhuhr', widget.perDay?['dhuhr'] ?? 1),
          _planRow('Asr', widget.perDay?['asr'] ?? 1),
          _planRow('Maghrib', widget.perDay?['maghrib'] ?? 1),
          _planRow('Isha', widget.perDay?['isha'] ?? 1),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _editDailyPlan,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit Plan'),
              style: OutlinedButton.styleFrom(
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

  Widget _languageCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.language, color: Colors.black54),
              const SizedBox(width: 8),
              const Text('Language',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _languageButton(
                  'English',
                  _selectedLanguage == 'English',
                  () => setState(() => _selectedLanguage = 'English'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _languageButton(
                  'Arabic',
                  _selectedLanguage == 'Arabic',
                  () => setState(() => _selectedLanguage = 'Arabic'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dangerZoneCard() {
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
          const Text('Danger Zone',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.red,
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _resetAllData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reset All Data'),
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

  Widget _footer() {
    return Column(
      children: [
        const Text('Qadaa Tracker v1.0',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text(
          'Track and complete your missed prayers with clarity and peace.',
          style: TextStyle(color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

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
        Text(value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: valueColor,
            )),
      ],
    );
  }

  Widget _planRow(String prayer, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(prayer, style: const TextStyle(fontSize: 16)),
          Text('$count per day',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              )),
        ],
      ),
    );
  }

  Widget _languageButton(String language, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300,
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
