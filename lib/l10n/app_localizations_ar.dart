// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'متتبع صلوات القضاء';

  @override
  String get qadaaTracker => 'متتبع صلوات القضاء';

  @override
  String get qadaaDescription => 'تتبع وأكمل صلواتك الفائتة بوضوح وطمأنينة.';

  @override
  String get createMyPlan => 'أنشئ خطتي';

  @override
  String get timePeriod => 'فترة زمنية';

  @override
  String get manualEntry => 'إدخال يدوي';

  @override
  String get years => 'سنوات';

  @override
  String get months => 'شهور';

  @override
  String get days => 'أيام';

  @override
  String get fajr => 'الفجر';

  @override
  String get dhuhr => 'الظهر';

  @override
  String get asr => 'العصر';

  @override
  String get maghrib => 'المغرب';

  @override
  String get isha => 'العشاء';

  @override
  String get pleaseEnterValidPeriod => 'الرجاء إدخال فترة زمنية صحيحة.';

  @override
  String get setYourDailyPlan => 'حدد خطتك اليومية';

  @override
  String get howManyQadaa => 'كم صلاة قضاء يمكنك الالتزام بها يوميًا؟';

  @override
  String get remaining => 'متبقية';

  @override
  String get savePlan => 'احفظ الخطة';

  @override
  String get dailyPlanUpdated => 'تم تحديث الخطة اليومية بنجاح!';

  @override
  String get prayerLogged => 'تم تسجيل الصلاة! 🙌';

  @override
  String get nothingToLog => 'لا يوجد شيء لتسجيله';

  @override
  String prayerCompleted(Object prayer) {
    return 'تم إكمال صلاة $prayer.';
  }

  @override
  String noPrayerRemaining(Object prayer) {
    return 'لا توجد صلاة $prayer متبقية.';
  }

  @override
  String get logQadaaPrayer => 'تسجيل صلاة قضاء';

  @override
  String get whichPrayer => 'ما الصلاة التي أكملتها؟';

  @override
  String get totalProgress => 'إجمالي التقدم';

  @override
  String get complete => 'مكتملة';

  @override
  String get totalMissed => 'إجمالي الفوائت';

  @override
  String get totalCompleted => 'إجمالي المكتمل';

  @override
  String get remainingPrayers => 'المتبقية';

  @override
  String get prayerBreakdown => 'تفصيل الصلوات';

  @override
  String get home => 'الرئيسية';

  @override
  String get stats => 'الإحصائيات';

  @override
  String get settings => 'الإعدادات';

  @override
  String get statistics => 'الإحصائيات';

  @override
  String get currentStreak => 'سلسلة الأيام الحالية';

  @override
  String get completedThisWeek => 'المكتملة هذا الأسبوع';

  @override
  String get weeklyProgress => 'التقدم الأسبوعي';

  @override
  String get estimatedFinishDate => 'تاريخ الانتهاء المتوقع';

  @override
  String get noDailyPlan => 'لا توجد خطة يومية';

  @override
  String get atCurrentPace => 'بناءً على وتيرتك الحالية';

  @override
  String get setDailyPlanToEstimate =>
      'قم بتحديد خطة يومية لتقدير تاريخ الانتهاء';

  @override
  String get january => 'يناير';

  @override
  String get february => 'فبراير';

  @override
  String get march => 'مارس';

  @override
  String get april => 'أبريل';

  @override
  String get may => 'مايو';

  @override
  String get june => 'يونيو';

  @override
  String get july => 'يوليو';

  @override
  String get august => 'أغسطس';

  @override
  String get september => 'سبتمبر';

  @override
  String get october => 'أكتوبر';

  @override
  String get november => 'نوفمبر';

  @override
  String get december => 'ديسمبر';

  @override
  String get sun => 'الأحد';

  @override
  String get mon => 'الاثنين';

  @override
  String get tue => 'الثلاثاء';

  @override
  String get wed => 'الأربعاء';

  @override
  String get thu => 'الخميس';

  @override
  String get fri => 'الجمعة';

  @override
  String get sat => 'السبت';

  @override
  String get preferences => 'التفضيلات';

  @override
  String get currentStatus => 'الحالة الحالية';

  @override
  String get completed => 'المكتملة';

  @override
  String get dailyPlan => 'الخطة اليومية';

  @override
  String get editPlan => 'تعديل الخطة';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'الإنجليزية';

  @override
  String get arabic => 'العربية';

  @override
  String get dangerZone => 'منطقة الخطر';

  @override
  String get resetAllData => 'إعادة تعيين جميع البيانات';

  @override
  String get areYouSure => 'هل أنت متأكد؟';

  @override
  String get resetWarning =>
      'سيؤدي هذا إلى حذف جميع بياناتك بما في ذلك التقدم والخطة وسجل الصلوات.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get yesResetEverything => 'نعم، أعد التعيين';

  @override
  String get allDataReset => 'تمت إعادة تعيين جميع البيانات.';

  @override
  String get appVersion => 'متتبع صلوات القضاء الإصدار 1.0';

  @override
  String get barrierDismiss => 'إغلاق';

  @override
  String get resetTitle => 'هل أنت متأكد؟';

  @override
  String get confirmReset => 'نعم، إعادة تعيين الكل';

  @override
  String get prayers => 'صلوات';

  @override
  String get footerSubtitle => 'تابع وأكمل صلواتك الفائتة بوضوح وطمأنينة.';

  @override
  String get perDay => 'يوميًا';
}
