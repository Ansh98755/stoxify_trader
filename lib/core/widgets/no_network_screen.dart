import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/color_constants.dart';
import '../constants/text_style_constants.dart';
import '../utils/app_size.dart';

/// Full-screen overlay shown when the device has no network.
/// Uses a deep-space gradient that is visually distinct from every other
/// background in the app (home = navy/blue/green; trades = slate/amber).
/// Dismissed automatically — caller pops it when connectivity returns.
class NoNetworkScreen extends StatefulWidget {
  const NoNetworkScreen({super.key});

  @override
  State<NoNetworkScreen> createState() => _NoNetworkScreenState();
}

class _NoNetworkScreenState extends State<NoNetworkScreen>
    with TickerProviderStateMixin {
  // Slow background gradient shift
  late final AnimationController _gradientCtrl;
  late final Animation<double> _gradientAnim;

  // Pulsing icon glow
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  // Floating vertical drift for the icon
  late final AnimationController _floatCtrl;
  late final Animation<double> _floatAnim;

  // Rotating broken-signal arcs
  late final AnimationController _spinCtrl;
  late final Animation<double> _spinAnim;

  @override
  void initState() {
    super.initState();

    _gradientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _gradientAnim = CurvedAnimation(
      parent: _gradientCtrl,
      curve: Curves.easeInOutSine,
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOutSine),
    );

    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _spinAnim = CurvedAnimation(parent: _spinCtrl, curve: Curves.linear);
  }

  @override
  void dispose() {
    _gradientCtrl.dispose();
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _gradientAnim,
          _pulseAnim,
          _floatAnim,
          _spinAnim,
        ]),
        builder: (context, _) {
          final t = _gradientAnim.value;
          return Stack(
            fit: StackFit.expand,
            children: [
              // ── Animated deep-space gradient background ──────────────────
              _NoNetworkGradient(t: t),

              // ── Slow-rotating decorative orbit rings ─────────────────────
              Positioned.fill(
                child: _OrbitRings(progress: _spinAnim.value),
              ),

              // ── Centre content ────────────────────────────────────────────
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: AppSize.symmetric(context, horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Floating + pulsing icon
                        Transform.translate(
                          offset: Offset(0, _floatAnim.value),
                          child: _GlowIcon(pulse: _pulseAnim.value),
                        ),
                        SizedBox(height: AppSize.h(context, 36)),
                        // Title
                        Text(
                          'No Internet Connection',
                          textAlign: TextAlign.center,
                          style: TextStyleConstants.screenTitle.copyWith(
                            fontSize: AppSize.sp(context, 24),
                            color: ColorConstants.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: AppSize.h(context, 12)),
                        // Sub-text
                        Text(
                          'Check your Wi-Fi or mobile data and we\'ll reconnect automatically.',
                          textAlign: TextAlign.center,
                          style: TextStyleConstants.bodyMedium.copyWith(
                            fontSize: AppSize.sp(context, 14),
                            color: Colors.white.withValues(alpha: 0.65),
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: AppSize.h(context, 40)),
                        // Status pill
                        _StatusPill(pulse: _pulseAnim.value),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Gradient background ────────────────────────────────────────────────────

class _NoNetworkGradient extends StatelessWidget {
  const _NoNetworkGradient({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    // Base: very dark desaturated indigo — completely unlike the light
    // home/trades backgrounds.
    final topColor = Color.lerp(
      const Color(0xFF0B0F1E),
      const Color(0xFF0E1629),
      t,
    )!;
    final midColor = Color.lerp(
      const Color(0xFF141C33),
      const Color(0xFF0F1A2E),
      t,
    )!;
    final bottomColor = Color.lerp(
      const Color(0xFF0D1120),
      const Color(0xFF121828),
      t,
    )!;

    // Accent blobs
    final accentLeft = Color.lerp(
      const Color(0xFF1A3A7A).withValues(alpha: 0.30),
      const Color(0xFF1E4490).withValues(alpha: 0.22),
      t,
    )!;
    final accentRight = Color.lerp(
      const Color(0xFF2C1654).withValues(alpha: 0.25),
      const Color(0xFF3B1D6A).withValues(alpha: 0.18),
      t,
    )!;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [topColor, midColor, bottomColor],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-1.1 + t * 0.4, -0.8 + t * 0.3),
              radius: 0.90,
              colors: [accentLeft, Colors.transparent],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(1.1 - t * 0.4, 0.9 - t * 0.3),
              radius: 0.85,
              colors: [accentRight, Colors.transparent],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Decorative orbit rings ─────────────────────────────────────────────────

class _OrbitRings extends StatelessWidget {
  const _OrbitRings({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: CustomPaint(
          painter: _OrbitRingsPainter(progress: progress),
        ),
      ),
    );
  }
}

class _OrbitRingsPainter extends CustomPainter {
  _OrbitRingsPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.40;

    // Outer ring — slow clockwise
    _drawArc(
      canvas,
      cx: cx,
      cy: cy,
      radius: size.width * 0.52,
      startAngle: progress * 2 * math.pi,
      sweepAngle: math.pi * 1.2,
      color: Colors.white.withValues(alpha: 0.05),
      strokeWidth: 1.0,
    );

    // Middle ring — counter-clockwise, dashed-ish via short sweep
    _drawArc(
      canvas,
      cx: cx,
      cy: cy,
      radius: size.width * 0.36,
      startAngle: -progress * 2 * math.pi * 1.4,
      sweepAngle: math.pi * 0.9,
      color: Colors.white.withValues(alpha: 0.06),
      strokeWidth: 0.8,
    );

    // Inner ring — fast clockwise
    _drawArc(
      canvas,
      cx: cx,
      cy: cy,
      radius: size.width * 0.22,
      startAngle: progress * 2 * math.pi * 1.8,
      sweepAngle: math.pi * 1.5,
      color: const Color(0xFF4F8CFF).withValues(alpha: 0.10),
      strokeWidth: 0.7,
    );
  }

  void _drawArc(
    Canvas canvas, {
    required double cx,
    required double cy,
    required double radius,
    required double startAngle,
    required double sweepAngle,
    required Color color,
    required double strokeWidth,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_OrbitRingsPainter old) => old.progress != progress;
}

// ─── Animated glow icon ─────────────────────────────────────────────────────

class _GlowIcon extends StatelessWidget {
  const _GlowIcon({required this.pulse});

  final double pulse;

  @override
  Widget build(BuildContext context) {
    final glowRadius = AppSize.r(context, 28) * pulse;
    final iconSize = AppSize.r(context, 68);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow halo
        Container(
          width: iconSize + glowRadius * 2.2,
          height: iconSize + glowRadius * 2.2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B6FD4).withValues(alpha: 0.18 * pulse),
                blurRadius: glowRadius * 2.5,
                spreadRadius: glowRadius * 0.5,
              ),
            ],
          ),
        ),
        // Icon container
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF253C72).withValues(alpha: 0.90),
                const Color(0xFF1A2B54).withValues(alpha: 0.95),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10 + 0.08 * pulse),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A5CC8).withValues(alpha: 0.22 * pulse),
                blurRadius: AppSize.r(context, 20),
                offset: Offset(0, AppSize.h(context, 4)),
              ),
            ],
          ),
          child: Icon(
            Icons.wifi_off_rounded,
            size: AppSize.r(context, 32),
            color: Colors.white.withValues(alpha: 0.75 + 0.25 * pulse),
          ),
        ),
      ],
    );
  }
}

// ─── Status pill ────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.pulse});

  final double pulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSize.symmetric(context, horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.r(context, 32)),
        color: Colors.white.withValues(alpha: 0.07),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing dot
          Container(
            width: AppSize.r(context, 7),
            height: AppSize.r(context, 7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEF4444).withValues(alpha: pulse),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444)
                      .withValues(alpha: 0.40 * pulse),
                  blurRadius: AppSize.r(context, 5),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSize.w(context, 8)),
          Text(
            'Waiting for connection…',
            style: TextStyleConstants.caption.copyWith(
              fontSize: AppSize.sp(context, 12),
              color: Colors.white.withValues(alpha: 0.55),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
