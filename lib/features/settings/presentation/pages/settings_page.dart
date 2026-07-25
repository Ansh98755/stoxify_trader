import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../../core/widgets/common_button_widget.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
                    title: 'Settings',
                    onBack: () => context.pop(),
                  ),
                  SizedBox(height: AppSize.h(context, 18)),
                  AppMenuListTile(
                    title: 'Notifications',
                    subtitle: 'Push alerts for trades & renewals',
                    onTap: () => context.push(AppRoutingName.notifications),
                  ),
                  SizedBox(height: AppSize.h(context, 10)),
                  AppMenuListTile(
                    title: 'Privacy',
                    subtitle: 'How we use your data',
                    onTap: () {},
                  ),
                  const Spacer(),
                  CommonButtonWidget(
                    label: 'Sign out',
                    backgroundColor: ColorConstants.white,
                    foregroundColor: ColorConstants.red,
                    borderColor: ColorConstants.red.withValues(alpha: 0.35),
                    onPressed: () => context.go(AppRoutingName.login),
                  ),
                  SizedBox(height: AppSize.h(context, 16)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
