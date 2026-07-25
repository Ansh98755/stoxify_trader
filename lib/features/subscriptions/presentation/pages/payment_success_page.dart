import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../../core/widgets/common_button_widget.dart';

class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.transparent,
      body: Stack(
        children: <Widget>[
          const AppScreenBackground(),
          SafeArea(
            child: Padding(
              padding: AppSize.insets(context, left: 24, right: 24),
              child: Column(
                children: <Widget>[
                  const Spacer(),
                  Container(
                    width: AppSize.r(context, 88),
                    height: AppSize.r(context, 88),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorConstants.pillSuccessBg,
                      border: Border.all(
                        color: ColorConstants.green.withValues(alpha: 0.35),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: ColorConstants.green,
                      size: AppSize.r(context, 44),
                    ),
                  ),
                  SizedBox(height: AppSize.h(context, 20)),
                  Text(
                    'Subscribed!',
                    style: TextStyleConstants.screenTitle.copyWith(
                      fontSize: AppSize.sp(context, 28),
                    ),
                  ),
                  SizedBox(height: AppSize.h(context, 10)),
                  Text(
                    'Your FNO Batch plan is active. New ideas from this analyst will appear in Home and Trades.',
                    textAlign: TextAlign.center,
                    style: TextStyleConstants.bodyMedium.copyWith(
                      fontSize: AppSize.sp(context, 14),
                      color: ColorConstants.mute,
                      height: 1.45,
                    ),
                  ),
                  const Spacer(),
                  CommonButtonWidget(
                    label: 'View Trades',
                    onPressed: () => context.go(AppRoutingName.tradeFeed),
                  ),
                  SizedBox(height: AppSize.h(context, 10)),
                  CommonButtonWidget(
                    label: 'Done',
                    backgroundColor: ColorConstants.white,
                    foregroundColor: ColorConstants.ink,
                    borderColor: ColorConstants.line,
                    onPressed: () => context.go(AppRoutingName.home),
                  ),
                  SizedBox(height: AppSize.h(context, 24)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
