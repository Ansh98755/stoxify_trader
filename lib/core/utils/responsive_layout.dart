import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

/// Responsive helpers for web desktop chrome vs mobile/app shell.
///
/// Mobile (iOS/Android) is unchanged. Web switches to desktop shell only when
/// the viewport is wide (typically landscape/desktop); narrow/portrait web
/// keeps the app-style bottom navigation.
abstract final class ResponsiveLayout {
  /// Minimum width to use left nav + multi-column home cards.
  static const double webDesktopMinWidth = 900;

  /// Wide three-column trade grid.
  static const double webWideMinWidth = 1400;

  static bool get isWeb => kIsWeb;

  /// Web + wide enough for desktop chrome (side nav, card grids).
  static bool useWebDesktopShell(BuildContext context) {
    if (!kIsWeb) return false;
    return MediaQuery.sizeOf(context).width >= webDesktopMinWidth;
  }

  /// How many cards per row for trade/discover grids (1 = mobile list).
  static int cardGridColumns(BuildContext context) {
    if (!useWebDesktopShell(context)) return 1;
    final w = MediaQuery.sizeOf(context).width;
    if (w >= webWideMinWidth) return 3;
    return 2;
  }

  @Deprecated('Use cardGridColumns')
  static int homeTradeColumns(BuildContext context) => cardGridColumns(context);

  /// Outer content padding when using the web desktop shell.
  static double contentHorizontalPadding(BuildContext context) {
    return useWebDesktopShell(context) ? 28 : 16;
  }
}
