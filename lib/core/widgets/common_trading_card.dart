import 'package:flutter/material.dart';
import '../../../../../shared/models/trading_card_data.dart';

import '../constants/asset_constants.dart';
import '../constants/color_constants.dart';
import '../constants/text_style_constants.dart';
import '../utils/app_size.dart';
import 'tapered_divider.dart';

/// Flutter equivalent of the Figma plugin's `tradeCard(d)` composition.
///
/// This widget is intended to be reused across Home/Discover/Trades screens.
class CommonTradingCard extends StatelessWidget {
  const CommonTradingCard({
    super.key,
    required this.data,
    this.onViewDetails,
  });

  final TradingCardData data;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    final bool hasDirection = data.dir != null;
    final bool isShort = data.dir == TradeDir.short;
    final bool isLoss = resolveTradingCardIsLoss(data);

    final bool compact = data.compact;
    final double wrapperTop = compact ? 0 : AppSize.h(context, 14);
    final double cardTopPadding = AppSize.h(context, 6);

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        if (!compact)
          Positioned(
            top: -4,
            left: AppSize.w(context, 14),
            right: AppSize.w(context, 25),
            child: _HangingTagsRow(
              segment: data.segment ?? 'Swing',
              asset: data.asset ?? 'Equity',
              analystName: data.analystName,
            ),
          ),
        Padding(
          padding: EdgeInsets.only(top: wrapperTop,),
          child: _CardBody(
            data: data,
            isLoss: isLoss,
            isShort: isShort,
            hasDirection: hasDirection,
            topPadding: cardTopPadding,
            onViewDetails: onViewDetails,
          ),
        ),
        if (!compact)
          Positioned(
            top: AppSize.h(context, 11),
            right: AppSize.w(context,-4),
            child: Semantics(
              button: true,
              selected: data.isSaved,
              label: data.isSaved ? 'Remove saved trade' : 'Save trade',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: data.onSaveTap,
                child: const _AnimatedBookmarkRibbon()),
              ),
            ),
      ],
    );
  }
}


