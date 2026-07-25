import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/asset_constants.dart';
import '../constants/color_constants.dart';
import '../utils/app_size.dart';

enum AppScreenBackgroundVariant {
  /// Default Home / Discover atmosphere (navy → blue → soft green).
  home,

  /// Trades atmosphere — cooler slate mist with amber market accents.
  trades,
}

/// Shared atmospheric backdrop used by main tabs (Home, Discover, Trades…).
class AppScreenBackground extends StatelessWidget {
  const AppScreenBackground({
    super.key,
    this.variant = AppScreenBackgroundVariant.home,
  });

  final AppScreenBackgroundVariant variant;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Positioned.fill(child: _AppGradientBackground(variant: variant)),
        Positioned.fill(child: _AnimatedBackgroundIcons(variant: variant)),
      ],
    );
  }
}

class _AppGradientBackground extends StatelessWidget {
  const _AppGradientBackground({required this.variant});

  final AppScreenBackgroundVariant variant;

  @override
  Widget build(BuildContext context) {
    if (variant == AppScreenBackgroundVariant.trades) {
      return const _TradesGradientBackground();
    }
    return const _HomeGradientBackground();
  }
}

class _HomeGradientBackground extends StatelessWidget {
  const _HomeGradientBackground();

  @override
  Widget build(BuildContext context) {
    final navyAtmosphere = Color.lerp(
      ColorConstants.white,
      ColorConstants.navy,
      0.16,
    )!;
    final blueAtmosphere = Color.lerp(
      ColorConstants.white,
      ColorConstants.brandBlue,
      0.13,
    )!;
    final blueSurface = Color.lerp(
      ColorConstants.pageBackground,
      ColorConstants.brandBlueLight,
      0.045,
    )!;
    final profitSurface = Color.lerp(
      ColorConstants.white,
      ColorConstants.green,
      0.04,
    )!;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const <double>[0, 0.20, 0.48, 0.76, 1],
              colors: <Color>[
                navyAtmosphere,
                blueAtmosphere,
                blueSurface,
                ColorConstants.pageBackground,
                profitSurface,
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.92, -0.96),
              radius: 0.86,
              stops: const <double>[0, 0.48, 1],
              colors: <Color>[
                ColorConstants.brandBlueLight.withValues(alpha: 0.14),
                ColorConstants.brandBlue.withValues(alpha: 0.045),
                ColorConstants.transparent,
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-1.05, 1.0),
              radius: 0.95,
              stops: const <double>[0, 0.56, 1],
              colors: <Color>[
                ColorConstants.green.withValues(alpha: 0.045),
                ColorConstants.profitBg.withValues(alpha: 0.10),
                ColorConstants.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TradesGradientBackground extends StatelessWidget {
  const _TradesGradientBackground();

  @override
  Widget build(BuildContext context) {
    final slateMist = Color.lerp(
      ColorConstants.white,
      ColorConstants.navyDark,
      0.10,
    )!;
    final coolInk = Color.lerp(
      ColorConstants.pageBackground,
      ColorConstants.navy,
      0.07,
    )!;
    final iceSurface = Color.lerp(
      ColorConstants.white,
      ColorConstants.brandBlueLight,
      0.06,
    )!;
    final warmFloor = Color.lerp(
      ColorConstants.pageBackground,
      ColorConstants.amber,
      0.035,
    )!;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const <double>[0, 0.28, 0.58, 0.82, 1],
              colors: <Color>[
                slateMist,
                coolInk,
                iceSurface,
                ColorConstants.pageBackground,
                warmFloor,
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.85, -0.92),
              radius: 0.92,
              stops: const <double>[0, 0.5, 1],
              colors: <Color>[
                ColorConstants.amber.withValues(alpha: 0.10),
                ColorConstants.warnBg.withValues(alpha: 0.12),
                ColorConstants.transparent,
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(1.05, 0.15),
              radius: 0.88,
              stops: const <double>[0, 0.52, 1],
              colors: <Color>[
                ColorConstants.brandBlue.withValues(alpha: 0.10),
                ColorConstants.brandBlueLight.withValues(alpha: 0.05),
                ColorConstants.transparent,
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.0, 1.15),
              radius: 0.9,
              stops: const <double>[0, 0.55, 1],
              colors: <Color>[
                ColorConstants.navy.withValues(alpha: 0.04),
                ColorConstants.liveBg.withValues(alpha: 0.18),
                ColorConstants.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedBackgroundIcons extends StatefulWidget {
  const _AnimatedBackgroundIcons({required this.variant});

  final AppScreenBackgroundVariant variant;

  @override
  State<_AnimatedBackgroundIcons> createState() =>
      _AnimatedBackgroundIconsState();
}

class _AnimatedBackgroundIconsState extends State<_AnimatedBackgroundIcons>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
    _floatAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTrades = widget.variant == AppScreenBackgroundVariant.trades;
    final primaryTint =
        isTrades ? ColorConstants.amber : ColorConstants.brandBlue;
    final secondaryTint =
        isTrades ? ColorConstants.brandBlue : ColorConstants.green;

    return IgnorePointer(
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return AnimatedBuilder(
              animation: _floatAnimation,
              builder: (BuildContext context, Widget? child) {
                final progress = _floatAnimation.value;
                final motion = (progress - 0.5) * 2;

                return Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Positioned(
                      top:
                          (constraints.maxHeight * (isTrades ? 0.18 : 0.23)) +
                          (AppSize.h(context, 18) * motion),
                      right: AppSize.w(context, isTrades ? 28 : 55),
                      child: Transform.rotate(
                        angle: motion * math.pi / 180,
                        child: Opacity(
                          opacity: isTrades ? 0.08 : 0.1,
                          child: Image.asset(
                            AssetConstants.homeBackgroundTrading,
                            width: AppSize.w(context, isTrades ? 118 : 124),
                            height: AppSize.w(context, isTrades ? 118 : 124),
                            fit: BoxFit.contain,
                            color: primaryTint,
                            colorBlendMode: BlendMode.srcIn,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top:
                          (constraints.maxHeight * (isTrades ? 0.68 : 0.62)) -
                          (AppSize.h(context, 18) * motion),
                      left: AppSize.w(context, isTrades ? 18 : 25),
                      child: Transform.rotate(
                        angle: -motion * 0.8 * math.pi / 180,
                        child: Opacity(
                          opacity: isTrades ? 0.07 : 0.1,
                          child: Image.asset(
                            AssetConstants.homeBackgroundProfit,
                            width: AppSize.w(context, isTrades ? 100 : 108),
                            height: AppSize.w(context, isTrades ? 100 : 108),
                            fit: BoxFit.contain,
                            color: secondaryTint,
                            colorBlendMode: BlendMode.srcIn,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
