import 'package:flutter/material.dart';

import '../constants/color_constants.dart';
import '../utils/app_size.dart';

/// Horizontal divider — thick in the center, fades thin toward the sides.
class TaperedHorizontalDivider extends StatelessWidget {
  const TaperedHorizontalDivider({
    super.key,
    this.height = 1.5,
    this.verticalPadding = 2,
  });

  final double height;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSize.h(context, verticalPadding)),
      child: SizedBox(
        width: double.infinity,
        height: AppSize.h(context, height),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSize.r(context, 2)),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: <Color>[
                ColorConstants.line.withValues(alpha: 0.0),
                ColorConstants.navy.withValues(alpha: 0.14),
                ColorConstants.brandBlue.withValues(alpha: 0.22),
                ColorConstants.navy.withValues(alpha: 0.14),
                ColorConstants.line.withValues(alpha: 0.0),
              ],
              stops: const <double>[0, 0.18, 0.5, 0.82, 1],
            ),
          ),
        ),
      ),
    );
  }
}

/// Vertical divider — thick in the center, fades thin toward the ends.
class TaperedVerticalDivider extends StatelessWidget {
  const TaperedVerticalDivider({
    super.key,
    this.width = 1.5,
    this.height = 40,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSize.w(context, width),
      height: AppSize.h(context, height),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSize.r(context, 2)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              ColorConstants.line.withValues(alpha: 0.0),
              ColorConstants.navy.withValues(alpha: 0.18),
              ColorConstants.brandBlue.withValues(alpha: 0.28),
              ColorConstants.navy.withValues(alpha: 0.18),
              ColorConstants.line.withValues(alpha: 0.0),
            ],
            stops: const <double>[0, 0.22, 0.5, 0.78, 1],
          ),
        ),
      ),
    );
  }
}