class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.data,
    required this.isLoss,
    required this.isShort,
    required this.hasDirection,
    required this.topPadding,
    required this.onViewDetails,
  });

  final TradingCardData data;
  final bool isLoss;
  final bool isShort;
  final bool hasDirection;
  final double topPadding;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    final String statusText =
        data.tradeStatus ?? (isLoss ? 'Closed in loss' : 'In profit');
    final String estGain = data.estGain ?? (isLoss ? '-6.00%' : '+18.00%');
    final String liveRet = data.liveRet ?? (isLoss ? '-1.00x' : '+3.86%');

    final String px = data.currentPrice ?? data.cmp ?? data.entry ?? '₹0';
    final String chgDefault =
        isLoss ? '-₹17.40 (-1.18%)' : '+₹23.40 (+1.18%)';
    final String change = data.change ?? chgDefault;

    final String asset = data.asset ?? 'Equity';
    final String segment = data.segment ?? 'Swing';

    final BorderRadius radius = BorderRadius.circular(AppSize.r(context, 14));

    return Material(
      color: ColorConstants.white,
      elevation: 2,
      shadowColor: ColorConstants.navy.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: tradingCardBorderColor(isLoss),
          width: AppSize.r(context, 3.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onViewDetails,
        child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSize.w(context, 12),
          topPadding,
          AppSize.w(context, 12),
          AppSize.h(context, 12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (data.compact)
              Row(
                children: <Widget>[
                  _Pill(label: 'Analyst signal', kind: PillKind.warn),
                  SizedBox(width: AppSize.w(context, 6)),
                  if (hasDirection) ...<Widget>[
                    _Pill(
                      label: isShort ? 'SHORT' : 'LONG',
                      kind: isShort ? PillKind.short : PillKind.long,
                    ),
                    SizedBox(width: AppSize.w(context, 6)),
                  ],
                  _Pill(label: segment, kind: PillKind.blue),
                  SizedBox(width: AppSize.w(context, 6)),
                  _Pill(label: asset, kind: PillKind.live),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (hasDirection && !data.showLongSignal) ...<Widget>[
                    Row(
                      children: <Widget>[
                        _Pill(
                          label: isShort ? 'SHORT' : 'LONG',
                          kind: isShort ? PillKind.short : PillKind.long,
                        ),
                      ],
                    ),
                    SizedBox(height: AppSize.h(context, 8)),
                    _AccentRail(isLoss: isLoss),
                  ],
                ],
              ),
            SizedBox(height: AppSize.h(context, 6)),
            _InstrumentRow(
              symbol: data.symbol,
              // batchName: data.batchName ?? data.company,
              /// here i'll implement the complete name thing for the trade like HDFC BANK PRIVATE LIMITED
              px: px,
              change: change,
              isLoss: isLoss,
            ),
            SizedBox(height: AppSize.h(context, 10)),
            // _StatusBand(text: statusText, isLoss: isLoss),
            // SizedBox(height: AppSize.h(context, 12)),
            _TimelineLiveTag(
              currentPrice: px,
              entry: data.entry ?? '0',
              stopLoss: data.sl ?? '0',
              target: data.target ?? '0',
            ),
            SizedBox(height: AppSize.h(context, 10)),
            _StatsCard(
              estGain: estGain,
              liveRet: liveRet,
              themeIsLoss: isLoss,
            ),
            SizedBox(height: AppSize.h(context, 2)),
            _LevelsRow(
              entry: data.entry ?? '₹0',
              sl: data.sl ?? '₹0',
              target: data.target ?? '₹0',
            ),
            // if (data.rationale != null) ...<Widget>[
            //   // SizedBox(height: AppSize.h(context, 10)),
            //   // Text(
            //   //   'Analyst rationale',
            //   //   style: TextStyle(
            //   //     fontFamily: TextStyleConstants.fontFamilyDisplay,
            //   //     fontWeight: FontWeight.w600,
            //   //     fontSize: AppSize.sp(context, 11),
            //   //     color: ColorConstants.mute,
            //   //     height: 1.1,
            //   //   ),
            //   // ),
            //   // SizedBox(height: AppSize.h(context, 6)),
            //   // Text(
            //   //   data.rationale!,
            //   //   style: TextStyle(
            //   //     fontFamily: TextStyleConstants.fontFamilyDisplay,
            //   //     fontWeight: FontWeight.w500,
            //   //     fontSize: AppSize.sp(context, 12),
            //   //     color: ColorConstants.ink,
            //   //     height: 18 / AppSize.sp(context, 12),
            //   //   ),
            //   // ),
            // ],
            // SizedBox(height: AppSize.h(context, 10)),
            // CommonButtonWidget(
            //   label: 'Trade Now',
            //   onPressed: onViewDetails ?? () {},
            // ),
          ],
        ),
      ),
      ),
    );
  }
}

class _InstrumentRow extends StatelessWidget {
  const _InstrumentRow({
    required this.symbol,
    // required this.batchName,
    required this.px,
    required this.change,
    required this.isLoss,
  });

  final String symbol;
  // final String? batchName;
  final String px;
  final String change;
  final bool isLoss;

