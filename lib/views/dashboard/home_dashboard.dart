import 'package:flutter/material.dart';
import 'package:qadaa_prayer_tracker/core/app_colors.dart';
import 'package:qadaa_prayer_tracker/l10n/app_localizations.dart';
import 'package:qadaa_prayer_tracker/Views/Dashboard/settings_dashboard.dart';
import 'package:qadaa_prayer_tracker/Views/Dashboard/stats_dashboard.dart';
import 'package:qadaa_prayer_tracker/models/daily_totals.dart';
import 'package:qadaa_prayer_tracker/core/services/dashboard_service.dart';

class HomeDashboard extends StatefulWidget {
  final DailyTotals initial;
  final Map<String, int>? perDay;

  const HomeDashboard({
    super.key,
    required this.initial,
    this.perDay,
  });

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard>
    with TickerProviderStateMixin {
  int _tabIndex = 0;
  late DailyTotals _initial;
  late DailyTotals _remaining;
  int _totalCompleted = 0;
  bool _isLoading = true;
  bool _isGuest = false;
  Map<String, dynamic> _guestLogs = {};
  final DashboardService _dashboardService = DashboardService();
  
  // Animation controllers
  final Map<String, AnimationController> _buttonControllers = {};
  late AnimationController _dialogAnimationController;

  @override
  void initState() {
    super.initState();
    _initial = widget.initial;
    _remaining = widget.initial;
    
    // Initialize animation controllers for each prayer button
    final prayerKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
    for (final key in prayerKeys) {
      _buttonControllers[key] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      );
    }
    
    // Initialize dialog animation controller
    _dialogAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _loadDashboardData();
  }
  
  @override
  void dispose() {
    // Dispose all animation controllers
    for (final controller in _buttonControllers.values) {
      controller.dispose();
    }
    _dialogAnimationController.dispose();
    super.dispose();
  }

  // ✅ Reload data from storage when called from settings
  void _reloadData() async {
    await _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final result = await _dashboardService.loadDashboardData(widget.initial);
      if (!mounted) return;
      setState(() {
        _initial = result.initial;
        _remaining = result.remaining;
        _totalCompleted = result.totalCompleted;
        _isGuest = result.isGuest;
        _guestLogs = result.guestLogs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading dashboard data: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  int get _totalInitial => _initial.sum;
  int get _totalRemaining => _remaining.sum;
  double get _progress =>
      _totalInitial == 0 ? 0 : _totalCompleted / _totalInitial;

  // ---------------- LOGIC ----------------
  void _logOne(String prayerKey) async {
    final loc = AppLocalizations.of(context)!;
    bool logged = false;

    // Animate button press
    final buttonController = _buttonControllers[prayerKey];
    if (buttonController != null) {
      buttonController.forward().then((_) {
        buttonController.reverse();
      });
    }

    setState(() {
      switch (prayerKey) {
        case 'fajr':
          if (_remaining.fajr > 0) {
            _remaining = _remaining.copyWith(fajr: _remaining.fajr - 1);
            _totalCompleted++;
            logged = true;
          }
          break;
        case 'dhuhr':
          if (_remaining.dhuhr > 0) {
            _remaining = _remaining.copyWith(dhuhr: _remaining.dhuhr - 1);
            _totalCompleted++;
            logged = true;
          }
          break;
        case 'asr':
          if (_remaining.asr > 0) {
            _remaining = _remaining.copyWith(asr: _remaining.asr - 1);
            _totalCompleted++;
            logged = true;
          }
          break;
        case 'maghrib':
          if (_remaining.maghrib > 0) {
            _remaining = _remaining.copyWith(maghrib: _remaining.maghrib - 1);
            _totalCompleted++;
            logged = true;
          }
          break;
        case 'isha':
          if (_remaining.isha > 0) {
            _remaining = _remaining.copyWith(isha: _remaining.isha - 1);
            _totalCompleted++;
            logged = true;
          }
          break;
      }
    });

    final prayerNames = {
      'fajr': loc.fajr,
      'dhuhr': loc.dhuhr,
      'asr': loc.asr,
      'maghrib': loc.maghrib,
      'isha': loc.isha,
    };

    final label = prayerNames[prayerKey] ?? prayerKey;
    final title = logged ? loc.prayerLogged : loc.nothingToLog;
    final subtitle =
    logged ? loc.prayerCompleted(label) : loc.noPrayerRemaining(label);

    _showCenteredNotice(title: title, subtitle: subtitle, isSuccess: logged);

    if (logged) {
      try {
        if (_isGuest) {
          final updatedLogs =
              await _dashboardService.logGuestPrayer(prayerKey, _guestLogs);
          if (!mounted) return;
          setState(() => _guestLogs = updatedLogs);
        } else {
          await _dashboardService.logUserPrayer(prayerKey);
        }
      } catch (e) {
        debugPrint('❌ Error persisting prayer log: $e');
      }
    }
  }

  void _showCenteredNotice({
    required String title,
    required String subtitle,
    bool isSuccess = false,
  }) {
    final loc = AppLocalizations.of(context)!;
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: loc.barrierDismiss,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        // Use the built-in animation from showGeneralDialog
        final scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          ),
        );
        
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeIn,
          ),
        );
        
