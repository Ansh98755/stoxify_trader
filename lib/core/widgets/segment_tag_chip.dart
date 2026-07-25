import 'package:flutter/material.dart';

import '../constants/color_constants.dart';
import '../constants/text_style_constants.dart';
import '../utils/app_size.dart';

class SegmentTagChip extends StatelessWidget {
  const SegmentTagChip({
    required this.label,
    super.key,
    this.muted = false,
    this.hanging = false,
    this.showDot = false,
  });

  final String label;
  final bool muted;

  /// Home-style hanging tab that sits on the top edge of a card.
  final bool hanging;
  final bool showDot;

  (Color, Color) get _gradientColors {
    final key = label.toLowerCase();
    if (muted) {
      return (ColorConstants.soft, ColorConstants.mute);
    }
    if (key.contains('equity') || key.contains('option')) {
      return (
        ColorConstants.gradientEquityStart,
        ColorConstants.gradientEquityEnd,
      );
    }
    if (key.contains('f&o') || key.contains('fno') || key.contains('signal')) {
      return (
        ColorConstants.gradientSignalStart,
        ColorConstants.gradientSignalEnd,
      );
    }
    return (
      ColorConstants.gradientBlueStart,
      ColorConstants.gradientBlueEnd,
    );
  }

  @override
  Widget build(BuildContext context) {
    final (Color start, Color end) = _gradientColors;

    return Container(
      padding: hanging
          ? EdgeInsets.only(
              left: AppSize.w(context, 9),
              right: AppSize.w(context, 9),
              top: AppSize.h(context, 5),
              bottom: AppSize.h(context, 9),
            )
          : AppSize.symmetric(context, horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[start, end],
        ),
        borderRadius: hanging
            ? BorderRadius.only(
                topLeft: Radius.circular(AppSize.r(context, 8)),
                topRight: Radius.circular(AppSize.r(context, 8)),
                bottomLeft: Radius.circular(AppSize.r(context, 3)),
                bottomRight: Radius.circular(AppSize.r(context, 3)),
              )
            : BorderRadius.circular(AppSize.r(context, 8)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: end.withValues(alpha: hanging ? 0.32 : 0.28),
            blurRadius: AppSize.r(context, hanging ? 8 : 6),
            offset: Offset(0, AppSize.h(context, hanging ? 3 : 2)),
          ),
          if (hanging)
            BoxShadow(
              color: ColorConstants.shadowSoft.withValues(alpha: 0.08),
              blurRadius: AppSize.r(context, 2),
              offset: Offset(0, AppSize.h(context, 1)),
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (showDot) ...<Widget>[
            Container(
              width: AppSize.r(context, 5),
              height: AppSize.r(context, 5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: ColorConstants.white,
              ),
            ),
            SizedBox(width: AppSize.w(context, 4)),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: TextStyleConstants.fontFamilyDisplay,
              fontSize: AppSize.sp(context, hanging ? 9.5 : 11),
              fontWeight: FontWeight.w600,
              color: ColorConstants.white,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Row of hanging gradient tags for the top edge of a card (Home-style).
class HangingSegmentTagsRow extends StatelessWidget {
  const HangingSegmentTagsRow({
    required this.tags,
    super.key,
  });

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < tags.length; i++) ...<Widget>[
          if (i > 0) SizedBox(width: AppSize.w(context, 5)),
          SegmentTagChip(
            label: tags[i],
            hanging: true,
            showDot: i > 0,
          ),
        ],
      ],
    );
  }
}
