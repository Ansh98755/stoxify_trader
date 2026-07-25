import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/app_screen_background.dart';

class MySubscriptionsPage extends StatelessWidget {
  const MySubscriptionsPage({super.key});

  static const List<_SubItem> _items = <_SubItem>[
    _SubItem(
      name: 'Arjun Mehta',
      plan: 'Equity Swing Pro',
      status: 'Renews 19 Aug',
      accent: ColorConstants.brandBlue,
    ),
    _SubItem(
      name: 'Neha Agarwal',
      plan: 'F&O Intraday Basic',
      status: 'Expires 02 Aug',
      accent: ColorConstants.green,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.transparent,
      body: Stack(
        children: <Widget>[
          const AppScreenBackground(),
          SafeArea(
            child: Padding(
              padding: AppSize.insets(context, left: 16, right: 16, top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppBackHeader(
                    title: 'Subscriptions',
                    onBack: () => context.pop(),
                  ),
                  SizedBox(height: AppSize.h(context, 16)),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, _) =>
                          SizedBox(height: AppSize.h(context, 10)),
                      itemBuilder: (BuildContext context, int index) {
                        final item = _items[index];
                        return Container(
                          padding: AppSize.insets(
                            context,
                            left: 14,
                            right: 14,
                            top: 14,
                            bottom: 14,
                          ),
                          decoration: BoxDecoration(
                            color: ColorConstants.white,
                            borderRadius:
                                BorderRadius.circular(AppSize.r(context, 14)),
                            border: Border.all(color: ColorConstants.line),
                          ),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: AppSize.r(context, 42),
                                height: AppSize.r(context, 42),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: item.accent.withValues(alpha: 0.15),
                                ),
                                child: Text(
                                  item.name
                                      .split(' ')
                                      .map((String p) => p[0])
                                      .take(2)
                                      .join(),
                                  style: TextStyleConstants.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: item.accent,
                                    fontSize: AppSize.sp(context, 13),
                                  ),
                                ),
                              ),
                              SizedBox(width: AppSize.w(context, 12)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      item.name,
                                      style: TextStyleConstants.bodyMedium
                                          .copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: ColorConstants.ink,
                                        fontSize: AppSize.sp(context, 14),
                                      ),
                                    ),
                                    SizedBox(height: AppSize.h(context, 3)),
                                    Text(
                                      '${item.plan} · ${item.status}',
                                      style:
                                          TextStyleConstants.caption.copyWith(
                                        fontSize: AppSize.sp(context, 12),
                                        color: ColorConstants.mute,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubItem {
  const _SubItem({
    required this.name,
    required this.plan,
    required this.status,
    required this.accent,
  });

  final String name;
  final String plan;
  final String status;
  final Color accent;
}
