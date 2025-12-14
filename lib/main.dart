import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:qadaa_prayer_tracker/l10n/app_localizations.dart';
import 'package:qadaa_prayer_tracker/views/registration/auth_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Load saved language before running app
  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString('language_code') ?? 'ar';
  runApp(MyApp(initialLang: savedLang));
}

class MyApp extends StatefulWidget {
  final String initialLang;

  const MyApp({super.key, this.initialLang = 'ar'});

  static void setLocale(BuildContext context, Locale newLocale) {
    final _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?._changeLanguage(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = Locale(widget.initialLang);
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString('language_code');
    if (savedLocale != null) {
      setState(() => _locale = Locale(savedLocale));
    }
  }

  void _changeLanguage(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    // Choose font based on locale: Araboto for Arabic, Roboto for English
    final isArabic = _locale.languageCode == 'ar';
    final baseTextTheme = isArabic
        ? ThemeData.light().textTheme.apply(fontFamily: 'Araboto')
        : GoogleFonts.robotoTextTheme();
    
    // Make all text bold for Arabic
    final textTheme = isArabic
        ? baseTextTheme.apply(
            bodyColor: baseTextTheme.bodyLarge?.color,
            displayColor: baseTextTheme.displayLarge?.color,
            decorationColor: baseTextTheme.bodyLarge?.color,
          ).copyWith(
            displayLarge: baseTextTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold),
            displayMedium: baseTextTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
            displaySmall: baseTextTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
            headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
            headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            headlineSmall: baseTextTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            titleLarge: baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            titleMedium: baseTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            titleSmall: baseTextTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            bodySmall: baseTextTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            labelLarge: baseTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            labelMedium: baseTextTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
            labelSmall: baseTextTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
          )
        : baseTextTheme;
    
    // Make button text bold for Arabic
    final buttonTextStyle = TextStyle(
      fontWeight: isArabic ? FontWeight.bold : FontWeight.normal,
    );
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        textTheme: textTheme,
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: buttonTextStyle,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            textStyle: buttonTextStyle,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: buttonTextStyle,
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}