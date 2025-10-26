// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Qadaa Tracker';

  @override
  String get qadaaTracker => 'Qadaa Tracker';

  @override
  String get qadaaDescription =>
      'Track and complete your missed prayers with clarity and peace.';

  @override
  String get createMyPlan => 'Create My Plan';

  @override
  String get timePeriod => 'Time Period';

  @override
  String get manualEntry => 'Manual Entry';

  @override
  String get years => 'Years';

  @override
  String get months => 'Months';

  @override
  String get days => 'Days';

  @override
  String get fajr => 'Fajr';

  @override
  String get dhuhr => 'Dhuhr';

  @override
  String get asr => 'Asr';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get isha => 'Isha';

  @override
  String get pleaseEnterValidPeriod => 'Please enter a valid time period.';

  @override
  String get setYourDailyPlan => 'Set Your Daily Plan';

  @override
  String get howManyQadaa =>
      'How many Qadaa prayers can you commit to each day?';

  @override
  String get remaining => 'remaining';

  @override
  String get savePlan => 'Save Plan';

  @override
  String get dailyPlanUpdated => 'Daily plan updated successfully!';

  @override
  String get prayerLogged => 'Prayer logged! 🙌';

  @override
  String get nothingToLog => 'Nothing to log';

  @override
  String prayerCompleted(Object prayer) {
    return '$prayer prayer completed.';
  }

  @override
  String noPrayerRemaining(Object prayer) {
    return 'No $prayer remaining.';
  }

  @override
  String get logQadaaPrayer => 'Log Qadaa Prayer';

  @override
  String get whichPrayer => 'Which prayer did you complete?';

  @override
  String get totalProgress => 'Total Progress';

  @override
  String get complete => 'Complete';

  @override
  String get totalMissed => 'Total Missed';

  @override
  String get totalCompleted => 'Total Completed';

  @override
  String get remainingPrayers => 'Remaining';

  @override
  String get prayerBreakdown => 'Prayer Breakdown';

  @override
  String get home => 'Home';

  @override
  String get stats => 'Stats';

  @override
  String get settings => 'Settings';

  @override
  String get statistics => 'Statistics';

  @override
  String get currentStreak => 'Current Streak';

  @override
  String get completedThisWeek => 'Completed this week';

  @override
  String get weeklyProgress => 'Weekly Progress';

  @override
  String get estimatedFinishDate => 'Estimated Finish Date';

  @override
  String get noDailyPlan => 'No daily plan';

  @override
  String get atCurrentPace => 'At your current pace';

  @override
  String get setDailyPlanToEstimate =>
      'Set a daily plan to estimate finish date';

  @override
  String get january => 'January';

  @override
  String get february => 'February';

  @override
  String get march => 'March';

  @override
  String get april => 'April';

  @override
  String get may => 'May';

  @override
  String get june => 'June';

  @override
  String get july => 'July';

  @override
  String get august => 'August';

  @override
  String get september => 'September';

  @override
  String get october => 'October';

  @override
  String get november => 'November';

  @override
  String get december => 'December';

  @override
  String get sun => 'Sun';

  @override
  String get mon => 'Mon';

  @override
  String get tue => 'Tue';

  @override
  String get wed => 'Wed';

  @override
  String get thu => 'Thu';

  @override
  String get fri => 'Fri';

  @override
  String get sat => 'Sat';

  @override
  String get preferences => 'Preferences';

  @override
  String get currentStatus => 'Current Status';

  @override
  String get completed => 'Completed';

  @override
  String get dailyPlan => 'Daily Plan';

  @override
  String get editPlan => 'Edit Plan';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get resetAllData => 'Reset All Data';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get resetWarning =>
      'This will permanently delete all your data including your progress, plan, and prayer logs.';

  @override
  String get cancel => 'Cancel';

  @override
  String get yesResetEverything => 'Yes, Reset Everything';

  @override
  String get allDataReset => 'All data has been reset.';

  @override
  String get appVersion => 'Qadaa Tracker v1.0';

  @override
  String get barrierDismiss => 'Dismiss';

  @override
  String get resetTitle => 'Are you sure?';

  @override
  String get confirmReset => 'Yes, Reset Everything';

  @override
  String get prayers => 'prayers';

  @override
  String get footerSubtitle =>
      'Track and complete your missed prayers with clarity and peace.';

  @override
  String get perDay => 'per day';

  @override
  String get logout => 'Log Out';

  @override
  String get logoutTitle => 'Log Out';

  @override
  String get logoutWarning => 'Are you sure you want to log out?';

  @override
  String get loggedOut => 'Logged out successfully';

  @override
  String get confirm => 'Confirm';

  @override
  String get signInSubtitle => 'Welcome back! Please log in to continue.';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get signIn => 'Sign In';

  @override
  String get or => 'or';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get signInWelcome => 'Welcome to Qadaa Tracker 👋';

  @override
  String get signInTagline => 'Track your missed prayers effortlessly.';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get noAccount => 'Don’t have an account?';

  @override
  String get signUp => 'Sign Up';

  @override
  String get signUpWelcome => 'Create your Qadaa Tracker account ✨';

  @override
  String get signUpTagline =>
      'Stay on top of your missed prayers with a personalized plan.';

  @override
  String get signUpSubtitle =>
      'Create your account to start tracking your prayers.';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get fillAllFields => 'Please fill all fields';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get accountCreated => 'Account created successfully!';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get emailInUse => 'This email is already in use.';

  @override
  String get weakPassword => 'Password should be at least 6 characters.';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get invalidCredentials => 'Invalid email or password.';

  @override
  String get invalidEmail => 'Invalid email format.';

  @override
  String get accountDisabled => 'This account has been disabled.';

  @override
  String get loginFailed => 'Login failed. Please try again.';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get enterEmailWarning => 'Please enter your email address.';

  @override
  String get resetEmailSent => 'A password reset email has been sent.';

  @override
  String get resetFailed => 'Failed to send reset email. Please try again.';

  @override
  String get emailNotFound => 'No account found with this email.';

  @override
  String get send => 'Send';

  @override
  String get googleSignInFailed => 'Google Sign-In failed';

  @override
  String get appleSignInFailed => 'Apple Sign-In failed';

  @override
  String get google => 'Google';

  @override
  String get apple => 'Apple';

  @override
  String get continueAsGuest => 'Continue as Guest';

  @override
  String get editMissedPrayers => 'Edit Missed Prayers';

  @override
  String get updateMissedPrayers => 'Update Missed Prayers';

  @override
  String get editLogs => 'Edit Logged Prayers';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get finish => 'Finish';

  @override
  String get finished => 'Finished';

  @override
  String get youCannotExceed => 'You cannot exceed the missed prayers count';

  @override
  String get missedPrayersFor => 'missed prayers for';

  @override
  String youAlreadyLoggedAll(Object prayer) {
    return 'You already logged all $prayer prayers ✅';
  }

  @override
  String get youAlreadyLoggedAllDescription =>
      'Shown when user reaches max logged prayers';

  @override
  String get validationError => 'Validation Error';

  @override
  String get validationIntro =>
      'You have completed more prayers than missed for:';

  @override
  String validationFajr(Object completed, Object missed) {
    return 'Fajr: $completed completed but only $missed missed';
  }

  @override
  String validationDhuhr(Object completed, Object missed) {
    return 'Dhuhr: $completed completed but only $missed missed';
  }

  @override
  String validationAsr(Object completed, Object missed) {
    return 'Asr: $completed completed but only $missed missed';
  }

  @override
  String validationMaghrib(Object completed, Object missed) {
    return 'Maghrib: $completed completed but only $missed missed';
  }

  @override
  String validationIsha(Object completed, Object missed) {
    return 'Isha: $completed completed but only $missed missed';
  }

  @override
  String get validationOutro => 'You need to reset your data to proceed.';

  @override
  String get resetData => 'Reset Data';

  @override
  String validationCantExceed(String prayer, String max) {
    return '$prayer can\'t exceed $max';
  }
}
