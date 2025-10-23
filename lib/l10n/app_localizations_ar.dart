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

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get logoutTitle => 'تأكيد تسجيل الخروج';

  @override
  String get logoutWarning => 'هل أنت متأكد أنك تريد تسجيل الخروج من الحساب؟';

  @override
  String get loggedOut => 'تم تسجيل الخروج بنجاح';

  @override
  String get confirm => 'تأكيد';

  @override
  String get signInSubtitle => 'مرحباً بعودتك! يرجى تسجيل الدخول للمتابعة.';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get or => 'أو';

  @override
  String get forgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get noAccount => 'ليس لديك حساب؟';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get signUpSubtitle => 'أنشئ حسابك لبدء تتبع صلواتك.';

  @override
  String get firstName => 'الاسم الأول';

  @override
  String get lastName => 'اسم العائلة';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get fillAllFields => 'يرجى ملء جميع الحقول';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get accountCreated => 'تم إنشاء الحساب بنجاح!';

  @override
  String get somethingWentWrong => 'حدث خطأ ما';

  @override
  String get emailInUse => 'هذا البريد الإلكتروني مستخدم بالفعل.';

  @override
  String get weakPassword => 'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل.';

  @override
  String get alreadyHaveAccount => 'هل لديك حساب بالفعل؟';

  @override
  String get invalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get invalidEmail => 'تنسيق البريد الإلكتروني غير صالح.';

  @override
  String get accountDisabled => 'تم تعطيل هذا الحساب.';

  @override
  String get loginFailed => 'فشل تسجيل الدخول. يرجى المحاولة مرة أخرى.';

  @override
  String get resetPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get enterEmailWarning => 'يرجى إدخال بريدك الإلكتروني.';

  @override
  String get resetEmailSent =>
      'تم إرسال رسالة لإعادة تعيين كلمة المرور إلى بريدك الإلكتروني.';

  @override
  String get resetFailed => 'فشل في إرسال رسالة إعادة التعيين. حاول مرة أخرى.';

  @override
  String get emailNotFound => 'لم يتم العثور على حساب بهذا البريد الإلكتروني.';

  @override
  String get send => 'إرسال';

  @override
  String get googleSignInFailed => 'فشل تسجيل الدخول بجوجل';

  @override
  String get appleSignInFailed => 'فشل تسجيل الدخول بآبل';

  @override
  String get google => 'جوجل';

  @override
  String get apple => 'آبل';

  @override
  String get continueAsGuest => 'المتابعة كضيف';

  @override
  String get editMissedPrayers => 'تعديل الصلوات الفائتة';

  @override
  String get updateMissedPrayers => 'تحديث الصلوات الفائتة';

  @override
  String get editLogs => 'تعديل الصلوات المنجزة';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get finish => 'تنتهي';

  @override
  String get youCannotExceed => 'لا يمكنك تجاوز عدد الصلوات الفائتة';

  @override
  String get missedPrayersFor => 'الصلوات الفائتة لـ';

  @override
  String youAlreadyLoggedAll(Object prayer) {
    return 'لقد قمت بتسجيل جميع صلوات $prayer الفائتة ✅';
  }

  @override
  String get youAlreadyLoggedAllDescription =>
      'تظهر عندما يُسجل المستخدم كل الصلوات الفائتة';

  @override
  String get validationError => 'خطأ في التحقق';

  @override
  String get validationIntro => 'لقد أكملت صلوات أكثر مما فاتك في:';

  @override
  String validationFajr(Object completed, Object missed) {
    return 'الفجر: تم إكمال $completed بينما عدد الفوائت $missed';
  }

  @override
  String validationDhuhr(Object completed, Object missed) {
    return 'الظهر: تم إكمال $completed بينما عدد الفوائت $missed';
  }

  @override
  String validationAsr(Object completed, Object missed) {
    return 'العصر: تم إكمال $completed بينما عدد الفوائت $missed';
  }

  @override
  String validationMaghrib(Object completed, Object missed) {
    return 'المغرب: تم إكمال $completed بينما عدد الفوائت $missed';
  }

  @override
  String validationIsha(Object completed, Object missed) {
    return 'العشاء: تم إكمال $completed بينما عدد الفوائت $missed';
  }

  @override
  String get validationOutro => 'يجب عليك إعادة ضبط البيانات للمتابعة.';

  @override
  String get resetData => 'إعادة تعيين البيانات';
}
