import 'package:flutter/material.dart';

import '../constants/color_constants.dart';
import '../constants/text_style_constants.dart';
import '../utils/app_size.dart';

enum TimelineMarkerLabelPosition { standard, leftOfDot, rightOfDot, hidden }

/// SL → Entry → Target timeline with Live marker (aligned with trade cards).
class TradeSignalTimeline extends StatelessWidget {
  const TradeSignalTimeline({
    super.key,
    this.timestamp,
    this.isLive = true,
    this.entry,
    this.stopLoss,
    this.target,
    this.currentPrice,
  });

  final String? timestamp;
  final bool isLive;
  final String? entry;
  final String? stopLoss;
  final String? target;
  final String? currentPrice;

  static double? _priceFrom(String? value) {
    if (value == null) return null;
    final String normalized = value.replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final double h = AppSize.h(context, 36);
    final double thickness = AppSize.h(context, 3);
    final double lineY = AppSize.h(context, 18) - (thickness / 2);
    final double dotTop = AppSize.h(context, 14);
    final double dotSize = AppSize.r(context, 9);

    return Column(
      children: <Widget>[
        SizedBox(
          height: h,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double maxW = constraints.maxWidth;
              final double inset = AppSize.w(context, 12);
              final double trackLeft = inset;
              final double trackRight = maxW - inset;
              final double trackW = trackRight - trackLeft;

              final double? slValue = _priceFrom(stopLoss);
              final double? entryValue = _priceFrom(entry);
              final double? targetValue = _priceFrom(target);
              final double? liveValue = _priceFrom(currentPrice);

              final bool hasValidRange = slValue != null &&
                  entryValue != null &&
                  targetValue != null &&
                  (targetValue - slValue).abs() > 0.000001;

              final double entryProgress = hasValidRange
                  ? ((entryValue! - slValue!) / (targetValue! - slValue!))
                      .clamp(0.08, 0.88)
                      .toDouble()
                  : 90 / 310;
              final double liveProgress = hasValidRange && liveValue != null
                  ? ((liveValue - slValue!) / (targetValue! - slValue!))
                      .clamp(0.0, 1.0)
                      .toDouble()
                  : entryProgress + 0.12;

              final double slX = trackLeft;
              final double entryX = trackLeft + (trackW * entryProgress);
              final double targetX = trackRight;
              final double liveX = trackLeft + (trackW * liveProgress);

              final double distToTarget = targetX - entryX;
              final double distToSl = entryX - slX;

              final TimelineMarkerLabelPosition entryLabelPosition;
              if (distToTarget < 60) {
                entryLabelPosition = TimelineMarkerLabelPosition.leftOfDot;
              } else if (distToSl < 40) {
                entryLabelPosition = TimelineMarkerLabelPosition.rightOfDot;
              } else {
                entryLabelPosition = TimelineMarkerLabelPosition.standard;
              }

              return Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    left: slX,
                    top: lineY,
                    child: Container(
                      width: (entryX - slX).clamp(0.0, trackW),
                      height: thickness,
                      color: ColorConstants.red,
                    ),
                  ),
                  Positioned(
                    left: entryX,
                    top: lineY,
                    child: Container(
                      width: (targetX - entryX).clamp(0.0, trackW),
                      height: thickness,
                      color: ColorConstants.green,
                    ),
                  ),
                  _TimelineMarker(
                    x: slX,
                    label: 'SL',
                    dotTop: dotTop,
                    dotSize: dotSize,
                  ),
                  _TimelineMarker(
                    x: entryX,
                    label: 'Entry',
                    dotTop: dotTop,
                    dotSize: dotSize,
                    labelPosition: entryLabelPosition,
                  ),
                  _TimelineMarker(
                    x: targetX,
                    label: 'Target',
                    dotTop: dotTop,
                    dotSize: dotSize,
                    alignEnd: true,
                  ),
                  if (isLive) ...<Widget>[
                    Positioned(
                      left: liveX,
                      top: -AppSize.h(context, 7),
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, 0),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSize.h(context, 3),
                            horizontal: AppSize.w(context, 8),
                          ),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppSize.r(context, 8)),
                            gradient: const LinearGradient(
                              colors: <Color>[
                                ColorConstants.red,
                                ColorConstants.redBright,
                              ],
                            ),
                          ),
                          child: Text(
                            currentPrice != null
                                ? 'Live $currentPrice'
                                : 'Live',
                            style: TextStyle(
                              fontFamily: TextStyleConstants.fontFamilyDisplay,
                              fontWeight: FontWeight.w600,
                              fontSize: AppSize.sp(context, 11),
                              color: ColorConstants.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: liveX - (AppSize.r(context, 12) / 2),
                      top: (lineY + (thickness / 2)) -
                          (AppSize.r(context, 12) / 2),
                      child: Container(
                        width: AppSize.r(context, 12),
                        height: AppSize.r(context, 12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ColorConstants.red,
                          border: Border.all(
                            color: ColorConstants.white,
                            width: AppSize.r(context, 2),
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: ColorConstants.red.withValues(alpha: 0.35),
                              blurRadius: AppSize.r(context, 6),
                              offset: Offset(0, AppSize.h(context, 1)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        if (timestamp != null) ...<Widget>[
          SizedBox(height: AppSize.h(context, 6)),
          Text(
            timestamp!,
            style: TextStyleConstants.caption.copyWith(
              fontSize: AppSize.sp(context, 11),
              fontWeight: FontWeight.w500,
              color: ColorConstants.mute,
            ),
          ),
        ],
      ],
    );
  }
}

class _TimelineMarker extends StatelessWidget {
  const _TimelineMarker({
    required this.x,
    required this.label,
    required this.dotTop,
    required this.dotSize,
    this.alignEnd = false,
    this.labelPosition = TimelineMarkerLabelPosition.standard,
  });

  final double x;
  final String label;
  final double dotTop;
  final double dotSize;
  final bool alignEnd;
  final TimelineMarkerLabelPosition labelPosition;

  @override
  Widget build(BuildContext context) {
    if (labelPosition == TimelineMarkerLabelPosition.hidden) {
      return const SizedBox.shrink();
    }

    final double h = AppSize.h(context, 36);
    return SizedBox(
      width: double.infinity,
      height: h,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double labelTop = AppSize.h(context, 22);

          Widget labelWidget;
          if (alignEnd) {
            labelWidget = Positioned(
              right: constraints.maxWidth - x - (dotSize / 1),
              top: labelTop,
              child: Text(
                label,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: TextStyleConstants.fontFamilyDisplay,
                  fontWeight: FontWeight.w600,
                  fontSize: AppSize.sp(context, 10),
                  color: ColorConstants.navy,
                ),
              ),
            );
          } else if (labelPosition == TimelineMarkerLabelPosition.leftOfDot) {
            labelWidget = Positioned(
              right: constraints.maxWidth - x + 2,
              top: labelTop,
              child: Text(
                label,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: TextStyleConstants.fontFamilyDisplay,
                  fontWeight: FontWeight.w600,
                  fontSize: AppSize.sp(context, 10),
                  color: ColorConstants.navy,
                ),
              ),
            );
          } else if (labelPosition == TimelineMarkerLabelPosition.rightOfDot) {
            labelWidget = Positioned(
              left: x + (dotSize / 2) + 2,
              top: labelTop,
              child: Text(
                label,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontFamily: TextStyleConstants.fontFamilyDisplay,
                  fontWeight: FontWeight.w600,
                  fontSize: AppSize.sp(context, 10),
                  color: ColorConstants.navy,
                ),
              ),
            );
          } else {
            labelWidget = Positioned(
              left: x - AppSize.w(context, 10),
              top: labelTop,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: TextStyleConstants.fontFamilyDisplay,
                  fontWeight: FontWeight.w600,
                  fontSize: AppSize.sp(context, 10),
                  color: ColorConstants.navy,
                ),
              ),
            );
          }

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: <Widget>[
              Positioned(
                left: x - (dotSize / 2),
                top: dotTop,
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: ColorConstants.gray900,
                  ),
                ),
              ),
              labelWidget,
            ],
          );
        },
      ),
    );
  }
}