  @override
  Widget build(BuildContext context) {
    final String s = symbol.trim();
    final String initials =
        s.isEmpty ? 'TM' : s.substring(0, s.length >= 2 ? 2 : 1).toUpperCase();
    // final String batch = (batchName ?? '').trim().isEmpty
    //     ? 'Batch'
    //     : batchName!.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Avatar(initials: initials),
        SizedBox(width: AppSize.w(context, 10)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  symbol,
                  style: TextStyle(
                    fontFamily: TextStyleConstants.fontFamilyDisplay,
                    fontWeight: FontWeight.w600,
                    fontSize: AppSize.sp(context, 16),
                    color: ColorConstants.navy,
                  ),
                ),
              ),
              Text(
                "Complete Name",
                style: TextStyleConstants.body.copyWith(
                  fontSize: 10,
                ),
              )
              // _AnimatedBatchLabel(batchName: batch),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: AppSize.w(context, 14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                px,
                style: TextStyle(
                  fontFamily: TextStyleConstants.fontFamilyDisplay,
                  fontWeight: FontWeight.w600,
                  fontSize: AppSize.sp(context, 15),
                  color: ColorConstants.navy,
                ),
              ),
              SizedBox(height: AppSize.h(context, 2)),
              Text(
                change,
                style: TextStyle(
                  fontFamily: TextStyleConstants.fontFamilyDisplay,
                  fontWeight: FontWeight.w600,
                  fontSize: AppSize.sp(context, 11),
                  color: metricValueColor(change, themeIsLoss: isLoss),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedBatchLabel extends StatefulWidget {
  const _AnimatedBatchLabel({required this.batchName});

  final String batchName;

  @override
  State<_AnimatedBatchLabel> createState() => _AnimatedBatchLabelState();
}

class _AnimatedBatchLabelState extends State<_AnimatedBatchLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double iconSize = AppSize.r(context, 13);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Animated shimmer on the batch icon
        AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            return ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (Rect bounds) {
                final double slide = _controller.value * 2 - 0.5;
                return LinearGradient(
                  begin: Alignment(slide - 1, 0),
                  end: Alignment(slide + 1, 0),
                  colors: const <Color>[
                    ColorConstants.brandBlue,
                    ColorConstants.brandBlueLight,
                    ColorConstants.brandBlue,
                    ColorConstants.brandBlueLight,
                    ColorConstants.brandBlue,
                  ],
                  stops: const <double>[0.0, 0.3, 0.5, 0.7, 1.0],
                ).createShader(bounds);
              },
              child: child,
            );
          },
          child: Image.asset(
            AssetConstants.batchIcon,
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain,
            errorBuilder: (
              BuildContext context,
              Object error,
              StackTrace? stackTrace,
            ) {
              return Icon(
                Icons.layers_rounded,
                size: iconSize,
                color: ColorConstants.brandBlue,
              );
            },
          ),
        ),
        SizedBox(width: AppSize.w(context, 5)),
        // Animated shimmer on the batch name text
        Flexible(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? child) {
              final double slide = _controller.value * 2 - 0.5;
              return ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    begin: Alignment(slide - 1, 0),
                    end: Alignment(slide + 1, 0),
                    colors: const <Color>[
                      ColorConstants.brandBlue,
                      ColorConstants.brandBlueLight,
                      ColorConstants.brandBlue,
                      ColorConstants.brandBlueLight,
                      ColorConstants.brandBlue,
                    ],
                    stops: const <double>[0.0, 0.3, 0.5, 0.7, 1.0],
                  ).createShader(bounds);
                },
                child: child,
              );
            },
            child: Text(
              widget.batchName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: TextStyleConstants.fontFamilyBody,
                fontWeight: FontWeight.w600,
                fontSize: AppSize.sp(context, 11),
                color: ColorConstants.brandBlue,
                height: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    final double size = AppSize.r(context, 42);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            ColorConstants.avatarBlueStart,
            ColorConstants.avatarBlueEnd,
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: ColorConstants.navy.withValues(alpha: 0.08),
            blurRadius: AppSize.r(context, 12),
            offset: Offset(0, AppSize.h(context, 4)),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontFamily: TextStyleConstants.fontFamilyDisplay,
            fontWeight: FontWeight.w600,
            fontSize: AppSize.sp(context, 14),
            color: ColorConstants.white,
          ),
        ),
      ),
    );
  }
}

// class _StatusBand extends StatelessWidget {
//   const _StatusBand({required this.text, required this.isLoss});
//
//   final String text;
//   final bool isLoss;
//
//   @override
//   Widget build(BuildContext context) {
//     final Color top =
//         isLoss ? ColorConstants.lossBg : ColorConstants.profitBg;
//     final Color bottom =
//         isLoss ? ColorConstants.lossBgStrong : ColorConstants.profitBgStrong;
//     final Color fg = tradingCardThemeColor(isLoss);
//
//     return Container(
//       padding: EdgeInsets.symmetric(
//         vertical: AppSize.h(context, 10),
//         horizontal: AppSize.w(context, 12),
//       ),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(AppSize.r(context, 10)),
//         gradient: LinearGradient(
//           begin: Alignment.centerLeft,
//           end: Alignment.centerRight,
//           colors: <Color>[top, bottom],
//         ),
//       ),
//       child: Text(
//         'Trade status: $text',
//         textAlign: TextAlign.center,
//         style: TextStyle(
//           fontFamily: TextStyleConstants.fontFamilyDisplay,
//           fontWeight: FontWeight.w600,
//           fontSize: AppSize.sp(context, 13),
//           color: fg,
//         ),
//       ),
//     );
//   }
// }

