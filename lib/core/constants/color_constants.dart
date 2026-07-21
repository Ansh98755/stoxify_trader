import 'package:flutter/material.dart';

/// StoXify Brand Identity System — color tokens
class ColorConstants {
  ColorConstants._();

  // ——— Brand core ———
  static const Color navy = Color(0xFF081F4D);
  static const Color navyDark = Color(0xFF0B1220);
  static const Color brandBlue = Color(0xFF1A5CC8);
  static const Color brandBlueLight = Color(0xFF4F8CFF);

  // ——— Surfaces ———
  static const Color pageBackground = Color(0xFFF9FAFB);
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray900 = Color(0xFF111827);

  // ——— Text ———
  static const Color ink = Color(0xFF081F4D);
  static const Color mute = Color(0xFF5B6B84);
  static const Color soft = Color(0xFF8B95A5);

  // ——— Semantic ———
  static const Color green = Color(0xFF16A34A);
  static const Color red = Color(0xFFDC2626);
  static const Color amber = Color(0xFFD97706);

  // ——— Borders & dividers ———
  static const Color line = Color(0xFFE5E7EB);

  // ——— Status / risk ———
  static const Color riskLowBg = Color(0xFFEFF6FF);
  static const Color riskMediumBg = Color(0xFFFFFBEB);
  static const Color riskHighBg = Color(0xFFFEF2F2);
  static const Color profitBg = Color(0xFFDCFCE7);
  static const Color lossBg = Color(0xFFFEE2E2);
  static const Color liveBg = Color(0xFFEFF6FF);
  static const Color warnBg = Color(0xFFFFFBEB);

  // ——— Gradients (start / end) ———
  static const Color gradientBlueStart = Color(0xFF1A5CC8);
  static const Color gradientBlueEnd = Color(0xFF4F8CFF);
  static const Color gradientNavyStart = Color(0xFF0A1628);
  static const Color gradientNavyEnd = Color(0xFF103247);
  static const Color gradientSignalStart = Color(0xFFB45309);
  static const Color gradientSignalEnd = Color(0xFFF59E0B);
  static const Color gradientEquityStart = Color(0xFF0369A1);
  static const Color gradientEquityEnd = Color(0xFF38BDF8);

  // ——— Overlay ———
  static const Color scrim = Color(0x70101828);
  static const Color transparent = Color(0x00000000);
  static const Color loginBackground = Color(0xFFF9FAFB);
}
