import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Wraps [child] in a [MouseRegion] that shows [SystemMouseCursors.click]
/// on hover. Use on web for any custom [GestureDetector] or tappable widget
/// that doesn't automatically receive the pointer cursor.
///
/// No-op on non-web platforms.
class WebPointer extends StatelessWidget {
  const WebPointer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: child,
    );
  }
}