class _TimelineLiveTag extends StatelessWidget {
  const _TimelineLiveTag({
    required this.currentPrice,
    required this.entry,
    required this.stopLoss,
    required this.target,
  });

  final String currentPrice;
  final String entry;
  final String stopLoss;
  final String target;

  static double? _priceFrom(String value) {
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

    return SizedBox(
      height: h,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double maxW = constraints.maxWidth;
          // Same inset on both sides so the track is visually centered.
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
              liveValue != null &&
              (targetValue - slValue).abs() > 0.000001;

          // SL maps to 0 and Target maps to 1. The same calculation works
          // for short trades because their price range is reversed.
          final double entryProgress = hasValidRange
              ? ((entryValue! - slValue!) / (targetValue! - slValue!))
                  .clamp(0.08, 0.92)
                  .toDouble()
              : 90 / 310;
          final double liveProgress = hasValidRange
              ? ((liveValue! - slValue!) / (targetValue! - slValue!))
                  .clamp(0.0, 1.0)
                  .toDouble()
              : entryProgress;

          // SL —— Entry —— Target proportions along the track.
          final double slX = trackLeft;
          final double entryX = trackLeft + (trackW * entryProgress);
          final double targetX = trackRight;
          final double liveX = trackLeft + (trackW * liveProgress);
          final double liveLabelX = liveX
              .clamp(
                trackLeft + AppSize.w(context, 18),
                trackRight - AppSize.w(context, 18),
              )
              .toDouble();

          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                left: slX,
                top: lineY,
                child: Container(
                  width: entryX - slX,
                  height: thickness,
                  color: ColorConstants.red,
                ),
              ),
              Positioned(
                left: entryX,
                top: lineY,
                child: Container(
                  width: targetX - entryX,
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
              ),
              _TimelineMarker(
                x: targetX,
                label: 'Target',
                dotTop: dotTop,
                dotSize: dotSize,
                alignEnd: true,
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                left: liveLabelX,
                top: -AppSize.h(context, 12),
                child: FractionalTranslation(
                  translation: const Offset(-0.5, 0),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: AppSize.h(context, 3),
                      horizontal: AppSize.w(context, 8),
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSize.r(context, 8)),
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: <Color>[
                          ColorConstants.red,
                          ColorConstants.redBright,
                        ],
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 140),
                      child: Text(
                        'Live $currentPrice',
                        key: ValueKey<String>(currentPrice),
                        style: TextStyle(
                          fontFamily: TextStyleConstants.fontFamilyDisplay,
                          fontWeight: FontWeight.w600,
                          fontSize: AppSize.sp(context, 10),
                          color: ColorConstants.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                left: liveX - (AppSize.r(context, 12) / 2),
                top: (lineY + (thickness / 2)) - (AppSize.r(context, 12) / 2),
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
          );
        },
      ),
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
  });

  final double x;
  final String label;
  final double dotTop;
  final double dotSize;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final double h = AppSize.h(context, 36);
    return SizedBox(
      width: double.infinity,
      height: h,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double labelTop = AppSize.h(context, 22);

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
              if (alignEnd)
                Positioned(
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
                )
              else
                Positioned(
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
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.estGain,
    required this.liveRet,
    required this.themeIsLoss,
  });

  final String estGain;
  final String liveRet;
  final bool themeIsLoss;

  @override
  Widget build(BuildContext context) {
    final Color estColor =
        metricValueColor(estGain, themeIsLoss: themeIsLoss);
    final Color liveColor =
        metricValueColor(liveRet, themeIsLoss: themeIsLoss);

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _MetricCell(
                label: 'Estimated gains',
                value: estGain,
                valueColor: estColor,
                alignEnd: false,
              ),
            ),
            const TaperedVerticalDivider(),
            Expanded(
              child: _MetricCell(
                label: 'Live returns',
                value: liveRet,
                valueColor: liveColor,
                alignEnd: true,
              ),
            ),
          ],
        ),
        const TaperedHorizontalDivider(),
      ],
    );
  }
}

