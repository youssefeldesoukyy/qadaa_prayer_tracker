import 'package:flutter/material.dart';
import 'package:qadaa_prayer_tracker/core/app_colors.dart';
import 'package:qadaa_prayer_tracker/l10n/app_localizations.dart';
import 'package:qadaa_prayer_tracker/models/daily_totals.dart';
import 'package:qadaa_prayer_tracker/Views/daily_plan.dart';
import 'package:qadaa_prayer_tracker/Views/qadaa_missed.dart';
import 'package:qadaa_prayer_tracker/views/registration/sign_in_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qadaa_prayer_tracker/views/edit_logged_prayers.dart';
import 'package:qadaa_prayer_tracker/core/services/dashboard_service.dart';
import 'package:qadaa_prayer_tracker/core/animations/slide_page_route.dart';

class SettingsDashboard extends StatefulWidget {
  final DailyTotals initial;
  final DailyTotals remaining;
  final Map<String, int>? perDay;
  final VoidCallback? onDataChanged;

  const SettingsDashboard({
    super.key,
    required this.initial,
    required this.remaining,
    this.perDay,
    this.onDataChanged,
  });

  @override
  State<SettingsDashboard> createState() => _SettingsDashboardState();
}

class _SettingsDashboardState extends State<SettingsDashboard> {
  final DashboardService _dashboardService = DashboardService();
  String _selectedLanguage = 'English';
  bool _isGuest = false;
  late DailyTotals _currentInitial;

  int get _totalCompleted => _currentInitial.sum - widget.remaining.sum;
  int get _totalRemaining => widget.remaining.sum;

  @override
  void initState() {
    super.initState();
    _currentInitial = widget.initial;
    _loadGuestStatusAndLanguage();
  }

  // ✅ Load guest status & language
  Future<void> _loadGuestStatusAndLanguage() async {
    // Use dashboardService for prefs
    final prefs = await SharedPreferences.getInstance();
    final isGuest = prefs.getBool('isGuest') ?? false;
    final langCode = await _dashboardService.getSelectedLanguage();
    setState(() {
      _isGuest = isGuest;
      _selectedLanguage = langCode;
    });
  }

  // -------------------------------------------------
  // FIRESTORE RESET FUNCTION
  // -------------------------------------------------
  Future<void> _resetFirestoreData() async {
    await _dashboardService.resetFirestoreData();
  }

  // -------------------------------------------------
  // LOCAL RESET (for guest)
  // -------------------------------------------------
  Future<void> _resetLocalGuestData() async {
    await _dashboardService.resetLocalGuestData();
  }

  // -------------------------------------------------
  // CLEAR LOCAL STORAGE (for logout)
  // -------------------------------------------------
  Future<void> _clearLocalStorage({bool keepGuestFlag = false}) async {
    await _dashboardService.clearLocalStorage(keepGuestFlag: keepGuestFlag);
  }

  void _editLoggedPrayers() async {
    final result = await Navigator.push(
      context,
      SlidePageRoute(
        page: const EditLoggedPrayers(),
        direction: SlideDirection.rightToLeft,
      ),
    );

    if (result == true && mounted) {
      setState(() {});
      widget.onDataChanged?.call(); // 👈 triggers HomeDashboard refresh
    }
  }

  // -------------------------------------------------
  // ACTIONS
  // -------------------------------------------------

  void _editDailyPlan() async {
    final updatedPlan = await Navigator.push<Map<String, int>>(
      context,
      SlidePageRoute(
        page: DailyPlan(
          totals: widget.remaining, // ✅ Pass remaining instead of initial
          perDay: widget.perDay,
          fromSettings: true,
        ),
        direction: SlideDirection.rightToLeft,
      ),
    );

    if (updatedPlan != null) {
      setState(() {
        widget.perDay?.addAll(updatedPlan);
      });
    }
  }

