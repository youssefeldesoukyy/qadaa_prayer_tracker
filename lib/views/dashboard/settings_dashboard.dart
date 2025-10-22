import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qadaa_prayer_tracker/Views/sign_in_screen.dart';
import 'package:qadaa_prayer_tracker/l10n/app_localizations.dart';
import 'package:qadaa_prayer_tracker/main.dart';
import 'package:qadaa_prayer_tracker/models/daily_totals.dart';
import 'package:qadaa_prayer_tracker/Views/daily_plan.dart';
import 'package:qadaa_prayer_tracker/Views/qadaa_missed.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qadaa_prayer_tracker/Views/Dashboard/edit_logged_prayers.dart';

class SettingsDashboard extends StatefulWidget {
  DailyTotals initial;
  final DailyTotals remaining;
  final Map<String, int>? perDay;
  final VoidCallback? onDataChanged; // 👈 add this

  SettingsDashboard({
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
  String _selectedLanguage = 'English';
  bool _isGuest = false;

  int get _totalCompleted => widget.initial.sum - widget.remaining.sum;
  int get _totalRemaining => widget.remaining.sum;

  @override
  void initState() {
    super.initState();
    _loadGuestStatusAndLanguage();
  }

  // ✅ Load guest status & language
  Future<void> _loadGuestStatusAndLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final isGuest = prefs.getBool('isGuest') ?? false;
    final langCode = prefs.getString('language_code') ?? 'ar';
    setState(() {
      _isGuest = isGuest;
      _selectedLanguage = langCode == 'ar' ? 'Arabic' : 'English';
    });
  }

  // -------------------------------------------------
  // FIRESTORE RESET FUNCTION
  // -------------------------------------------------
  Future<void> _resetFirestoreData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userRef =
          FirebaseFirestore.instance.collection('Users').doc(user.uid);

      await userRef.update({
        'prayerPlan.missedPrayers': {
          'fajr': 0,
          'dhuhr': 0,
          'asr': 0,
          'maghrib': 0,
          'isha': 0,
        },
        'prayerPlan.dailyPlan': {
          'fajr': 0,
          'dhuhr': 0,
          'asr': 0,
          'maghrib': 0,
          'isha': 0,
        },
        'logs': {},
      });

      debugPrint('✅ Firestore data reset successfully.');
    } catch (e) {
      debugPrint('❌ Error resetting Firestore data: $e');
    }
  }

  // -------------------------------------------------
  // LOCAL RESET (for guest)
  // -------------------------------------------------
  Future<void> _resetLocalGuestData() async {
    final prefs = await SharedPreferences.getInstance();

    // Keep guest flag and language
    final lang = prefs.getString('language_code') ?? 'ar';
    await prefs.clear();
    await prefs.setBool('isGuest', true);
    await prefs.setString('language_code', lang);

    // Reset only qadaa + daily plan, keep other things like createdAt
    await prefs.remove('guestTotals');
    await prefs.remove('guestPerDay');
    await prefs.remove('guestLogs');

    debugPrint('✅ Local guest prayer data reset.');
  }

  // -------------------------------------------------
  // CLEAR LOCAL STORAGE (for logout)
  // -------------------------------------------------
  Future<void> _clearLocalStorage({bool keepGuestFlag = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language_code') ?? 'ar';
    await prefs.clear();

    if (keepGuestFlag) {
      await prefs.setBool('isGuest', true);
      await prefs.setString('language_code', lang);
    }

    debugPrint('✅ Local SharedPreferences cleared.');
  }

  void _editLoggedPrayers() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditLoggedPrayers()),
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

  // 🟢 NEW: Edit missed prayers
  void _editMissedPrayers() async {
    final updatedTotals = await Navigator.push<DailyTotals>(
      context,
      MaterialPageRoute(
          builder: (_) =>
              QadaaMissed(initialTotals: widget.initial, isEditing: true)),
    );

    if (updatedTotals != null) {
      // ✅ Validate that missed prayers >= completed prayers for each prayer type
      final completedCounts = await _getCompletedCountsByPrayer();

      // Check each prayer type individually
      if (updatedTotals.fajr < (completedCounts['fajr'] ?? 0).toDouble() ||
          updatedTotals.dhuhr < (completedCounts['dhuhr'] ?? 0).toDouble() ||
          updatedTotals.asr < (completedCounts['asr'] ?? 0).toDouble() ||
          updatedTotals.maghrib < (completedCounts['maghrib'] ?? 0).toDouble() ||
          updatedTotals.isha < (completedCounts['isha'] ?? 0).toDouble()) {
        final loc = AppLocalizations.of(context)!;
        await _showValidationAlert(loc, completedCounts, updatedTotals);
        return; // Don't save the changes
      }

      setState(() {
        widget.initial = DailyTotals(
          fajr: updatedTotals.fajr,
          dhuhr: updatedTotals.dhuhr,
          asr: updatedTotals.asr,
          maghrib: updatedTotals.maghrib,
          isha: updatedTotals.isha,
        );
      });

      // ✅ Save the updated missed prayers to storage
      await _saveMissedPrayersToStorage(updatedTotals);

      // ✅ Notify home dashboard to refresh
      widget.onDataChanged?.call();
    }
  }

  // ✅ Get actual completed count by prayer type from storage (Firebase or SharedPreferences)
  Future<Map<String, int>> _getCompletedCountsByPrayer() async {
    if (_isGuest) {
      // Guest mode: Get from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final logsString = prefs.getString('guestLogs');
      if (logsString != null) {
        final logs = jsonDecode(logsString);
        int fajr = 0, dhuhr = 0, asr = 0, maghrib = 0, isha = 0;

        // Calculate completed by prayer type from logs
        if (logs.values.isNotEmpty && logs.values.first is Map) {
          for (var entry in logs.values) {
            final day = Map<String, int>.from(entry);
            fajr += (day['fajr'] ?? 0);
            dhuhr += (day['dhuhr'] ?? 0);
            asr += (day['asr'] ?? 0);
            maghrib += (day['maghrib'] ?? 0);
            isha += (day['isha'] ?? 0);
          }
        }
        return {
          'fajr': fajr,
          'dhuhr': dhuhr,
          'asr': asr,
          'maghrib': maghrib,
          'isha': isha
        };
      }
      return {'fajr': 0, 'dhuhr': 0, 'asr': 0, 'maghrib': 0, 'isha': 0};
    } else {
      // Logged-in mode: Get from Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .get();

          if (doc.exists) {
            final data = doc.data() ?? {};
            final logs = Map<String, dynamic>.from(data['logs'] ?? {});
            int fajr = 0, dhuhr = 0, asr = 0, maghrib = 0, isha = 0;

            // Calculate completed by prayer type from Firebase logs
            for (var entry in logs.values) {
              final day = Map<String, int>.from(entry);
              fajr += (day['fajr'] ?? 0);
              dhuhr += (day['dhuhr'] ?? 0);
              asr += (day['asr'] ?? 0);
              maghrib += (day['maghrib'] ?? 0);
              isha += (day['isha'] ?? 0);
            }
            return {
              'fajr': fajr,
              'dhuhr': dhuhr,
              'asr': asr,
              'maghrib': maghrib,
              'isha': isha
            };
          }
        } catch (e) {
          debugPrint('❌ Error getting completed count from Firebase: $e');
        }
      }
      return {'fajr': 0, 'dhuhr': 0, 'asr': 0, 'maghrib': 0, 'isha': 0};
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
            child:
                Text(loc.cancel, style: const TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
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
      Map<String, int> completedCounts, DailyTotals missedTotals) {
    final issues = <String>[];

    if (missedTotals.fajr < completedCounts['fajr']!) {
      issues.add(
          'Fajr: ${completedCounts['fajr']} completed but only ${missedTotals.fajr} missed');
    }
    if (missedTotals.dhuhr < completedCounts['dhuhr']!) {
      issues.add(
          'Dhuhr: ${completedCounts['dhuhr']} completed but only ${missedTotals.dhuhr} missed');
    }
    if (missedTotals.asr < completedCounts['asr']!) {
      issues.add(
          'Asr: ${completedCounts['asr']} completed but only ${missedTotals.asr} missed');
    }
    if (missedTotals.maghrib < completedCounts['maghrib']!) {
      issues.add(
          'Maghrib: ${completedCounts['maghrib']} completed but only ${missedTotals.maghrib} missed');
    }
    if (missedTotals.isha < completedCounts['isha']!) {
      issues.add(
          'Isha: ${completedCounts['isha']} completed but only ${missedTotals.isha} missed');
    }

    return 'You have completed more prayers than missed for:\n\n${issues.join('\n')}\n\nYou need to reset your data to proceed.';
  }

  // ✅ Save missed prayers to storage (Firestore or SharedPreferences)
  Future<void> _saveMissedPrayersToStorage(DailyTotals totals) async {
    if (_isGuest) {
      // Guest mode: Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('guestTotals', jsonEncode(totals.toJson()));
      debugPrint('✅ Guest missed prayers saved: $totals');
    } else {
      // Logged-in mode: Save to Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .update({
            'prayerPlan.missedPrayers': totals.toMap(),
          });
          debugPrint('✅ Firestore missed prayers saved: $totals');
        } catch (e) {
          debugPrint('❌ Error saving missed prayers to Firestore: $e');
        }
      }
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
            child:
                Text(loc.cancel, style: const TextStyle(color: Colors.black)),
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
                  MaterialPageRoute(builder: (_) => const QadaaMissed()),
                  (route) => false,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.allDataReset)),
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
          MaterialPageRoute(builder: (_) => const SignInScreen()),
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
            child:
                Text(loc.cancel, style: const TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
              await _clearLocalStorage();

              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                  (route) => false,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.loggedOut)),
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

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.settings,
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(loc.preferences,
                style: const TextStyle(color: Colors.black54)),
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
                label: Text(_isGuest ? loc.signIn : loc.logout),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isGuest ? const Color(0xFF2563EB) : Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _footer(loc),
          ],
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
                const Icon(Icons.info_outline, color: Colors.black54),
                const SizedBox(width: 8),
                Text(loc.currentStatus,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            _statusRow(loc.totalMissed, '${widget.initial.sum} ${loc.prayers}',
                Colors.black),
            const SizedBox(height: 8),
            _statusRow(
                loc.completed, '$_totalCompleted ${loc.prayers}', Colors.green),
            const SizedBox(height: 8),
            _statusRow(loc.remainingPrayers, '$_totalRemaining ${loc.prayers}',
                const Color(0xFF2563EB)),
            const SizedBox(height: 16),
            // 🟢 New Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _editMissedPrayers,
                icon: const Icon(Icons.edit, size: 18),
                label: Text(loc.editMissedPrayers),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
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
                label: Text(loc.editLogs),
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

  Widget _dailyPlanCard(AppLocalizations loc) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.dailyPlan,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(loc.howManyQadaa,
                style: const TextStyle(color: Colors.black54)),
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

  Widget _languageCard(AppLocalizations loc) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.language, color: Colors.black54),
                const SizedBox(width: 8),
                Text(loc.language,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _languageButton(
                        loc.english, _selectedLanguage == 'English', () async {
                  setState(() => _selectedLanguage = 'English');
                  MyApp.setLocale(context, const Locale('en'));
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('language_code', 'en');
                })),
                const SizedBox(width: 12),
                Expanded(
                    child: _languageButton(
                        loc.arabic, _selectedLanguage == 'Arabic', () async {
                  setState(() => _selectedLanguage = 'Arabic');
                  MyApp.setLocale(context, const Locale('ar'));
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('language_code', 'ar');
                })),
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
          borderRadius: BorderRadius.circular(12),
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
                label: Text(loc.resetAllData),
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
            Text(loc.appVersion,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(loc.footerSubtitle,
                style: const TextStyle(color: Colors.black54),
                textAlign: TextAlign.center),
          ],
        ),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: child,
      );

  Widget _statusRow(String label, String value, Color valueColor) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: valueColor)),
        ],
      );

  Widget _planRow(String prayer, int count, AppLocalizations loc) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(prayer, style: const TextStyle(fontSize: 16)),
            Text('$count ${loc.perDay}',
                style: const TextStyle(fontSize: 16, color: Colors.black54)),
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
            color: isSelected ? const Color(0xFF2563EB) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : Colors.grey.shade300),
          ),
          child: Text(language,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600)),
        ),
      );
}