class _LevelsRow extends StatelessWidget {
  const _LevelsRow({
    required this.entry,
    required this.sl,
    required this.target,
  });

  final String entry;
  final String sl;
  final String target;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _MetricCell(
            label: 'Entry',
            value: entry,
            valueColor: ColorConstants.navy,
            alignEnd: false,
          ),
        ),
        const TaperedVerticalDivider(),
        Expanded(
          child: _MetricCell(
            label: 'Stop loss',
            value: sl,
            valueColor: ColorConstants.navy,
            alignEnd: false,
            center: true,
          ),
        ),
        const TaperedVerticalDivider(),
        Expanded(
          child: _MetricCell(
            label: 'Target',
            value: target,
            valueColor: ColorConstants.navy,
            alignEnd: true,
          ),
        ),
      ],
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.alignEnd,
    this.center = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool alignEnd;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final CrossAxisAlignment cross = center
        ? CrossAxisAlignment.center
        : (alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start);
    final TextAlign textAlign = center
        ? TextAlign.center
        : (alignEnd ? TextAlign.right : TextAlign.left);

    return Padding(
      padding: AppSize.symmetric(context, horizontal: 8, vertical: 2),
      child: Column(
        crossAxisAlignment: cross,
        children: <Widget>[
          Text(
            label,
            textAlign: textAlign,
            style: TextStyle(
              fontFamily: TextStyleConstants.fontFamilyBody,
              fontWeight: FontWeight.w500,
              fontSize: AppSize.sp(context, 10),
              color: ColorConstants.mute,
            ),
          ),
          SizedBox(height: AppSize.h(context, 1)),
          Text(
            value,
            textAlign: textAlign,
            style: TextStyle(
              fontFamily: TextStyleConstants.fontFamilyDisplay,
              fontWeight: FontWeight.w600,
              fontSize: AppSize.sp(context, 15),
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccentRail extends StatelessWidget {
  const _AccentRail({required this.isLoss});

  final bool isLoss;

  @override
  Widget build(BuildContext context) {
    final Color left =
        isLoss ? ColorConstants.redLight : ColorConstants.greenLight;
    final Color right =
        isLoss ? ColorConstants.redBright : ColorConstants.greenBright;

    return Container(
      width: AppSize.w(context, 100),
      height: AppSize.h(context, 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.r(context, 2)),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[left, right],
        ),
      ),
    );
  }
}

enum PillKind {
  sebi,
  long,
  short,
  buy,
  sell,
  live,
  warn,
  blue,
  mute,
  risk,
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.kind,
  });

  final String label;
  final PillKind kind;

  @override
  Widget build(BuildContext context) {
    final _PillColors c = _pillColors(kind);

    final bool showCheck =
        kind == PillKind.sebi || kind == PillKind.long || kind == PillKind.buy;
    final bool showLiveDot = kind == PillKind.live;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: AppSize.h(context, 5),
        horizontal: AppSize.w(context, 9),
      ),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (showCheck)
            Icon(
              Icons.check_rounded,
              size: AppSize.r(context, 11),
              color: c.fg,
            ),
          if (showLiveDot)
            Container(
              width: AppSize.r(context, 6),
              height: AppSize.r(context, 6),
              decoration: BoxDecoration(
                color: c.fg,
                shape: BoxShape.circle,
              ),
            ),
          SizedBox(width: AppSize.w(context, 5)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: TextStyleConstants.fontFamilyDisplay,
              fontWeight: FontWeight.w600,
              fontSize: AppSize.sp(context, 10),
              color: c.fg,
            ),
          ),
        ],
      ),
    );
  }

  static _PillColors _pillColors(PillKind kind) {
    switch (kind) {
      case PillKind.sebi:
      case PillKind.long:
      case PillKind.buy:
        return _PillColors(
          bg: ColorConstants.pillSuccessBg,
          fg: ColorConstants.green,
        );
      case PillKind.short:
      case PillKind.sell:
        return _PillColors(
          bg: ColorConstants.riskHighBg,
          fg: ColorConstants.red,
        );
      case PillKind.live:
      case PillKind.blue:
        return _PillColors(
          bg: ColorConstants.liveBg,
          fg: ColorConstants.brandBlue,
        );
      case PillKind.warn:
      case PillKind.risk:
        return _PillColors(
          bg: ColorConstants.warnBg,
          fg: ColorConstants.amber,
        );
      case PillKind.mute:
        return _PillColors(
          bg: ColorConstants.pillNeutralBg,
          fg: ColorConstants.mute,
        );
    }
  }
}

