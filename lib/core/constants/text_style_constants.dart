import 'package:flutter/material.dart';

import 'color_constants.dart';

/// StoXify Brand Identity System — typography
/// Manrope: display / titles · Inter: body / caption / numeric
class TextStyleConstants {
  TextStyleConstants._();

  static const String fontFamilyDisplay = 'Manrope';
  static const String fontFamilyBody = 'Inter';

  /// @deprecated Use [fontFamilyDisplay] or [fontFamilyBody]
  static const String fontFamily = fontFamilyDisplay;

  // ——— Display — Manrope Bold · 32–40 ———
  static const TextStyle display = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontWeight: FontWeight.w700,
    fontSize: 36,
    height: 1.15,
    letterSpacing: -0.5,
    color: ColorConstants.navy,
  );

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontWeight: FontWeight.w700,
    fontSize: 40,
    height: 1.15,
    letterSpacing: -0.5,
    color: ColorConstants.navy,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontWeight: FontWeight.w700,
    fontSize: 32,
    height: 1.2,
    letterSpacing: -0.4,
    color: ColorConstants.navy,
  );

  // ——— Screen title — Manrope SemiBold · 24–28 ———
  static const TextStyle screenTitle = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 26,
    height: 1.25,
    letterSpacing: -0.3,
    color: ColorConstants.navy,
  );

  static const TextStyle screenTitleLarge = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 28,
    height: 1.25,
    letterSpacing: -0.3,
    color: ColorConstants.navy,
  );

  static const TextStyle screenTitleSmall = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 24,
    height: 1.3,
    letterSpacing: -0.2,
    color: ColorConstants.navy,
  );

  // ——— Section header — Manrope SemiBold · 20 ———
  static const TextStyle sectionHeader = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    height: 1.3,
    color: ColorConstants.navy,
  );

  // ——— Card title — Manrope SemiBold · 16–18 ———
  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 17,
    height: 1.35,
    color: ColorConstants.navy,
  );

  static const TextStyle cardTitleLarge = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 1.35,
    color: ColorConstants.navy,
  );

  static const TextStyle cardTitleSmall = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 1.35,
    color: ColorConstants.navy,
  );

  // ——— Body — Inter Regular · 14–15 ———
  static const TextStyle body = TextStyle(
    fontFamily: fontFamilyBody,
    fontWeight: FontWeight.w400,
    fontSize: 14.5,
    height: 1.5,
    color: ColorConstants.mute,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamilyBody,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 1.5,
    color: ColorConstants.mute,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamilyBody,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 1.5,
    color: ColorConstants.mute,
  );

  // ——— Body medium — Inter Medium · 14 ———
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamilyBody,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 1.45,
    color: ColorConstants.mute,
  );

  // ——— Caption / meta — Inter Regular · 12 ———
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamilyBody,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 1.4,
    color: ColorConstants.soft,
  );

  // ——— Numeric / data — Inter Medium · tabular · 14–16 ———
  static const TextStyle numeric = TextStyle(
    fontFamily: fontFamilyBody,
    fontWeight: FontWeight.w500,
    fontSize: 15,
    height: 1.35,
    fontFeatures: [FontFeature.tabularFigures()],
    color: ColorConstants.ink,
  );

  static const TextStyle numericLarge = TextStyle(
    fontFamily: fontFamilyBody,
    fontWeight: FontWeight.w500,
    fontSize: 16,
    height: 1.35,
    fontFeatures: [FontFeature.tabularFigures()],
    color: ColorConstants.ink,
  );

  static const TextStyle numericSmall = TextStyle(
    fontFamily: fontFamilyBody,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 1.35,
    fontFeatures: [FontFeature.tabularFigures()],
    color: ColorConstants.ink,
  );

  static const TextStyle numericProfit = TextStyle(
    fontFamily: fontFamilyBody,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 1.35,
    fontFeatures: [FontFeature.tabularFigures()],
    color: ColorConstants.green,
  );

  static const TextStyle numericLoss = TextStyle(
    fontFamily: fontFamilyBody,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 1.35,
    fontFeatures: [FontFeature.tabularFigures()],
    color: ColorConstants.red,
  );

  // ——— Material TextTheme aliases (map brand roles → M3 slots) ———
  static const TextStyle displayMedium = display;
  static const TextStyle headlineLarge = sectionHeader;
  static const TextStyle headlineMedium = screenTitle;
  static const TextStyle headlineSmall = cardTitleLarge;
  static const TextStyle titleLarge = cardTitle;
  static const TextStyle titleMedium = cardTitleSmall;
  static const TextStyle titleSmall = cardTitleSmall;
  static const TextStyle labelLarge = bodyMedium;
  static const TextStyle labelMedium = caption;
  static const TextStyle labelSmall = caption;

  // ——— Buttons (UI chrome — Manrope SemiBold) ———
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 1.2,
    color: ColorConstants.white,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 1.2,
    color: ColorConstants.white,
  );

  static const TextStyle link = TextStyle(
    fontFamily: fontFamilyBody,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 1.35,
    color: ColorConstants.brandBlue,
  );
}
