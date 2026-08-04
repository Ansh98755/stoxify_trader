import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/color_constants.dart';

/// StoXify animated app loader.
///
/// A circular arrangement of dots that orbit, trail, and glow with
/// brandBlue / navy / white accents — no external packages required.
///
/// Usage:
/// ```dart
/// const AppLoader()                        // default 80 × 80
/// AppLoader(size: 120)                     // bigger
/// AppLoader(showBackground: false)         // transparent bg
/// ```
class AppLoader extends StatefulWidget {
  const AppLoader({
    super.key,
    this.size = 80.0,
    this.backgroundColor = ColorConstants.navy,
    this.showBackground = true,
  });

  /// Overall widget diameter (dots are sized proportionally).
  final double size;

  /// Background circle colour.
  final Color backgroundColor;

  /// Whether to paint the circular disc behind the dots.
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
      duration: const Duration(milliseconds: 1800),
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
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painter
// ─────────────────────────────────────────────────────────────────────────────

class _AppLoaderPainter extends CustomPainter {
  const _AppLoaderPainter({
    required this.progress,
    required this.showBackground,
    required this.backgroundColor,
  });

  final double progress;
  final bool showBackground;
  final Color backgroundColor;

  static const int _dotCount = 10;

  // Colour palette cycles across the dot trail.
  static const List<Color> _palette = <Color>[
    ColorConstants.brandBlue,  // leader — vivid blue
    Color(0xFF4F8CFF),          // lighter blue
    ColorConstants.white,       // white flash
    Color(0xFF8AB4FF),          // soft periwinkle
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double orbitR = size.width * 0.36;
    final double maxDotR = size.width * 0.072;

    if (showBackground) _paintBackground(canvas, cx, cy, size.width / 2);
    _paintTrack(canvas, cx, cy, orbitR);
    for (int i = _dotCount - 1; i >= 0; i--) {
      // Paint tail-first so leader renders on top.
      _paintDot(canvas, i, cx, cy, orbitR, maxDotR);
    }
    _paintCenter(canvas, cx, cy, size.width);
  }

  void _paintBackground(Canvas canvas, double cx, double cy, double r) {
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = backgroundColor);

    // Subtle radial depth overlay.
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            ColorConstants.brandBlue.withValues(alpha: 0.18),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
    );
  }

  void _paintTrack(Canvas canvas, double cx, double cy, double r) {
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = ColorConstants.brandBlue.withValues(alpha: 0.18),
    );
  }

  void _paintDot(Canvas canvas, int i, double cx, double cy,
      double orbitR, double maxDotR) {
    final double phaseOffset = i / _dotCount;
    final double angle =
        (progress - phaseOffset) * 2 * math.pi - math.pi / 2;

    final double x = cx + orbitR * math.cos(angle);
    final double y = cy + orbitR * math.sin(angle);

    // Leader is biggest; tail shrinks to 25 %.
    final double sizeFactor =
        math.max(0.25, 1.0 - i / (_dotCount - 1) * 0.75);
    final double dotR = maxDotR * sizeFactor;

    // Leader is fully opaque; tail fades to 12 %.
    final double opacity =
        math.max(0.12, 1.0 - i / (_dotCount - 1) * 0.88);

    final Color baseColor = _palette[i % _palette.length];

    // Glow halo on the first 3 dots.
    if (i < 3) {
      final double glowR = dotR * (2.2 - i * 0.3);
      final double glowAlpha = opacity * 0.25 * (1.0 - i * 0.25);
      canvas.drawCircle(
        Offset(x, y),
        glowR,
        Paint()
          ..color = ColorConstants.brandBlue.withValues(alpha: glowAlpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowR * 0.8),
      );
    }

    // Main dot.
    canvas.drawCircle(
      Offset(x, y),
      dotR,
      Paint()..color = baseColor.withValues(alpha: opacity),
    );

    // Specular highlight on the leader only.
    if (i == 0) {
      canvas.drawCircle(
        Offset(x - dotR * 0.28, y - dotR * 0.28),
        dotR * 0.32,
        Paint()..color = ColorConstants.white.withValues(alpha: 0.75),
      );
    }
  }

  void _paintCenter(Canvas canvas, double cx, double cy, double size) {
    final double innerR = size * 0.14;
    final double pulseScale = 1.0 + 0.18 * math.sin(progress * 2 * math.pi);

    // Outer pulse halo.
    canvas.drawCircle(
      Offset(cx, cy),
      innerR * pulseScale * 1.55,
      Paint()
        ..color = ColorConstants.brandBlue.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Inner gradient disc.
    canvas.drawCircle(
      Offset(cx, cy),
      innerR,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[
            ColorConstants.brandBlue,
            ColorConstants.navy,
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: innerR),
        ),
    );

    // White centre dot.
    canvas.drawCircle(
      Offset(cx, cy),
      innerR * 0.32,
      Paint()..color = ColorConstants.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_AppLoaderPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-screen overlay variant
// ─────────────────────────────────────────────────────────────────────────────

/// Drop this anywhere to show a full-screen loading overlay.
///
/// ```dart
/// if (isLoading) const AppLoaderOverlay(),
/// ```
class AppLoaderOverlay extends StatelessWidget {
  const AppLoaderOverlay({
    super.key,
    this.loaderSize = 88.0,
    this.barrierOpacity = 0.55,
  });

  final double loaderSize;
  final double barrierOpacity;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ColorConstants.navy.withValues(alpha: barrierOpacity),
      child: Center(
        child: AppLoader(size: loaderSize),
      ),
    );
  }
}