  // 🟢 NEW: Edit missed prayers
  void _editMissedPrayers() async {
    final updatedTotals = await Navigator.push<DailyTotals>(
      context,
      SlidePageRoute(
        page: QadaaMissed(initialTotals: _currentInitial, isEditing: true),
        direction: SlideDirection.rightToLeft,
      ),
    );

    if (updatedTotals != null) {
      // ✅ Validate that missed prayers >= completed prayers for each prayer type
      final completedCounts =
          await _dashboardService.getCompletedCountsByPrayer(isGuest: _isGuest);

      // Check each prayer type individually
      if (updatedTotals.fajr < (completedCounts['fajr'] ?? 0).toDouble() ||
          updatedTotals.dhuhr < (completedCounts['dhuhr'] ?? 0).toDouble() ||
          updatedTotals.asr < (completedCounts['asr'] ?? 0).toDouble() ||
          updatedTotals.maghrib <
              (completedCounts['maghrib'] ?? 0).toDouble() ||
          updatedTotals.isha < (completedCounts['isha'] ?? 0).toDouble()) {
        final loc = AppLocalizations.of(context)!;
        await _showValidationAlert(loc, completedCounts, updatedTotals);
        return; // Don't save the changes
      }

      setState(() {
        _currentInitial = DailyTotals(
          fajr: updatedTotals.fajr,
          dhuhr: updatedTotals.dhuhr,
          asr: updatedTotals.asr,
          maghrib: updatedTotals.maghrib,
          isha: updatedTotals.isha,
        );
      });

      // ✅ Save the updated missed prayers to storage
      await _dashboardService.saveMissedPrayers(updatedTotals,
          isGuest: _isGuest);

      // ✅ Notify home dashboard to refresh
      widget.onDataChanged?.call();
    }
  }

