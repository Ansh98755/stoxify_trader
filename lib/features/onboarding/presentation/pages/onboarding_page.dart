import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/asset_constants.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/common_button_widget.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OnboardingBloc>(
      create: (_) => OnboardingBloc(),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatefulWidget {
  const _OnboardingView();

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleState(BuildContext context, OnboardingState state) {
    if (state.isCompleted) {
      context.go(AppRoutingName.login);
      return;
    }

    if (!_pageController.hasClients) return;
    final currentPage = _pageController.page?.round();
    if (currentPage == state.currentPage) return;

    _pageController.animateToPage(
      state.currentPage,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingBloc, OnboardingState>(
      listenWhen: (previous, current) =>
          previous.currentPage != current.currentPage ||
          previous.isCompleted != current.isCompleted,
      listener: _handleState,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: ColorConstants.transparent,
          systemStatusBarContrastEnforced: false,
        ),
        child: Scaffold(
          backgroundColor: ColorConstants.navy,
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: <double>[0, 0.48, 1],
                colors: <Color>[
                  Color(0x2E1A5CC8),
                  Color(0x144F8CFF),
                  ColorConstants.pageBackground,
                ],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final artHeight = AppSize.h(
                    context,
                    300,
                  ).clamp(AppSize.h(context, 240), AppSize.h(context, 300));

                  return Padding(
                    padding: AppSize.insets(
                      context,
                      left: 20,
                      top: 8,
                      right: 20,
                      bottom: 22,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        BlocBuilder<OnboardingBloc, OnboardingState>(
                          buildWhen: (previous, current) =>
                              previous.currentPage != current.currentPage,
                          builder:
                              (BuildContext context, OnboardingState state) {
                                return Text(
                                  'STEP ${state.currentPage + 1} OF '
                                  '${OnboardingState.pageCount}',
                                  style: TextStyleConstants.caption.copyWith(
                                    color: ColorConstants.white,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                    fontSize: AppSize.sp(context, 12),
                                  ),
                                );
                              },
                        ),
                        SizedBox(height: AppSize.h(context, 14)),
                        SizedBox(
                          height: artHeight,
                          width: double.infinity,
                          child: const _TradingLoaderScene(),
                        ),
                        SizedBox(height: AppSize.h(context, 52)),
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            physics: const BouncingScrollPhysics(),
                            itemCount: OnboardingState.pageCount,
                            onPageChanged: (int page) {
                              context.read<OnboardingBloc>().add(
                                OnboardingPageChanged(page),
                              );
                            },
                            itemBuilder: (BuildContext context, int index) {
                              return _OnboardingCopy(index: index);
                            },
                          ),
                        ),
                        SizedBox(height: AppSize.h(context, 22)),
                        const _OnboardingActions(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TradingLoaderScene extends StatelessWidget {
  const _TradingLoaderScene();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.r(context, 28)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFF4F8FF), Color(0xFFEEFBF3)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSize.r(context, 28)),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Center(
              child: Container(
                width: AppSize.w(context, 230),
                height: AppSize.w(context, 230),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      Color(0x2990C50B),
                      ColorConstants.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Lottie.asset(
                AssetConstants.tradingLoader,
                width: AppSize.w(context, 250),
                height: AppSize.w(context, 250),
                fit: BoxFit.contain,
                repeat: true,
              ),
            ),
            Positioned(
              left: AppSize.w(context, 14),
              top: AppSize.h(context, 18),
              child: const _ContextChip(
                title: 'SEBI',
                subtitle: 'Registered',
                accent: ColorConstants.green,
              ),
            ),
            Positioned(
              right: AppSize.w(context, 14),
              top: AppSize.h(context, 22),
              child: const _ContextChip(
                title: 'Live',
                subtitle: 'Ideas',
                accent: ColorConstants.brandBlue,
              ),
            ),
            Positioned(
              left: AppSize.w(context, 16),
              bottom: AppSize.h(context, 18),
              child: const _ContextChip(
                title: 'Audited',
                subtitle: 'Track record',
                accent: ColorConstants.navy,
              ),
            ),
            Positioned(
              right: AppSize.w(context, 16),
              bottom: AppSize.h(context, 18),
              child: const _ContextChip(
                title: 'Trust',
                subtitle: 'A+',
                accent: ColorConstants.brandBlueLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContextChip extends StatelessWidget {
  const _ContextChip({
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSize.symmetric(context, horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: ColorConstants.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppSize.r(context, 10)),
        border: Border.all(color: ColorConstants.line),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0x0F101828),
            offset: Offset(0, AppSize.h(context, 1)),
            blurRadius: AppSize.r(context, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: AppSize.r(context, 7),
            height: AppSize.r(context, 7),
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          SizedBox(width: AppSize.w(context, 6)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                style: TextStyleConstants.caption.copyWith(
                  color: ColorConstants.ink,
                  fontWeight: FontWeight.w600,
                  fontSize: AppSize.sp(context, 12),
                ),
              ),
              Text(
                subtitle,
                style: TextStyleConstants.caption.copyWith(
                  fontSize: AppSize.sp(context, 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OnboardingCopy extends StatelessWidget {
  const _OnboardingCopy({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          StringConstants.onboardingTitles[index],
          style: TextStyleConstants.screenTitleLarge.copyWith(
            color: ColorConstants.white,
            fontSize: AppSize.sp(context, 26),
          ),
        ),
        SizedBox(height: AppSize.h(context, 12)),
        Text(
          StringConstants.onboardingDescriptions[index],
          style: TextStyleConstants.bodyMedium.copyWith(
            height: 1.55,
            color: ColorConstants.white.withValues(alpha: 0.55),
            fontSize: AppSize.sp(context, 14),
          ),
        ),
        SizedBox(height: AppSize.h(context, 16)),
        // const _ProgressIndicator(),
      ],
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      buildWhen: (previous, current) =>
          previous.currentPage != current.currentPage,
      builder: (BuildContext context, OnboardingState state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(OnboardingState.pageCount, (
            int index,
          ) {
            final isActive = index == state.currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              width: AppSize.w(context, isActive ? 28 : 8),
              height: AppSize.h(context, 8),
              margin: EdgeInsets.only(
                right: index == OnboardingState.pageCount - 1
                    ? 0
                    : AppSize.w(context, 6),
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? ColorConstants.brandBlue
                    : ColorConstants.line,
                borderRadius: BorderRadius.circular(AppSize.r(context, 4)),
              ),
            );
          }),
        );
      },
    );
  }
}

class _OnboardingActions extends StatelessWidget {
  const _OnboardingActions();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      buildWhen: (previous, current) =>
          previous.currentPage != current.currentPage,
      builder: (BuildContext context, OnboardingState state) {
        return Column(
          children: <Widget>[
            CommonButtonWidget(
              label: state.isLastPage ? 'Get started' : 'Continue',
              onPressed: () {
                context.read<OnboardingBloc>().add(
                  const OnboardingNextPressed(),
                );
              },
            ),
            SizedBox(
              height: AppSize.h(context, 44),
              child: state.isLastPage
                  ? null
                  : TextButton(
                      onPressed: () {
                        context.read<OnboardingBloc>().add(
                          const OnboardingSkipped(),
                        );
                      },
                      child: Text(
                        'Skip for now',
                        style: TextStyleConstants.link.copyWith(
                          fontSize: AppSize.sp(context, 14),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
