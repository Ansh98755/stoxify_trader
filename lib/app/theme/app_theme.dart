import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/color_constants.dart';
import '../../core/constants/text_style_constants.dart';

/// StoXify Brand Identity System — Material theme
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: TextStyleConstants.fontFamilyBody,
      scaffoldBackgroundColor: ColorConstants.pageBackground,
      primaryColor: ColorConstants.brandBlue,
      colorScheme: const ColorScheme.light(
        primary: ColorConstants.brandBlue,
        onPrimary: ColorConstants.white,
        secondary: ColorConstants.brandBlueLight,
        onSecondary: ColorConstants.white,
        surface: ColorConstants.white,
        onSurface: ColorConstants.ink,
        error: ColorConstants.red,
        onError: ColorConstants.white,
        outline: ColorConstants.line,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: ColorConstants.pageBackground,
        foregroundColor: ColorConstants.navy,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyleConstants.screenTitle,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyleConstants.displayLarge,
        displayMedium: TextStyleConstants.display,
        displaySmall: TextStyleConstants.displaySmall,
        headlineLarge: TextStyleConstants.screenTitleLarge,
        headlineMedium: TextStyleConstants.screenTitle,
        headlineSmall: TextStyleConstants.sectionHeader,
        titleLarge: TextStyleConstants.cardTitleLarge,
        titleMedium: TextStyleConstants.cardTitle,
        titleSmall: TextStyleConstants.cardTitleSmall,
        bodyLarge: TextStyleConstants.bodyLarge,
        bodyMedium: TextStyleConstants.body,
        bodySmall: TextStyleConstants.caption,
        labelLarge: TextStyleConstants.bodyMedium,
        labelMedium: TextStyleConstants.caption,
        labelSmall: TextStyleConstants.caption,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.brandBlue,
          foregroundColor: ColorConstants.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyleConstants.buttonLarge,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorConstants.ink,
          side: const BorderSide(color: ColorConstants.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyleConstants.buttonMedium.copyWith(
            color: ColorConstants.ink,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColorConstants.brandBlue,
          textStyle: TextStyleConstants.link,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorConstants.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ColorConstants.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ColorConstants.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: ColorConstants.brandBlue, width: 1.5),
        ),
        hintStyle: TextStyleConstants.bodyMedium.copyWith(
          color: ColorConstants.soft,
        ),
      ),
      cardTheme: CardThemeData(
        color: ColorConstants.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: ColorConstants.line),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: ColorConstants.line,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ColorConstants.white,
        selectedItemColor: ColorConstants.brandBlue,
        unselectedItemColor: ColorConstants.gray900,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyleConstants.labelSmall,
        unselectedLabelStyle: TextStyleConstants.labelSmall,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ColorConstants.white,
        selectedColor: ColorConstants.brandBlue,
        disabledColor: ColorConstants.gray50,
        labelStyle: TextStyleConstants.labelMedium,
        secondaryLabelStyle: TextStyleConstants.labelMedium.copyWith(
          color: ColorConstants.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: const BorderSide(color: ColorConstants.line),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ColorConstants.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: TextStyleConstants.headlineSmall,
        contentTextStyle: TextStyleConstants.bodyMedium,
      ),
    );

    if (!kIsWeb) return base;

    // ── Web-specific overrides ──────────────────────────────────────────────
    // Show pointer cursor for all interactive widgets so the app feels
    // native to browser users. Also make the scrollbar always visible.
    return base.copyWith(
      scrollbarTheme: const ScrollbarThemeData(
        thumbVisibility: WidgetStatePropertyAll(true),
        thickness: WidgetStatePropertyAll(6),
        radius: Radius.circular(4),
      ),
    );
  }
}
