import 'package:flutter/material.dart';

/// App color constants
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation
  
  /// Gets button text style with bold font weight for Arabic
  static TextStyle buttonTextStyle(BuildContext context, {Color? color}) {
    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';
    return TextStyle(
      color: color,
      fontWeight: isArabic ? FontWeight.bold : FontWeight.normal,
    );
  }

  /// Text color: #070c1d
  static const Color text = Color(0xFF070C1D);

  /// Primary color: #134e2b
  static const Color primary = Color(0xFF134E2B);

  /// Secondary color: #7fc284
  static const Color secondary = Color(0xFF7FC284);

  /// Accent color: #f8e39c
  static const Color accent = Color(0xFFF8E39C);

  /// Creates a styled SnackBar with app colors
  static SnackBar styledSnackBar(String message, {Duration? duration}) {
    return SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      duration: duration ?? const Duration(seconds: 3),
    );
  }
}

