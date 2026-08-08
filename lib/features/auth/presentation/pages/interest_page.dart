import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/notifications/notification_navigator.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/common_button_widget.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../domain/repositories/auth_repository.dart';

class InterestPage extends StatefulWidget {
  const InterestPage({super.key});

  @override
  State<InterestPage> createState() => _InterestPageState();
}

class _InterestPageState extends State<InterestPage> {
  final Set<String> _selected = <String>{};
  bool _isLoading = true;
  bool _isSubmitting = false;

  /// UI id → backend enum (PATCH body).
  static const Map<String, String> _backendInterestById = <String, String>{
    'Equity': 'EQUITY',
    'F&O': 'FNO',
    'Intraday': 'INTRADAY',
    'Swing': 'SWING',
    'Long Term': 'LONG_TERM',
  };

  /// Backend enum → UI id (pre-select from GET /users/me).
  static const Map<String, String> _idByBackendInterest = <String, String>{
    'EQUITY': 'Equity',
    'FNO': 'F&O',
    'INTRADAY': 'Intraday',
    'SWING': 'Swing',
    'LONG_TERM': 'Long Term',
  };

  static const List<_InterestOption> _options = <_InterestOption>[
    _InterestOption(
      id: 'Equity',
      title: 'Equity',
      subtitle: 'Cash market stock ideas',
      icon: Icons.show_chart_rounded,
    ),
    _InterestOption(
      id: 'Swing',
      title: 'Swing',
      subtitle: 'Multi-day positional setups',
      icon: Icons.timeline_rounded,
    ),
    _InterestOption(
      id: 'Intraday',
      title: 'Intraday',
      subtitle: 'Same-day equity & index calls',
      icon: Icons.bolt_rounded,
    ),
    _InterestOption(
      id: 'F&O',
      title: 'F&O',
      subtitle: 'Futures & options research',
      icon: Icons.candlestick_chart_rounded,
    ),
    _InterestOption(
      id: 'Long Term',
      title: 'Long Term',
      subtitle: 'Investment-style research',
      icon: Icons.account_balance_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        unawaited(_loadExistingInterests());
      } else {
        setState(() {
          if (_selected.isEmpty) _selected.add('Equity');
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _loadExistingInterests() async {
    try {
      final user = await getIt<AuthRepository>().getMe();
      if (!mounted) return;
      final restored = <String>{};
      for (final raw in user.interests) {
        final key = raw.trim().toUpperCase();
        final id = _idByBackendInterest[key];
        if (id != null) restored.add(id);
      }
      setState(() {
        _selected
          ..clear()
          ..addAll(restored.isEmpty ? <String>{'Equity'} : restored);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (_selected.isEmpty) _selected.add('Equity');
        _isLoading = false;
      });
    }
  }

  Future<void> _onContinue() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final mapped = _selected
        .map((String id) => _backendInterestById[id])
        .whereType<String>()
        .toList(growable: false);

    try {
      await getIt<AuthRepository>().updateInterests(mapped);
      await getIt<SecureStorage>().delete(SecureStorage.isNewUser);
    } catch (_) {
      // Best-effort: still continue so the user isn't stuck.
    }

    if (!mounted) return;
    // Profile opens this with push(); onboarding lands here with replace/go.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutingName.home);
      NotificationNavigator.flushPendingAfterFrame();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fromProfile = context.canPop();
    return Scaffold(
      backgroundColor: ColorConstants.pageBackground,
      body: Stack(
        children: <Widget>[
          SafeArea(
            child: Padding(
              padding: AppSize.insets(
                context,
                left: 20,
                right: 20,
                top: 16,
                bottom: 22,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (fromProfile)
                    Padding(
                      padding: EdgeInsets.only(bottom: AppSize.h(context, 8)),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: ColorConstants.ink,
                      ),
                    ),
                  Text(
                    'What do you trade?',
                    style: TextStyleConstants.screenTitle.copyWith(
                      fontSize: AppSize.sp(context, 24),
                    ),
                  ),
                  SizedBox(height: AppSize.h(context, 8)),
                  Text(
                    'Pick one or more segments. We’ll personalise Discover and recommendations.',
                    style: TextStyleConstants.bodyMedium.copyWith(
                      fontSize: AppSize.sp(context, 13.5),
                      color: ColorConstants.mute,
                    ),
                  ),
                  SizedBox(height: AppSize.h(context, 20)),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: AppLoader())
                        : ListView.separated(
                            itemCount: _options.length,
                            separatorBuilder: (_, _) =>
                                SizedBox(height: AppSize.h(context, 10)),
                            itemBuilder: (BuildContext context, int index) {
                              final option = _options[index];
                              final selected = _selected.contains(option.id);
                              return Material(
                                color: selected
                                    ? ColorConstants.liveBg
                                    : ColorConstants.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSize.r(context, 14),
                                  ),
                                  side: BorderSide(
                                    color: selected
                                        ? ColorConstants.brandBlue
                                        : ColorConstants.line,
                                    width: selected ? 1.5 : 1,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (selected) {
                                        _selected.remove(option.id);
                                      } else {
                                        _selected.add(option.id);
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(
                                    AppSize.r(context, 14),
                                  ),
                                  child: Padding(
                                    padding: AppSize.insets(
                                      context,
                                      left: 14,
                                      right: 14,
                                      top: 14,
                                      bottom: 14,
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Container(
                                          width: AppSize.r(context, 42),
                                          height: AppSize.r(context, 42),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              AppSize.r(context, 12),
                                            ),
                                            gradient: const LinearGradient(
                                              colors: <Color>[
                                                ColorConstants.brandBlue,
                                                ColorConstants.brandBlueLight,
                                              ],
                                            ),
                                          ),
                                          child: Icon(
                                            option.icon,
                                            color: ColorConstants.white,
                                            size: AppSize.r(context, 22),
                                          ),
                                        ),
                                        SizedBox(width: AppSize.w(context, 12)),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                option.title,
                                                style: TextStyleConstants
                                                    .bodyMedium
                                                    .copyWith(
                                                  fontSize:
                                                      AppSize.sp(context, 14.5),
                                                  fontWeight: FontWeight.w700,
                                                  color: ColorConstants.ink,
                                                ),
                                              ),
                                              SizedBox(
                                                height: AppSize.h(context, 3),
                                              ),
                                              Text(
                                                option.subtitle,
                                                style: TextStyleConstants
                                                    .caption
                                                    .copyWith(
                                                  fontSize:
                                                      AppSize.sp(context, 12),
                                                  color: ColorConstants.mute,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          selected
                                              ? Icons.check_circle_rounded
                                              : Icons.circle_outlined,
                                          color: selected
                                              ? ColorConstants.brandBlue
                                              : ColorConstants.soft,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  CommonButtonWidget(
                    label: fromProfile ? 'Save preferences' : 'Continue',
                    isLoading: _isSubmitting,
                    onPressed: _selected.isEmpty ||
                            _isSubmitting ||
                            _isLoading
                        ? null
                        : _onContinue,
                  ),
                ],
              ),
            ),
          ),
          if (_isSubmitting) const Positioned.fill(child: AppLoaderOverlay()),
        ],
      ),
    );
  }
}

class _InterestOption {
  const _InterestOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
}
