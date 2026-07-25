import 'package:flutter/material.dart';

import '../constants/color_constants.dart';
import '../constants/text_style_constants.dart';
import '../utils/app_size.dart';

class SebiVerifiedPill extends StatelessWidget {
  const SebiVerifiedPill({
    super.key,
    this.compact = false,
  });

  /// When true, shows a short "SEBI" label for dense card headers.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSize.symmetric(
        context,
        horizontal: compact ? 7 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: ColorConstants.liveBg,
        borderRadius: BorderRadius.circular(AppSize.r(context, 6)),
        border: Border.all(
          color: ColorConstants.brandBlue.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.verified_rounded,
            size: AppSize.r(context, compact ? 11 : 12),
            color: ColorConstants.brandBlue,
          ),
          SizedBox(width: AppSize.w(context, 4)),
          Text(
            compact ? 'SEBI' : 'SEBI-registered',
            style: TextStyleConstants.caption.copyWith(
              fontSize: AppSize.sp(context, compact ? 10 : 10.5),
              fontWeight: FontWeight.w700,
              color: ColorConstants.brandBlue,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
