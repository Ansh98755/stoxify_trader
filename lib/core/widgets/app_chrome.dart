import 'package:flutter/material.dart';

import '../constants/color_constants.dart';
import '../constants/text_style_constants.dart';
import '../utils/app_size.dart';

class AppBackHeader extends StatelessWidget {
  const AppBackHeader({
    required this.title,
    super.key,
    this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Material(
          color: ColorConstants.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
            side: const BorderSide(color: ColorConstants.line),
          ),
          child: InkWell(
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
            child: SizedBox(
              width: AppSize.r(context, 40),
              height: AppSize.r(context, 40),
              child: Icon(
                Icons.arrow_back_rounded,
                size: AppSize.r(context, 20),
                color: ColorConstants.ink,
              ),
            ),
          ),
        ),
        SizedBox(width: AppSize.w(context, 12)),
        Expanded(
          child: Text(
            title,
            style: TextStyleConstants.cardTitle.copyWith(
              fontSize: AppSize.sp(context, 18),
              color: ColorConstants.ink,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class AppMenuListTile extends StatelessWidget {
  const AppMenuListTile({
    required this.title,
    required this.onTap,
    super.key,
    this.subtitle,
    this.leading,
    this.destructive = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        destructive ? ColorConstants.red : ColorConstants.ink;

    return Material(
      color: ColorConstants.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSize.r(context, 14)),
        side: const BorderSide(color: ColorConstants.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSize.r(context, 14)),
        child: Padding(
          padding: AppSize.insets(context, left: 14, right: 12, top: 14, bottom: 14),
          child: Row(
            children: <Widget>[
              if (leading != null) ...<Widget>[
                leading!,
                SizedBox(width: AppSize.w(context, 12)),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyleConstants.bodyMedium.copyWith(
                        fontSize: AppSize.sp(context, 14),
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      SizedBox(height: AppSize.h(context, 3)),
                      Text(
                        subtitle!,
                        style: TextStyleConstants.caption.copyWith(
                          fontSize: AppSize.sp(context, 12),
                          color: ColorConstants.mute,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: ColorConstants.soft,
                size: AppSize.r(context, 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SebiDisclaimerStrip extends StatelessWidget {
  const SebiDisclaimerStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSize.insets(context, left: 12, right: 12, top: 10, bottom: 10),
      decoration: BoxDecoration(
        color: ColorConstants.gray50,
        borderRadius: BorderRadius.circular(AppSize.r(context, 10)),
        border: Border.all(color: ColorConstants.line),
      ),
      child: Text(
        'Research opinions only. Not investment advice. Markets involve risk; past performance does not guarantee future results.',
        style: TextStyleConstants.caption.copyWith(
          fontSize: AppSize.sp(context, 11),
          color: ColorConstants.mute,
          height: 1.4,
        ),
      ),
    );
  }
}

class AppSectionLabel extends StatelessWidget {
  const AppSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyleConstants.bodyMedium.copyWith(
        fontSize: AppSize.sp(context, 13),
        fontWeight: FontWeight.w600,
        color: ColorConstants.mute,
      ),
    );
  }
}
