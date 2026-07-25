import 'package:flutter/material.dart';

import '../constants/color_constants.dart';
import '../constants/text_style_constants.dart';
import '../utils/app_size.dart';

class FilterChipPill extends StatelessWidget {
  const FilterChipPill({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ColorConstants.brandBlue : ColorConstants.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
        side: BorderSide(
          color: selected
              ? ColorConstants.brandBlue
              : ColorConstants.navy.withValues(alpha: 0.35),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
        child: Padding(
          padding: AppSize.symmetric(context, horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyleConstants.bodyMedium.copyWith(
              fontSize: AppSize.sp(context, 12),
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? ColorConstants.white : ColorConstants.ink,
            ),
          ),
        ),
      ),
    );
  }
}
