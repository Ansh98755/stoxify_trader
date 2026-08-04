import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/color_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer engine — single AnimationController shared across the whole subtree
// via InheritedWidget so all skeletons animate in perfect sync.
// ─────────────────────────────────────────────────────────────────────────────

class ShimmerScope extends StatefulWidget {
  const ShimmerScope({super.key, required this.child});

  final Widget child;

  static _ShimmerScopeState? _of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_ShimmerInherited>()
        ?._state;
  }

  @override
  State<ShimmerScope> createState() => _ShimmerScopeState();
}

class _ShimmerScopeState extends State<ShimmerScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  Animation<double> get animation => _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ShimmerInherited(state: this, child: widget.child);
  }
}

class _ShimmerInherited extends InheritedWidget {
  const _ShimmerInherited({required _ShimmerScopeState state, required super.child})
      : _state = state;

  final _ShimmerScopeState _state;

  @override
  bool updateShouldNotify(_ShimmerInherited old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// ShimmerBox — the atomic shimmer rectangle/circle.
// Wrap with ShimmerScope above the list; individual boxes read the shared
// animation from context so they animate together.
// ─────────────────────────────────────────────────────────────────────────────

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.isCircle = false,
  });

  final double width;
  final double height;
  final double borderRadius;
  final bool isCircle;

  static const Color _base = Color(0xFFEEEEEE);
  static const Color _highlight = Color(0xFFF5F5F5);
  static const Color _shimmer = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    final state = ShimmerScope._of(context);

    if (state == null) {
      // Fallback when no ShimmerScope ancestor — static placeholder.
      return _box(const AlwaysStoppedAnimation(0.0));
    }

    return AnimatedBuilder(
      animation: state.animation,
      builder: (_, __) => _box(state.animation),
    );
  }

  Widget _box(Animation<double> animation) {
    final t = animation.value;
    // Sweep from -1 → +2 so the glint fully enters and exits the box.
    final sweepOffset = -1.0 + t * 3.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment(sweepOffset - 1, 0),
          end: Alignment(sweepOffset + 1, 0),
          colors: const <Color>[_base, _highlight, _shimmer, _highlight, _base],
          stops: const <double>[0.0, 0.35, 0.5, 0.65, 1.0],
          tileMode: TileMode.clamp,
          transform: _SkewTransform(math.pi / 24),
        ),
      ),
    );
  }
}

/// Applies a very slight skew to the gradient for a realistic glint.
class _SkewTransform extends GradientTransform {
  const _SkewTransform(this.angle);
  final double angle;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.skewX(angle);
  }
}
