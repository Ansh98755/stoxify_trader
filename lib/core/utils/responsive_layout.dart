import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

/// Width at which web switches from the mobile shell (bottom nav, 1 column)
/// to the desktop shell (side drawer, 2-column cards).
const double kDesktopWebBreakpoint = 900;

/// True only on wide web viewports. Phone browsers must use the native-style
/// mobile layout even when [kIsWeb] is true.
bool isDesktopWeb(BuildContext context) {
  if (!kIsWeb) return false;
  return MediaQuery.sizeOf(context).width >= kDesktopWebBreakpoint;
}
