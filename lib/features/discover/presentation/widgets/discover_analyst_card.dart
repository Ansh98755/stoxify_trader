import 'package:flutter/material.dart';
import 'package:stoxify/core/widgets/tapered_divider.dart';

import '../../../../core/constants/asset_constants.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/sebi_verified_pill.dart';
import '../../../../core/widgets/segment_tag_chip.dart';

class DiscoverAnalystData {
  const DiscoverAnalystData({
    required this.userId,
    required this.name,
    required this.initials,
    required this.sebi,
    required this.subtitle,
    required this.winRate,
    required this.avgPnl,
    required this.experienceYears,
    required this.totalTrades,
    required this.winTrades,
    required this.avgReturn,
    required this.tags,
    required this.avatarStart,
    required this.avatarEnd,
    this.profilePicUrl,
  });

  final String userId;
  final String name;
  final String initials;
  final String? sebi;
  final String subtitle;
  final String? profilePicUrl;
  final String winRate;
  final String avgPnl;
  final String experienceYears;
  final String totalTrades;
  final String winTrades;
  final String avgReturn;
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
    final bool avgReturnNegative = data.avgReturn.startsWith('-');
    final bool avgReturnMissing = data.avgReturn == 'N/A';
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
                            imageUrl: data.profilePicUrl,
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
                                          height: 1,
                                          color: ColorConstants.ink,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: AppSize.w(context, 6)),
                                    if (data.sebi != null)
                                      const SebiVerifiedPill(compact: true),
                                  ],
                                ),
                                if (data.subtitle.isNotEmpty) ...<Widget>[
                                  // SizedBox(height: AppSize.h(context, 5)),
                                  Text(
                                    data.subtitle,
                                    style:
                                        TextStyleConstants.bodyMedium.copyWith(
                                      fontSize: AppSize.sp(context, 12.5),
                                      color: ColorConstants.mute,
                                      height: 1,
                                    ),
                                  ),
                                ],
                                if (data.sebi != null) ...<Widget>[
                                  SizedBox(height: AppSize.h(context, 4)),
                                  Text(
                                    data.sebi!,
                                    style:
                                        TextStyleConstants.caption.copyWith(
                                      fontSize: AppSize.sp(context, 11),
                                      fontWeight: FontWeight.w600,
                                      color: ColorConstants.brandBlue,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
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
                      SizedBox(height: AppSize.h(context, 8)),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: ColorConstants.soft,
                            width: 0.5
                          )
                        ),
                        // color: ColorConstants.soft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical:8),
                          child: Column(
                                                children: [
                                                  // Center(
                                                  //   child: Text(
                                                  //     "Performance Metrix",
                                                  //     style: TextStyleConstants.bodySmall.copyWith(color: ColorConstants.ink,fontSize: 14),
                                                  //   ),
                                                  // ),
                                                  // SizedBox(height: AppSize.h(context, 6)),

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
                              value: data.experienceYears,
                              label: 'Yrs experience',
                              valueColor: ColorConstants.ink,
                              iconAsset:
                                  AssetConstants.subscribersAnalystCard,
                            ),
                          ],
                                                ),
                                                SizedBox(height: AppSize.h(context, 6)),
                                                TaperedHorizontalDivider(),
                                                SizedBox(height: AppSize.h(context, 6)),
                                                Row(
                          children: <Widget>[
                            _MetricCell(
                              value: data.totalTrades,
                              label: 'Total trades',
                              valueColor: data.totalTrades == 'N/A'
                                  ? ColorConstants.soft
                                  : ColorConstants.ink,
                              icon: Icons.candlestick_chart_outlined,
                            ),
                            _MetricDivider(),
                            _MetricCell(
                              value: data.winTrades,
                              label: 'Win trades',
                              valueColor: data.winTrades == 'N/A'
                                  ? ColorConstants.soft
                                  : ColorConstants.green,
                              icon: Icons.emoji_events_outlined,
                            ),
                            _MetricDivider(),
                            _MetricCell(
                              value: data.avgReturn,
                              label: 'Avg return',
                              valueColor: avgReturnMissing
                                  ? ColorConstants.soft
                                  : avgReturnNegative
                                      ? ColorConstants.red
                                      : ColorConstants.green,
                              icon: Icons.trending_up_rounded,
                            ),
                          ],
                                                ),
                                                ],
                          ),
                        ),
                      )
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
    required this.imageUrl,
    required this.start,
    required this.end,
    required this.size,
  });

  final String initials;
  final String? imageUrl;
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
        child: ClipOval(
          child: imageUrl != null
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _AvatarInitials(
                    initials: initials,
                    size: size,
                  ),
                )
              : _AvatarInitials(
                  initials: initials,
                  size: size,
                ),
        ),
      ),
    );
  }
}

class _AvatarInitials extends StatelessWidget {
  const _AvatarInitials({
    required this.initials,
    required this.size,
  });

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: TextStyleConstants.cardTitleSmall.copyWith(
          color: ColorConstants.white,
          fontSize: AppSize.sp(context, size * 0.28),
          fontWeight: FontWeight.w700,
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
    this.iconAsset,
    this.icon,
  }) : assert(
          iconAsset != null || icon != null,
          'Provide either iconAsset or icon',
        );

  final String value;
  final String label;
  final Color valueColor;
  final String? iconAsset;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final iconSize = AppSize.r(context, 16);
    return Expanded(
      child: Column(
        children: <Widget>[
          if (iconAsset != null)
            Image.asset(
              iconAsset!,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
              color: valueColor,
              colorBlendMode: BlendMode.srcIn,
              filterQuality: FilterQuality.high,
            )
          else
            Icon(
              icon,
              size: iconSize,
              color: valueColor,
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