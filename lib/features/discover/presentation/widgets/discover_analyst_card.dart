import 'package:flutter/material.dart';

import '../../../../core/constants/asset_constants.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/sebi_verified_pill.dart';
import '../../../../core/widgets/segment_tag_chip.dart';

class DiscoverAnalystData {
  const DiscoverAnalystData({
    required this.name,
    required this.initials,
    required this.sebi,
    required this.subtitle,
    required this.winRate,
    required this.avgPnl,
    required this.subscribers,
    required this.tags,
    required this.avatarStart,
    required this.avatarEnd,
  });

  final String name;
  final String initials;
  final String sebi;
  final String subtitle;
  final String winRate;
  final String avgPnl;
  final String subscribers;
  final List<String> tags;
  final Color avatarStart;
  final Color avatarEnd;
}

class DiscoverAnalystCard extends StatelessWidget {
  const DiscoverAnalystCard({
    required this.data,
    super.key,
    this.onTap,
  });

  final DiscoverAnalystData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool pnlNegative = data.avgPnl.startsWith('-');
    final radius = AppSize.r(context, 16);
    final hasTags = data.tags.isNotEmpty;
    final wrapperTop = hasTags ? AppSize.h(context, 14) : 0.0;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        if (hasTags)
          Positioned(
            top: -4,
            left: AppSize.w(context, 14),
            child: HangingSegmentTagsRow(tags: data.tags),
          ),
        Padding(
          padding: EdgeInsets.only(top: wrapperTop),
          child: Material(
            color: ColorConstants.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
              side: BorderSide(
                color: ColorConstants.navy.withValues(alpha: 0.08),
              ),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(radius),
              child: Ink(
                decoration: BoxDecoration(
                  color: ColorConstants.white,
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: ColorConstants.navy.withValues(alpha: 0.07),
                      blurRadius: AppSize.r(context, 18),
                      offset: Offset(0, AppSize.h(context, 6)),
                    ),
                  ],
                ),
                child: Padding(
                  padding: AppSize.insets(
                    context,
                    left: 14,
                    right: 12,
                    top: hasTags ? 12 : 14,
                    bottom: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _Avatar(
                            initials: data.initials,
                            start: data.avatarStart,
                            end: data.avatarEnd,
                            size: 52,
                          ),
                          SizedBox(width: AppSize.w(context, 12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        data.name,
                                        style: TextStyleConstants.cardTitle
                                            .copyWith(
                                          fontSize: AppSize.sp(context, 16),
                                          height: 1.2,
                                          color: ColorConstants.ink,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: AppSize.w(context, 6)),
                                    const SebiVerifiedPill(compact: true),
                                  ],
                                ),
                                SizedBox(height: AppSize.h(context, 5)),
                                Text(
                                  data.subtitle,
                                  style: TextStyleConstants.bodyMedium.copyWith(
                                    fontSize: AppSize.sp(context, 12.5),
                                    color: ColorConstants.mute,
                                    height: 1.35,
                                  ),
                                ),
                                SizedBox(height: AppSize.h(context, 4)),
                                Text(
                                  data.sebi,
                                  style: TextStyleConstants.caption.copyWith(
                                    fontSize: AppSize.sp(context, 11),
                                    fontWeight: FontWeight.w600,
                                    color: ColorConstants.brandBlue,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding:
                                EdgeInsets.only(top: AppSize.h(context, 4)),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: AppSize.r(context, 22),
                              color: ColorConstants.soft,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSize.h(context, 14)),
                      Row(
                        children: <Widget>[
                          _MetricCell(
                            value: data.winRate,
                            label: 'Win rate',
                            valueColor: ColorConstants.green,
                            iconAsset: AssetConstants.winRateAnalystCard,
                          ),
                          _MetricDivider(),
                          _MetricCell(
                            value: data.avgPnl,
                            label: 'Avg P&L',
                            valueColor: pnlNegative
                                ? ColorConstants.red
                                : ColorConstants.green,
                            iconAsset: AssetConstants.avgPlAnalystCard,
                          ),
                          _MetricDivider(),
                          _MetricCell(
                            value: data.subscribers,
                            label: 'Subscribers',
                            valueColor: ColorConstants.ink,
                            iconAsset:
                                AssetConstants.subscribersAnalystCard,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.initials,
    required this.start,
    required this.end,
    required this.size,
  });

  final String initials;
  final Color start;
  final Color end;
  final double size;

  @override
  Widget build(BuildContext context) {
    final resolved = AppSize.r(context, size);
    return Container(
      width: resolved,
      height: resolved,
      padding: EdgeInsets.all(AppSize.r(context, 2.5)),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorConstants.white,
        border: Border.all(
          color: ColorConstants.brandBlueLight.withValues(alpha: 0.55),
          width: AppSize.r(context, 1.5),
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[start, end],
          ),
        ),
        child: Center(
          child: Text(
            initials,
            style: TextStyleConstants.cardTitleSmall.copyWith(
              color: ColorConstants.white,
              fontSize: AppSize.sp(context, size * 0.28),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: AppSize.h(context, 36),
      margin: AppSize.symmetric(context, horizontal: 2),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            ColorConstants.transparent,
            ColorConstants.line,
            ColorConstants.transparent,
          ],
        ),
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.value,
    required this.label,
    required this.valueColor,
    required this.iconAsset,
  });

  final String value;
  final String label;
  final Color valueColor;
  final String iconAsset;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Image.asset(
            iconAsset,
            width: AppSize.r(context, 16),
            height: AppSize.r(context, 16),
            fit: BoxFit.contain,
            color: valueColor,
            colorBlendMode: BlendMode.srcIn,
            filterQuality: FilterQuality.high,
          ),
          SizedBox(height: AppSize.h(context, 4)),
          Text(
            value,
            style: TextStyleConstants.numeric.copyWith(
              fontSize: AppSize.sp(context, 15),
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
          SizedBox(height: AppSize.h(context, 2)),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyleConstants.caption.copyWith(
              fontSize: AppSize.sp(context, 10),
              fontWeight: FontWeight.w600,
              color: ColorConstants.mute,
            ),
          ),
        ],
      ),
    );
  }
}
