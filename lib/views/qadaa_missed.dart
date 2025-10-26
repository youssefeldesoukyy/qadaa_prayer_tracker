import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qadaa_prayer_tracker/l10n/app_localizations.dart';
import 'package:qadaa_prayer_tracker/models/daily_totals.dart';
import 'package:qadaa_prayer_tracker/Views/daily_plan.dart';
import 'package:qadaa_prayer_tracker/core/services/dashboard_service.dart';

class QadaaMissed extends StatefulWidget {
  final bool fromGuest; // ✅ distinguish guest vs logged user
  final DailyTotals? initialTotals; // ✅ Add initial data
  final bool isEditing; // ✅ Add flag to distinguish editing vs creating

  const QadaaMissed(
      {super.key,
      this.fromGuest = false,
      this.initialTotals,
      this.isEditing = false});

  @override
  State<QadaaMissed> createState() => _QadaaMissedState();
}

enum QadaMode { timePeriod, manual }

class _QadaaMissedState extends State<QadaaMissed> {
  QadaMode _mode = QadaMode.timePeriod;
  final DashboardService _dashboardService = DashboardService();

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
  void initState() {
    super.initState();
    // ✅ Populate fields with existing data if available
    if (widget.initialTotals != null) {
      // ✅ Smart mode detection: if all values are equal, likely from time period
      final allEqual = widget.initialTotals!.fajr == widget.initialTotals!.dhuhr &&
          widget.initialTotals!.dhuhr == widget.initialTotals!.asr &&
          widget.initialTotals!.asr == widget.initialTotals!.maghrib &&
          widget.initialTotals!.maghrib == widget.initialTotals!.isha;

      if (allEqual && widget.initialTotals!.fajr > 0) {
        // Time period mode - only populate time fields
        _convertToTimePeriod(widget.initialTotals!.fajr);
        _mode = QadaMode.timePeriod;
      } else {
        // Manual mode - only populate manual fields
        _fajr.text = widget.initialTotals!.fajr.toString();
        _dhuhr.text = widget.initialTotals!.dhuhr.toString();
        _asr.text = widget.initialTotals!.asr.toString();
        _maghrib.text = widget.initialTotals!.maghrib.toString();
        _isha.text = widget.initialTotals!.isha.toString();
        _mode = QadaMode.manual;
      }
    }
  }

  void _convertToTimePeriod(int totalDays) {
    // Simple conversion: try to break down total days into years, months, days
    final years = totalDays ~/ 365;
    final remainingAfterYears = totalDays % 365;
    final months = remainingAfterYears ~/ 30;
    final days = remainingAfterYears % 30;

    _years.text = years.toString();
    _months.text = months.toString();
    _days.text = days.toString();
  }

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/sign_in_background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 18),
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
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: _onCreatePlanPressed,
                          child: Text(
                            widget.isEditing
                                ? loc.updateMissedPrayers
                                : loc.createMyPlan,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitch(AppLocalizations loc) {
    return SegmentedButton<QadaMode>(
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
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
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

      totals = DailyTotals(fajr: f, dhuhr: d, asr: a, maghrib: m, isha: i);
    }

    // ✅ If editing, just return the updated totals
    if (widget.isEditing) {
      if (mounted) {
        Navigator.pop(context, totals);
      }
      return;
    }

    final shouldUseGuestFlow =
        widget.fromGuest || await _dashboardService.useGuestFlow();

    await _dashboardService.saveMissedPrayers(
      totals,
      isGuest: shouldUseGuestFlow,
    );

    if (!mounted) return;

    final nextPage = MaterialPageRoute(
      builder: (_) => DailyPlan(totals: totals),
    );

    if (shouldUseGuestFlow) {
      Navigator.pushReplacement(context, nextPage);
    } else {
      Navigator.push(context, nextPage);
    }
  }
}
