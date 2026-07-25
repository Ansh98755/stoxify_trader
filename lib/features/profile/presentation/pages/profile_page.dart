import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/utils/main_tab_navigation.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../../core/widgets/bottom_navbar.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: ColorConstants.transparent,
      body: Stack(
        children: <Widget>[
          const AppScreenBackground(),
          SafeArea(
            child: Padding(
              padding: AppSize.insets(context, left: 16, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Profile',
                    style: TextStyleConstants.screenTitle.copyWith(
                      fontSize: AppSize.sp(context, 22),
                    ),
                  ),
                  SizedBox(height: AppSize.h(context, 14)),
                  Container(
                    width: double.infinity,
                    padding: AppSize.insets(
                      context,
                      left: 14,
                      right: 14,
                      top: 14,
                      bottom: 14,
                    ),
                    decoration: BoxDecoration(
                      color: ColorConstants.white,
                      borderRadius: BorderRadius.circular(AppSize.r(context, 16)),
                      border: Border.all(color: ColorConstants.line),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: AppSize.r(context, 52),
                          height: AppSize.r(context, 52),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: <Color>[
                                ColorConstants.brandBlueLight,
                                ColorConstants.brandBlue,
                              ],
                            ),
                          ),
                          child: Text(
                            'AY',
                            style: TextStyleConstants.cardTitleSmall.copyWith(
                              color: ColorConstants.white,
                              fontSize: AppSize.sp(context, 16),
                            ),
                          ),
                        ),
                        SizedBox(width: AppSize.w(context, 12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Ayush',
                                style: TextStyleConstants.cardTitleSmall.copyWith(
                                  fontSize: AppSize.sp(context, 16),
                                ),
                              ),
                              SizedBox(height: AppSize.h(context, 3)),
                              Text(
                                '+91 98765 43210',
                                style: TextStyleConstants.caption.copyWith(
                                  fontSize: AppSize.sp(context, 12),
                                  color: ColorConstants.mute,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSize.h(context, 16)),
                  Expanded(
                    child: ListView(
                      children: <Widget>[
                        AppMenuListTile(
                          title: 'Personal info',
                          subtitle: 'Name, email & phone',
                          leading: _icon(Icons.person_outline_rounded),
                          onTap: () {},
                        ),
                        SizedBox(height: AppSize.h(context, 10)),
                        AppMenuListTile(
                          title: 'Trading preferences',
                          subtitle: 'Segments you follow',
                          leading: _icon(Icons.tune_rounded),
                          onTap: () => context.push(AppRoutingName.interest),
                        ),
                        SizedBox(height: AppSize.h(context, 10)),
                        AppMenuListTile(
                          title: 'My subscriptions',
                          subtitle: 'Manage active plans',
                          leading: _icon(Icons.subscriptions_outlined),
                          onTap: () =>
                              context.push(AppRoutingName.mySubscriptions),
                        ),
                        SizedBox(height: AppSize.h(context, 10)),
                        AppMenuListTile(
                          title: 'Notifications',
                          subtitle: 'Trade alerts & renewals',
                          leading: _icon(Icons.notifications_none_rounded),
                          onTap: () =>
                              context.push(AppRoutingName.notifications),
                        ),
                        SizedBox(height: AppSize.h(context, 10)),
                        AppMenuListTile(
                          title: 'Settings',
                          subtitle: 'Privacy & account',
                          leading: _icon(Icons.settings_outlined),
                          onTap: () => context.push(AppRoutingName.settings),
                        ),
                        SizedBox(height: AppSize.h(context, 10)),
                        AppMenuListTile(
                          title: 'Delete account',
                          leading: _icon(
                            Icons.delete_outline_rounded,
                            color: ColorConstants.red,
                          ),
                          destructive: true,
                          onTap: () {},
                        ),
                        SizedBox(height: AppSize.h(context, 88)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavbar(
              currentIndex: 3,
              onItemSelected: (int index) {
                if (index == 3) return;
                navigateMainTab(context, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  static Widget _icon(IconData icon, {Color color = ColorConstants.brandBlue}) {
    return Builder(
      builder: (BuildContext context) {
        return Container(
          width: AppSize.r(context, 36),
          height: AppSize.r(context, 36),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSize.r(context, 10)),
          ),
          child: Icon(icon, color: color, size: AppSize.r(context, 20)),
        );
      },
    );
  }
}
