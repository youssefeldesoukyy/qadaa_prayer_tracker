import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qadaa_prayer_tracker/core/app_colors.dart';
import 'package:qadaa_prayer_tracker/l10n/app_localizations.dart';
import 'package:qadaa_prayer_tracker/models/daily_totals.dart';
import 'package:qadaa_prayer_tracker/Views/daily_plan.dart';
import 'package:qadaa_prayer_tracker/core/services/dashboard_service.dart';
import 'package:qadaa_prayer_tracker/core/animations/slide_page_route.dart';

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back button - RTL-aware
                  Align(
                    alignment: Localizations.localeOf(context).languageCode == 'ar'
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.text),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(height: 8),
                        // Text(
                        //   loc.appTitle,
                        //   textAlign: TextAlign.center,
                        //   style: const TextStyle(
                        //     color: AppColors.text,
                        //     fontSize: 32,
                        //     fontWeight: FontWeight.bold,
                        //   ),
                        // ),
                        const SizedBox(height: 8),
                        Text(
                          loc.qadaaDescription,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.text),
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
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: const StadiumBorder(),
                            ),
                            onPressed: _onCreatePlanPressed,
                            child: Text(
                              widget.isEditing
                                  ? loc.updateMissedPrayers
                                  : loc.createMyPlan,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
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
        backgroundColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return AppColors.accent.withValues(alpha: 0.1);
          },
        ),
        foregroundColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return AppColors.text;
          },
        ),
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
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: AppColors.secondary.withValues(alpha: 0.3),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: _digitsOnly,
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: AppColors.text),
          floatingLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
          hintText: '0',
          hintStyle: TextStyle(
            color: AppColors.text.withValues(alpha: 0.5),
            fontSize: 13,
          ),
          filled: true,
          fillColor: AppColors.accent.withValues(alpha: 0.1),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
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
          AppColors.styledSnackBar(loc.pleaseEnterValidPeriod),
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

    final nextPage = SlidePageRoute(
      page: DailyPlan(totals: totals),
      direction: SlideDirection.rightToLeft,
    );

    if (shouldUseGuestFlow) {
      Navigator.pushReplacement(context, nextPage);
    } else {
      Navigator.push(context, nextPage);
    }
  }
}