  // ✅ Show validation alert when missed prayers < completed prayers
  Future<void> _showValidationAlert(AppLocalizations loc,
      Map<String, int> completedCounts, DailyTotals missedTotals) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.validationError),
        content: Text(_buildValidationMessage(completedCounts, missedTotals)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              loc.cancel,
              style: AppColors.buttonTextStyle(ctx, color: AppColors.text),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _resetAllData();
            },
            child: Text(loc.resetData),
          ),
        ],
      ),
    );
  }

  // ✅ Build validation message showing which prayer types have issues
  String _buildValidationMessage(
    Map<String, int> completedCounts,
    DailyTotals missedTotals,
  ) {
    final loc = AppLocalizations.of(context)!;
    final issues = <String>[];

    if (missedTotals.fajr < completedCounts['fajr']!) {
      issues.add(loc.validationFajr(
        completedCounts['fajr']!,
        missedTotals.fajr,
      ));
    }

    if (missedTotals.dhuhr < completedCounts['dhuhr']!) {
      issues.add(loc.validationDhuhr(
        completedCounts['dhuhr']!,
        missedTotals.dhuhr,
      ));
    }

    if (missedTotals.asr < completedCounts['asr']!) {
      issues.add(loc.validationAsr(
        completedCounts['asr']!,
        missedTotals.asr,
      ));
    }

    if (missedTotals.maghrib < completedCounts['maghrib']!) {
      issues.add(loc.validationMaghrib(
        completedCounts['maghrib']!,
        missedTotals.maghrib,
      ));
    }

    if (missedTotals.isha < completedCounts['isha']!) {
      issues.add(loc.validationIsha(
        completedCounts['isha']!,
        missedTotals.isha,
      ));
    }

    return '${loc.validationIntro}\n\n${issues.join('\n')}\n\n${loc.validationOutro}';
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
            child: Text(
              loc.cancel,
              style: AppColors.buttonTextStyle(ctx, color: AppColors.text),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (_isGuest) {
                await _resetLocalGuestData();
              } else {
                await _resetFirestoreData();
              }

              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  SlidePageRoute(
                    page: const QadaaMissed(),
                    direction: SlideDirection.rightToLeft,
                  ),
                  (route) => false,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  AppColors.styledSnackBar(loc.allDataReset),
                );
              }
            },
            child: Text(loc.confirmReset),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------
  // HANDLE AUTH BUTTON (Sign in / Logout)
  // -------------------------------------------------
  Future<void> _handleAuthButtonPressed() async {
    final loc = AppLocalizations.of(context)!;

    if (_isGuest) {
      // 🟢 Guest → keep local data, just navigate to main sign-in screen
      if (context.mounted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isGuest', false);

        Navigator.pushAndRemoveUntil(
          context,
          SlidePageRoute(
            page: const SignInScreen(),
            direction: SlideDirection.rightToLeft,
          ),
          (route) => false,
        );
      }
      return;
    }

    // 🔵 Logged-in user → confirm logout
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.logoutTitle),
        content: Text(loc.logoutWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              loc.cancel,
              style: AppColors.buttonTextStyle(ctx, color: AppColors.text),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _dashboardService.signOut();
              await _clearLocalStorage();

              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  SlidePageRoute(
                    page: const SignInScreen(),
                    direction: SlideDirection.rightToLeft,
                  ),
                  (route) => false,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  AppColors.styledSnackBar(loc.loggedOut),
                );
              }
            },
            child: Text(loc.confirm),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------
  // MAIN BUILD
  // -------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.settings,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(loc.preferences,
                style: const TextStyle(color: AppColors.text)),
            const SizedBox(height: 24),

            _statusCard(loc),
            const SizedBox(height: 16),
            _dailyPlanCard(loc),
            const SizedBox(height: 16),
            _languageCard(loc),
            const SizedBox(height: 16),
            _dangerZoneCard(loc),

            const SizedBox(height: 32),

            // ✅ Dynamic button (Sign In or Logout)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleAuthButtonPressed,
                icon: Icon(_isGuest ? Icons.login : Icons.logout, size: 18),
                label: Text(
                  _isGuest ? loc.signIn : loc.logout,
                  style: AppColors.buttonTextStyle(context),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isGuest ? AppColors.primary : Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _footer(loc),
          ],
        ),
        ),
      ),
    );
  }

  // -------------------------------------------------
  // UI SECTIONS
  // -------------------------------------------------
  Widget _statusCard(AppLocalizations loc) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.text),
                const SizedBox(width: 8),
                Text(
                  loc.currentStatus,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _statusRow(loc.totalMissed, '${_currentInitial.sum} ${loc.prayers}',
                AppColors.text),
            const SizedBox(height: 8),
            _statusRow(
                loc.completed, '$_totalCompleted ${loc.prayers}', AppColors.primary),
            const SizedBox(height: 8),
            _statusRow(loc.remainingPrayers, '$_totalRemaining ${loc.prayers}',
                AppColors.secondary),
            const SizedBox(height: 16),
            // 🟢 New Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _editMissedPrayers,
                icon: const Icon(Icons.edit, size: 18),
                label: Text(
                  loc.editMissedPrayers,
                  style: AppColors.buttonTextStyle(context),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _editLoggedPrayers,
                icon: const Icon(Icons.edit_calendar, size: 18),
                label: Text(
                  loc.editLogs,
                  style: AppColors.buttonTextStyle(context),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
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

  Widget _dailyPlanCard(AppLocalizations loc) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.dailyPlan,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(loc.howManyQadaa,
                style: const TextStyle(color: AppColors.text)),
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
                label: Text(
                  loc.editPlan,
                  style: AppColors.buttonTextStyle(context),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
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

  Widget _languageCard(AppLocalizations loc) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.language, color: AppColors.text),
                const SizedBox(width: 8),
                Text(
                  loc.language,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
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
                    () async {
                      setState(() => _selectedLanguage = 'English');
                      await _dashboardService.changeLanguage(context, 'en');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _languageButton(
                    loc.arabic,
                    _selectedLanguage == 'Arabic',
                    () async {
                      setState(() => _selectedLanguage = 'Arabic');
                      await _dashboardService.changeLanguage(context, 'ar');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _dangerZoneCard(AppLocalizations loc) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.dangerZone,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.red)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _resetAllData,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(
                  loc.resetAllData,
                  style: AppColors.buttonTextStyle(context),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _footer(AppLocalizations loc) => Center(
        child: Column(
          children: [
            Image.asset(
              'assets/icons/Itmam_logo.png',
              height: 80,
              fit: BoxFit.contain,
            ),
            Text(
              loc.appTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            Text(
              loc.footerSubtitle,
              style: const TextStyle(color: AppColors.text),
              textAlign: TextAlign.center,
            ),
            Text(
              loc.appVersion,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w300,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.3),
          ),
        ),
        child: child,
      );

  Widget _statusRow(String label, String value, Color valueColor) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: AppColors.text),
          ),
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

  Widget _planRow(String prayer, int count, AppLocalizations loc) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              prayer,
              style: const TextStyle(fontSize: 16, color: AppColors.text),
            ),
            Text(
              '$count ${loc.perDay}',
              style: const TextStyle(fontSize: 16, color: AppColors.text),
            ),
          ],
        ),
      );

  Widget _languageButton(
          String language, bool isSelected, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.secondary.withValues(alpha: 0.3),
            ),
          ),
          child: Text(language,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.text,
                  fontWeight: FontWeight.w600)),
        ),
      );
}
