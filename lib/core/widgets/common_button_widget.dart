import 'package:flutter/material.dart';

import '../constants/color_constants.dart';
import '../constants/text_style_constants.dart';
import '../utils/app_size.dart';

class CommonButtonWidget extends StatelessWidget {
  const CommonButtonWidget({
    required this.label,
    required this.onPressed,
    super.key,
    this.backgroundColor = ColorConstants.brandBlue,
    this.foregroundColor = ColorConstants.white,
    this.disabledBackgroundColor = ColorConstants.line,
    this.disabledForegroundColor = ColorConstants.soft,
    this.borderColor,
    this.width = double.infinity,
    this.height = 50,
    this.borderRadius = 8,
    this.isLoading = false,
    this.leading,
    this.horizontalPadding = 20,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color disabledBackgroundColor;
  final Color disabledForegroundColor;
  final Color? borderColor;
  final double? width;
  final double height;
  final double borderRadius;
  final bool isLoading;
  final Widget? leading;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: AppSize.h(context, height),
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: disabledBackgroundColor,
          disabledForegroundColor: disabledForegroundColor,
          padding: AppSize.symmetric(context, horizontal: horizontalPadding),
          textStyle: TextStyleConstants.buttonLarge.copyWith(
            fontSize: AppSize.sp(context, 15),
          ),
          side: borderColor == null
              ? BorderSide.none
              : BorderSide(color: borderColor!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppSize.r(context, borderRadius),
            ),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isLoading
              ? SizedBox(
                  key: const ValueKey<String>('loading'),
                  width: AppSize.r(context, 20),
                  height: AppSize.r(context, 20),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foregroundColor,
                  ),
                )
              : Row(
                  key: const ValueKey<String>('content'),
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (leading != null) ...<Widget>[
                      leading!,
                      SizedBox(width: AppSize.w(context, 8)),
                    ],
                    Text(
                      label,
                      style: TextStyleConstants.buttonLarge.copyWith(
                        color: foregroundColor,
                        fontSize: AppSize.sp(context, 15),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
