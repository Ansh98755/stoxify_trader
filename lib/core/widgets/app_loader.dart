import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/color_constants.dart';

/// StoXify app loader — simple orbiting dots.
///
/// Quiet monochrome trail, small dots, no glow/pulse chrome.
///
/// ```dart
/// const AppLoader()
/// AppLoader(size: 48)
/// AppLoader(showBackground: false)
/// ```
class AppLoader extends StatefulWidget {
  const AppLoader({
    super.key,
    this.size = 48.0,
    this.dotColor = ColorConstants.ink,
    this.backgroundColor = ColorConstants.white,
    this.showBackground = false,
  });

  /// Overall diameter.
  final double size;

  /// Dot colour (opacity still fades along the trail).
  final Color dotColor;

  /// Optional soft disc behind the ring.
  final Color backgroundColor;

  /// Off by default for a cleaner look.
  final bool showBackground;

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, _) {
          return CustomPaint(
            painter: _AppLoaderPainter(
              progress: _controller.value,
              showBackground: widget.showBackground,
              backgroundColor: widget.backgroundColor,
              dotColor: widget.dotColor,
            ),
          );
        },
      ),
    );
  }
}

class _AppLoaderPainter extends CustomPainter {
  const _AppLoaderPainter({
    required this.progress,
    required this.showBackground,
    required this.backgroundColor,
    required this.dotColor,
  });

  final double progress;
  final bool showBackground;
  final Color backgroundColor;
  final Color dotColor;

  static const int _dotCount = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double orbitR = size.width * 0.34;
    // Small sober dots — ~4% of diameter for the leader.
    final double maxDotR = size.width * 0.04;

    if (showBackground) {
      canvas.drawCircle(
        Offset(cx, cy),
        size.width / 2,
        Paint()..color = backgroundColor,
      );
    }

    // Faint guide ring.
    canvas.drawCircle(
      Offset(cx, cy),
      orbitR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = ColorConstants.line,
    );

    // Tail first, leader last so head sits on top.
    for (int i = _dotCount - 1; i >= 0; i--) {
      final double phaseOffset = i / _dotCount;
      final double angle =
          (progress - phaseOffset) * 2 * math.pi - math.pi / 2;
      final double x = cx + orbitR * math.cos(angle);
      final double y = cy + orbitR * math.sin(angle);

      final double t = i / (_dotCount - 1);
      final double sizeFactor = math.max(0.35, 1.0 - t * 0.55);
      final double opacity = math.max(0.18, 1.0 - t * 0.82);

      canvas.drawCircle(
        Offset(x, y),
        maxDotR * sizeFactor,
        Paint()..color = dotColor.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_AppLoaderPainter old) =>
      old.progress != progress ||
      old.showBackground != showBackground ||
      old.backgroundColor != backgroundColor ||
      old.dotColor != dotColor;
}

/// Full-screen loading overlay with a light barrier and compact loader.
///
/// ```dart
/// if (isLoading) const AppLoaderOverlay(),
/// ```
class AppLoaderOverlay extends StatelessWidget {
  const AppLoaderOverlay({
    super.key,
    this.loaderSize = 44.0,
    this.barrierOpacity = 0.28,
  });

  final double loaderSize;
  final double barrierOpacity;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ColorConstants.ink.withValues(alpha: barrierOpacity),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ColorConstants.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: ColorConstants.shadowSoft.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: AppLoader(
              size: loaderSize,
              showBackground: false,
            ),
          ),
        ),
      ),
    );
  }
}