class _PillColors {
  const _PillColors({required this.bg, required this.fg});
  final Color bg;
  final Color fg;

}

class _HangingTagsRow extends StatelessWidget {
  const _HangingTagsRow({
    required this.segment,
    required this.asset,
    this.analystName,
  });

  final String segment;
  final String asset;
  final String? analystName;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        if (analystName != null && analystName!.trim().isNotEmpty)
          _HangingGradientTag(
            label: analystName!,
            start: ColorConstants.gradientSignalStart,
            end: ColorConstants.gradientSignalEnd,
            showDot: false,
          ),
        // LEFT — analyst name tag (only shown when present)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _HangingGradientTag(
              label: segment,
              start: ColorConstants.gradientBlueStart,
              end: ColorConstants.gradientBlueEnd,
              showDot: false,
            ),
            SizedBox(width: AppSize.w(context, 5)),
            _HangingGradientTag(
              label: asset,
              start: ColorConstants.gradientEquityStart,
              end: ColorConstants.gradientEquityEnd,
              showDot: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _HangingGradientTag extends StatelessWidget {
  const _HangingGradientTag({
    required this.label,
    required this.start,
    required this.end,
    required this.showDot,
  });

  final String label;
  final Color start;
  final Color end;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSize.w(context, 9),
        right: AppSize.w(context, 9),
        top: AppSize.h(context, 5),
        bottom: AppSize.h(context, 9),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[start, end],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSize.r(context, 8)),
          topRight: Radius.circular(AppSize.r(context, 8)),
          bottomLeft: Radius.circular(AppSize.r(context, 3)),
          bottomRight: Radius.circular(AppSize.r(context, 3)),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: end.withValues(alpha: 0.32),
            blurRadius: AppSize.r(context, 8),
            offset: Offset(0, AppSize.h(context, 3)),
          ),
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
          if (showDot)
            Container(
              width: AppSize.r(context, 5),
              height: AppSize.r(context, 5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: ColorConstants.white,
              ),
            ),
          SizedBox(width: AppSize.w(context, 4)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: TextStyleConstants.fontFamilyDisplay,
              fontWeight: FontWeight.w600,
              fontSize: AppSize.sp(context, 9.5),
              color: ColorConstants.white,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedBookmarkRibbon extends StatefulWidget {
  const _AnimatedBookmarkRibbon();

  @override
  State<_AnimatedBookmarkRibbon> createState() =>
      _AnimatedBookmarkRibbonState();
}

class _AnimatedBookmarkRibbonState extends State<_AnimatedBookmarkRibbon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: Image.asset(
        AssetConstants.bookmarkIcon,
        width: AppSize.r(context, 32),
        height: AppSize.r(context, 32),
        fit: BoxFit.contain,
      ),
      builder: (BuildContext context, Widget? child) {
        final double sweep = (_controller.value * 2.4) - 1.2;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (Rect bounds) => LinearGradient(
            begin: Alignment(sweep - 1, -1),
            end: Alignment(sweep + 1, 1),
            colors: const <Color>[
              ColorConstants.navy,
              ColorConstants.brandBlue,
              ColorConstants.brandBlueLight,
              ColorConstants.gradientEquityEnd,
              ColorConstants.brandBlue,
              ColorConstants.navy,
            ],
            stops: const <double>[0, 0.25, 0.43, 0.55, 0.75, 1],
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}
