import 'package:qadaa_prayer_tracker/models/daily_totals.dart';

enum AuthTarget { qadaaSetup, homeDashboard }

class AuthFlowResult {
  final AuthTarget target;
  final DailyTotals? totals;
  final Map<String, int>? perDay;

  const AuthFlowResult._(this.target, {this.totals, this.perDay});

  const AuthFlowResult.qadaaSetup() : this._(AuthTarget.qadaaSetup);

  const AuthFlowResult.dashboard({
    required DailyTotals totals,
    Map<String, int>? perDay,
  }) : this._(AuthTarget.homeDashboard, totals: totals, perDay: perDay);
}
