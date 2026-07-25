import 'package:flutter/material.dart';

import '../constants/color_constants.dart';
import '../constants/text_style_constants.dart';
import '../utils/app_size.dart';

enum RiskLevel { low, medium, high }

class RiskBadge extends StatelessWidget {
  const RiskBadge({required this.level, super.key});

  final RiskLevel level;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;

    switch (level) {
      case RiskLevel.low:
        bg = ColorConstants.riskLowBg;
        fg = ColorConstants.brandBlue;
        label = 'Low risk';
      case RiskLevel.medium:
        bg = ColorConstants.riskMediumBg;
        fg = ColorConstants.amber;
        label = 'Medium risk';
      case RiskLevel.high:
        bg = ColorConstants.riskHighBg;
        fg = ColorConstants.red;
        label = 'High risk';
    }

    return Container(
      padding: AppSize.symmetric(context, horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSize.r(context, 6)),
        border: Border.all(color: fg.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyleConstants.caption.copyWith(
          fontSize: AppSize.sp(context, 10.5),
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  static RiskLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return RiskLevel.low;
      case 'high':
        return RiskLevel.high;
      default:
        return RiskLevel.medium;
    }
  }
}
