import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/asset_constants.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/bottom_navbar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentNavbarIndex = 0;
  final bool _hasUnreadNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: ColorConstants.transparent,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: _HomeGradientBackground()),
          const Positioned.fill(child: _AnimatedHomeBackgroundIcons()),
          SafeArea(
            child: Padding(
              padding: AppSize.insets(
                context,
                left: 16,
                top: 8,
                right: 16,
                bottom: 104,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Hi, Ayush',
                          style: TextStyleConstants.screenTitle.copyWith(
                            fontSize: AppSize.sp(context, 26),
                          ),
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 46,
                        decoration: BoxDecoration(
                          color: ColorConstants.white,
                          border: Border.all(color: ColorConstants.line),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          onPressed: () {},
                          tooltip: 'Notifications',
                          icon: Stack(
                            clipBehavior: Clip.none,
                            children: <Widget>[
                              Image.asset(
                                AssetConstants.notificationIcon,
                                width: AppSize.r(context, 26),
                                height: AppSize.r(context, 26),
                                fit: BoxFit.contain,
                              ),
                              if (_hasUnreadNotifications)
                                Positioned(
                                  top: -3,
                                  right: 2,
                                  child: Container(
                                    width: AppSize.r(context, 12),
                                    height: AppSize.r(context, 12),
                                    decoration: BoxDecoration(
                                      color: ColorConstants.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: ColorConstants.white,
                                        width: AppSize.r(context, 1.5),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSize.h(context, 4)),
                  Text(
                    'Live ideas from analysts you subscribe to',
                    style: TextStyleConstants.caption.copyWith(
                      fontSize: AppSize.sp(context, 12),
                    ),
                  ),
                  SizedBox(height: AppSize.h(context, 24)),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Home screen — build UI here',
                        style: TextStyleConstants.body.copyWith(
                          fontSize: AppSize.sp(context, 14.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentNavbarIndex,
        onItemSelected: (int index) {
          if (_currentNavbarIndex == index) return;
          setState(() => _currentNavbarIndex = index);
        },
      ),
    );
  }
}

class _AnimatedHomeBackgroundIcons extends StatefulWidget {
  const _AnimatedHomeBackgroundIcons();

  @override
  State<_AnimatedHomeBackgroundIcons> createState() =>
      _AnimatedHomeBackgroundIconsState();
}

class _AnimatedHomeBackgroundIconsState
    extends State<_AnimatedHomeBackgroundIcons>
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
                          (constraints.maxHeight * 0.23) +
                          (AppSize.h(context, 4) * motion),
                      right: AppSize.w(context, 55),
                      child: Transform.rotate(
                        angle: motion * math.pi / 180,
                        child: Opacity(
                          opacity: 0.06,
                          child: Image.asset(
                            AssetConstants.homeBackgroundTrading,
                            width: AppSize.w(context, 124),
                            height: AppSize.w(context, 124),
                            fit: BoxFit.contain,
                            color: ColorConstants.brandBlue,
                            colorBlendMode: BlendMode.srcIn,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top:
                          (constraints.maxHeight * 0.62) -
                          (AppSize.h(context, 3) * motion),
                      left: AppSize.w(context, 25),
                      child: Transform.rotate(
                        angle: -motion * 0.8 * math.pi / 180,
                        child: Opacity(
                          opacity: 0.055,
                          child: Image.asset(
                            AssetConstants.homeBackgroundProfit,
                            width: AppSize.w(context, 108),
                            height: AppSize.w(context, 108),
                            fit: BoxFit.contain,
                            color: ColorConstants.green,
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
