import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/app_screen_background.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static const List<_NotifItem> _items = <_NotifItem>[
    _NotifItem(
      title: 'New trade idea',
      subtitle: 'Arjun Mehta published Tata Motors · Swing',
      time: '12 min ago',
      icon: Icons.bolt_rounded,
      color: ColorConstants.brandBlue,
    ),
    _NotifItem(
      title: 'Target hit',
      subtitle: 'Reliance reached T1 · +5.20%',
      time: '1 hr ago',
      icon: Icons.flag_rounded,
      color: ColorConstants.green,
    ),
    _NotifItem(
      title: 'Renewing soon',
      subtitle: 'Equity Swing Pro renews in 3 days',
      time: 'Yesterday',
      icon: Icons.autorenew_rounded,
      color: ColorConstants.amber,
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
                    title: 'Alerts',
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                width: AppSize.r(context, 40),
                                height: AppSize.r(context, 40),
                                decoration: BoxDecoration(
                                  color: item.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                    AppSize.r(context, 12),
                                  ),
                                ),
                                child: Icon(
                                  item.icon,
                                  color: item.color,
                                  size: AppSize.r(context, 20),
                                ),
                              ),
                              SizedBox(width: AppSize.w(context, 12)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      item.title,
                                      style: TextStyleConstants.bodyMedium
                                          .copyWith(
                                        fontSize: AppSize.sp(context, 14),
                                        fontWeight: FontWeight.w700,
                                        color: ColorConstants.ink,
                                      ),
                                    ),
                                    SizedBox(height: AppSize.h(context, 4)),
                                    Text(
                                      item.subtitle,
                                      style:
                                          TextStyleConstants.caption.copyWith(
                                        fontSize: AppSize.sp(context, 12.5),
                                        color: ColorConstants.mute,
                                      ),
                                    ),
                                    SizedBox(height: AppSize.h(context, 6)),
                                    Text(
                                      item.time,
                                      style:
                                          TextStyleConstants.caption.copyWith(
                                        fontSize: AppSize.sp(context, 11),
                                        color: ColorConstants.soft,
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

class _NotifItem {
  const _NotifItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;
}
