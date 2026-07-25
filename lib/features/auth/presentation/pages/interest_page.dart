import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/common_button_widget.dart';
import '../../domain/repositories/auth_repository.dart';

class InterestPage extends StatefulWidget {
  const InterestPage({super.key});

  @override
  State<InterestPage> createState() => _InterestPageState();
}

class _InterestPageState extends State<InterestPage> {
  final Set<String> _selected = <String>{'Equity'};
  bool _isSubmitting = false;

  static const Map<String, String> _backendInterestById = <String, String>{
    'Equity': 'EQUITY',
    'F&O': 'FNO',
    'Intraday': 'INTRADAY',
    'Swing': 'SWING',
    'Long Term': 'LONG_TERM',
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

  Future<void> _onContinue() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final mapped = _selected
        .map((String id) => _backendInterestById[id])
        .whereType<String>()
        .toList(growable: false);

    try {
      await getIt<AuthRepository>().updateInterests(mapped);
    } catch (_) {
      // Best-effort: still continue so the user isn't stuck.
    }

    if (!mounted) return;
    context.go(AppRoutingName.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.pageBackground,
      body: SafeArea(
        child: Padding(
          padding: AppSize.insets(context, left: 20, right: 20, top: 16, bottom: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
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
                child: ListView.separated(
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
                        borderRadius:
                            BorderRadius.circular(AppSize.r(context, 14)),
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
                        borderRadius:
                            BorderRadius.circular(AppSize.r(context, 14)),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      option.title,
                                      style:
                                          TextStyleConstants.bodyMedium.copyWith(
                                        fontSize: AppSize.sp(context, 14.5),
                                        fontWeight: FontWeight.w700,
                                        color: ColorConstants.ink,
                                      ),
                                    ),
                                    SizedBox(height: AppSize.h(context, 3)),
                                    Text(
                                      option.subtitle,
                                      style:
                                          TextStyleConstants.caption.copyWith(
                                        fontSize: AppSize.sp(context, 12),
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
                label: 'Continue',
                isLoading: _isSubmitting,
                onPressed: _selected.isEmpty || _isSubmitting
                    ? null
                    : _onContinue,
              ),
            ],
          ),
        ),
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
