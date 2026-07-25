import 'package:flutter/material.dart';

import '../../../../core/constants/asset_constants.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/utils/app_size.dart';

class HomeSearchRow extends StatelessWidget {
  const HomeSearchRow({
    super.key,
    this.controller,
    this.hintText = 'Search research or analysts',
    this.onChanged,
    this.onFilterTap,
    this.hasActiveFilters = false,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Material(
            color: ColorConstants.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSize.r(context, 14)),
              side: BorderSide(
                color: ColorConstants.navy.withValues(alpha: 0.4),
              ),
            ),
            child: SizedBox(
              height: AppSize.r(context, 44),
              child: Padding(
                padding: AppSize.symmetric(context, horizontal: 12),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.search_rounded,
                      size: AppSize.r(context, 18),
                      color: ColorConstants.soft,
                    ),
                    SizedBox(width: AppSize.w(context, 10)),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        onChanged: onChanged,
                        style: TextStyleConstants.body.copyWith(
                          color: ColorConstants.ink,
                          fontSize: AppSize.sp(context, 13),
                          fontWeight: FontWeight.w500,
                        ),
                        cursorColor: ColorConstants.brandBlue,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          isDense: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintText: hintText,
                          hintStyle: TextStyleConstants.body.copyWith(
                            color: ColorConstants.soft,
                            fontSize: AppSize.sp(context, 13),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    if (controller != null && controller!.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          controller!.clear();
                          onChanged?.call('');
                        },
                        child: Icon(
                          Icons.close_rounded,
                          size: AppSize.r(context, 16),
                          color: ColorConstants.soft,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: AppSize.w(context, 8)),
        Material(
          color: ColorConstants.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSize.r(context, 16)),
            side: BorderSide(
              color: ColorConstants.navy.withValues(alpha: 0.4),
            ),
          ),
          child: InkWell(
            onTap: onFilterTap,
            borderRadius: BorderRadius.circular(AppSize.r(context, 16)),
            child: SizedBox(
              width: AppSize.r(context, 42),
              height: AppSize.r(context, 44),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: <Widget>[
                  Image.asset(
                    AssetConstants.filterIcon,
                    width: AppSize.r(context, 25),
                    height: AppSize.r(context, 25),
                    fit: BoxFit.contain,
                  ),
                  if (hasActiveFilters)
                    Positioned(
                      top: AppSize.h(context, 8),
                      right: AppSize.w(context, 8),
                      child: Container(
                        width: AppSize.r(context, 7),
                        height: AppSize.r(context, 7),
                        decoration: const BoxDecoration(
                          color: ColorConstants.brandBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