        final iconScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
          ),
        );
        
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (Navigator.of(ctx).canPop()) {
            Navigator.of(ctx).pop();
          }
        });
        
        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (isSuccess)
                        ScaleTransition(
                          scale: iconScaleAnimation,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: 40,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: AppColors.secondary,
                            size: 40,
                          ),
                        ),
                      if (isSuccess) const SizedBox(height: 16),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------- UI ----------------
  Widget _homePage() {
    final loc = AppLocalizations.of(context)!;
    if (_isLoading) return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
      ),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          children: [
            Text(
              loc.appTitle,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(loc.totalProgress,
                style: const TextStyle(color: AppColors.text)),
            const SizedBox(height: 24),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: _progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, animatedProgress, child) {
                return SizedBox(
                  width: 180,
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: CircularProgressIndicator(
                          value: animatedProgress,
                          strokeWidth: 14,
                          backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                          color: AppColors.primary,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TweenAnimationBuilder<int>(
                            tween: IntTween(
                              begin: 0,
                              end: (_progress * 100).floor(),
                            ),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            builder: (context, animatedValue, child) {
                              return Text(
                                '$animatedValue%',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          Text(
                            loc.complete,
                            style: const TextStyle(color: AppColors.text),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(child: _statCard(loc.totalMissed, '$_totalInitial')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _statCard(loc.totalCompleted, '$_totalCompleted',
                          valueColor: AppColors.primary)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _statCard(loc.remainingPrayers, '$_totalRemaining',
                          valueColor: AppColors.secondary)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _breakdownContainer(loc),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, {Color? valueColor}) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: AppColors.secondary.withValues(alpha: 0.3),
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.text,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.text),
        ),
      ],
    ),
  );

  Widget _breakdownContainer(AppLocalizations loc) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: AppColors.secondary.withValues(alpha: 0.3),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.prayerBreakdown,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 10),
        _breakdownRow(Icons.nights_stay_outlined, loc.fajr, _initial.fajr,
            _remaining.fajr, 'fajr'),
        _breakdownRow(Icons.wb_sunny_outlined, loc.dhuhr, _initial.dhuhr,
            _remaining.dhuhr, 'dhuhr'),
        _breakdownRow(Icons.wb_twilight_outlined, loc.asr, _initial.asr,
            _remaining.asr, 'asr'),
        _breakdownRow(Icons.brightness_3_outlined, loc.maghrib,
            _initial.maghrib, _remaining.maghrib, 'maghrib'),
        _breakdownRow(Icons.star_border, loc.isha, _initial.isha,
            _remaining.isha, 'isha'),
      ],
    ),
  );

  Widget _breakdownRow(
      IconData icon, String label, int initial, int remaining, String key) {
    final completed = (initial - remaining).clamp(0, initial);
    final pct = initial == 0 ? 0.0 : completed / initial;

    final loc = AppLocalizations.of(context)!;
    final buttonController = _buttonControllers[key] ?? _dialogAnimationController;
    
    // Create scale animation for button press
    final scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: buttonController,
        curve: Curves.easeInOut,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: AnimatedBuilder(
        animation: buttonController,
        builder: (context, child) {
          return Transform.scale(
            scale: scaleAnimation.value,
            child: InkWell(
              onTap: () => _logOne(key),
              borderRadius: BorderRadius.circular(12),
              splashColor: AppColors.primary.withValues(alpha: 0.1),
              highlightColor: AppColors.primary.withValues(alpha: 0.05),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        Text(
                          '$completed/$initial',
                          style: const TextStyle(color: AppColors.text),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.primary.withValues(alpha: 0.6),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: pct),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          builder: (context, animatedValue, child) {
                            return LinearProgressIndicator(
                              value: animatedValue,
                              minHeight: 8,
                              backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                              color: AppColors.primary,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$remaining ${loc.remaining}',
                        style: const TextStyle(color: AppColors.text, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statsPage() => StatsDashboard(
      key: ValueKey(_totalCompleted),
      initial: _initial,
      remaining: _remaining,
      perDay: widget.perDay);

  Widget _settingsPage() => SettingsDashboard(
    initial: _initial,
    remaining: _remaining,
    perDay: widget.perDay,
    onDataChanged: _reloadData,
  );

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _homePage(),
          _statsPage(),
          _settingsPage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: AppColors.secondary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _tabIndex,
          onTap: (i) => setState(() => _tabIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.text.withValues(alpha: 0.6),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
          elevation: 0,
          showUnselectedLabels: true,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: loc.home,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.bar_chart_rounded),
              activeIcon: const Icon(Icons.bar_chart),
              label: loc.stats,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings),
              label: loc.settings,
            ),
          ],
        ),
      ),
    );
  }
}
