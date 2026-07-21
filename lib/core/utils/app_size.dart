import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Central responsive sizing utility for the StoXify app.
///
/// All design measurements are based on the 390 × 844 Figma frame and scale
/// within guarded limits so phones and tablets remain usable.
final class AppSize {
  AppSize._();

  static const double designWidth = 390;
  static const double designHeight = 844;
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  static MediaQueryData mediaQuery(BuildContext context) =>
      MediaQuery.of(context);

  static double screenWidth(BuildContext context) =>
      mediaQuery(context).size.width;

  static double screenHeight(BuildContext context) =>
      mediaQuery(context).size.height;

  static double safeHeight(BuildContext context) {
    final data = mediaQuery(context);
    return data.size.height - data.padding.top - data.padding.bottom;
  }

  static EdgeInsets safePadding(BuildContext context) =>
      mediaQuery(context).padding;

  static double widthScale(BuildContext context) =>
      (screenWidth(context) / designWidth).clamp(0.80, 1.40);

  static double heightScale(BuildContext context) =>
      (screenHeight(context) / designHeight).clamp(0.75, 1.40);

  static double uniformScale(BuildContext context) =>
      math.min(widthScale(context), heightScale(context));

  /// Scales a horizontal Figma measurement.
  static double w(BuildContext context, num value) =>
      value.toDouble() * widthScale(context);

  /// Scales a vertical Figma measurement.
  static double h(BuildContext context, num value) =>
      value.toDouble() * heightScale(context);

  /// Scales radii and square visual elements uniformly.
  static double r(BuildContext context, num value) =>
      value.toDouble() * uniformScale(context);

  /// Scales typography conservatively and keeps system text scaling active.
  static double sp(BuildContext context, num value) {
    final scale = uniformScale(context).clamp(0.90, 1.15);
    return value.toDouble() * scale;
  }

  static EdgeInsets insets(
    BuildContext context, {
    num left = 0,
    num top = 0,
    num right = 0,
    num bottom = 0,
  }) {
    return EdgeInsets.fromLTRB(
      w(context, left),
      h(context, top),
      w(context, right),
      h(context, bottom),
    );
  }

  static EdgeInsets symmetric(
    BuildContext context, {
    num horizontal = 0,
    num vertical = 0,
  }) {
    return EdgeInsets.symmetric(
      horizontal: w(context, horizontal),
      vertical: h(context, vertical),
    );
  }

  static bool isCompact(BuildContext context) =>
      screenWidth(context) < 360 || safeHeight(context) < 700;

  static bool isMobile(BuildContext context) =>
      screenWidth(context) < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = screenWidth(context);
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      screenWidth(context) >= tabletBreakpoint;

  static double maxContentWidth(
    BuildContext context, {
    double mobile = double.infinity,
    double tablet = 600,
    double desktop = 720,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }
}
