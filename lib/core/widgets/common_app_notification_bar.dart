import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

import '../constants/color_constants.dart';
import '../constants/text_style_constants.dart';
import '../utils/app_size.dart';

enum AppNotificationType { success, error, warning, info }

final class CommonAppNotificationBar {
  CommonAppNotificationBar._();

  static const Duration defaultDuration = Duration(seconds: 4);

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    AppNotificationType type = AppNotificationType.info,
    Duration duration = defaultDuration,
  }) async {
    final visual = _NotificationVisual.fromType(type);

    await Flushbar<void>(
      flushbarPosition: FlushbarPosition.TOP,
      flushbarStyle: FlushbarStyle.FLOATING,
      margin: AppSize.insets(context, left: 16, top: 12, right: 16),
      padding: AppSize.insets(
        context,
        left: 14,
        top: 12,
        right: 14,
        bottom: 12,
      ),
      borderRadius: BorderRadius.circular(AppSize.r(context, 14)),
      backgroundColor: visual.backgroundColor,
      borderColor: visual.foregroundColor.withValues(alpha: 0.28),
      borderWidth: 1,
      boxShadows: <BoxShadow>[
        BoxShadow(
          color: ColorConstants.navy.withValues(alpha: 0.12),
          blurRadius: AppSize.r(context, 18),
          offset: Offset(0, AppSize.h(context, 6)),
        ),
      ],
      icon: Container(
        width: AppSize.r(context, 34),
        height: AppSize.r(context, 34),
        decoration: BoxDecoration(
          color: visual.foregroundColor.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          visual.icon,
          color: visual.foregroundColor,
          size: AppSize.r(context, 21),
        ),
      ),
      titleText: Text(
        title,
        style: TextStyleConstants.cardTitleSmall.copyWith(
          color: visual.foregroundColor,
          fontSize: AppSize.sp(context, 14),
        ),
      ),
      messageText: Text(
        message,
        style: TextStyleConstants.caption.copyWith(
          color: visual.foregroundColor.withValues(alpha: 0.82),
          fontSize: AppSize.sp(context, 12),
        ),
      ),
      duration: duration,
      animationDuration: const Duration(milliseconds: 220),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInCubic,
      isDismissible: true,
      dismissDirection: FlushbarDismissDirection.HORIZONTAL,
    ).show(context);
  }

  static Future<void> success({
    required BuildContext context,
    required String title,
    required String message,
    Duration duration = defaultDuration,
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      type: AppNotificationType.success,
      duration: duration,
    );
  }

  static Future<void> error({
    required BuildContext context,
    required String title,
    required String message,
    Duration duration = defaultDuration,
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      type: AppNotificationType.error,
      duration: duration,
    );
  }

  static Future<void> warning({
    required BuildContext context,
    required String title,
    required String message,
    Duration duration = defaultDuration,
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      type: AppNotificationType.warning,
      duration: duration,
    );
  }

  static Future<void> info({
    required BuildContext context,
    required String title,
    required String message,
    Duration duration = defaultDuration,
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      type: AppNotificationType.info,
      duration: duration,
    );
  }
}

final class _NotificationVisual {
  const _NotificationVisual({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
  });

  factory _NotificationVisual.fromType(AppNotificationType type) {
    return switch (type) {
      AppNotificationType.success => const _NotificationVisual(
        backgroundColor: ColorConstants.profitBg,
        foregroundColor: ColorConstants.green,
        icon: Icons.check_rounded,
      ),
      AppNotificationType.error => const _NotificationVisual(
        backgroundColor: ColorConstants.lossBg,
        foregroundColor: ColorConstants.red,
        icon: Icons.close_rounded,
      ),
      AppNotificationType.warning => const _NotificationVisual(
        backgroundColor: ColorConstants.warnBg,
        foregroundColor: ColorConstants.amber,
        icon: Icons.priority_high_rounded,
      ),
      AppNotificationType.info => const _NotificationVisual(
        backgroundColor: ColorConstants.liveBg,
        foregroundColor: ColorConstants.brandBlue,
        icon: Icons.info_outline_rounded,
      ),
    };
  }

  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
}
