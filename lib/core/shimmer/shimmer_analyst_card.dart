import 'package:flutter/material.dart';

import '../constants/color_constants.dart';
import '../utils/app_size.dart';
import 'shimmer.dart';

/// Skeleton that mirrors the shape of DiscoverAnalystCard.
/// Wrap a list of these in ShimmerScope so all animate together.
class ShimmerAnalystCard extends StatelessWidget {
  const ShimmerAnalystCard({super.key});

  @override
  Widget build(BuildContext context) {
    final r = AppSize.r(context, 16);
    return Container(
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(
          color: ColorConstants.navy.withValues(alpha: 0.08),
        ),
      ),
      padding: AppSize.insets(
        context,
        left: 14,
        right: 12,
        top: 14,
        bottom: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // avatar + name/subtitle + chevron
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // avatar circle
              ShimmerBox(
                width: AppSize.r(context, 52),
                height: AppSize.r(context, 52),
                isCircle: true,
              ),
              SizedBox(width: AppSize.w(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // name line
                    ShimmerBox(
                      width: AppSize.w(context, 140),
                      height: AppSize.h(context, 14),
                      borderRadius: 5,
                    ),
                    SizedBox(height: AppSize.h(context, 7)),
                    // subtitle line
                    ShimmerBox(
                      width: AppSize.w(context, 110),
                      height: AppSize.h(context, 10),
                      borderRadius: 4,
                    ),
                    SizedBox(height: AppSize.h(context, 6)),
                    // SEBI reg line
                    ShimmerBox(
                      width: AppSize.w(context, 80),
                      height: AppSize.h(context, 9),
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
              // chevron placeholder
              ShimmerBox(
                width: AppSize.r(context, 18),
                height: AppSize.r(context, 18),
                borderRadius: 4,
              ),
            ],
          ),
          SizedBox(height: AppSize.h(context, 14)),
          // metrics row: win rate | avg p&l | subscribers
          Row(
            children: <Widget>[
              _MetricCellShimmer(),
              SizedBox(width: AppSize.w(context, 2)),
              _MetricCellShimmer(),
              SizedBox(width: AppSize.w(context, 2)),
              _MetricCellShimmer(),
            ],
          ),
        ],
      ),
    );
  }
}

/// One column of the three-metric row inside ShimmerAnalystCard.
class _MetricCellShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          // icon
          ShimmerBox(
            width: AppSize.r(context, 16),
            height: AppSize.r(context, 16),
            isCircle: true,
          ),
          SizedBox(height: AppSize.h(context, 5)),
          // value
          ShimmerBox(
            width: AppSize.w(context, 48),
            height: AppSize.h(context, 14),
            borderRadius: 4,
          ),
          SizedBox(height: AppSize.h(context, 4)),
          // label
          ShimmerBox(
            width: AppSize.w(context, 40),
            height: AppSize.h(context, 9),
            borderRadius: 3,
          ),
        ],
      ),
    );
  }
}

/// Scrollable list of [ShimmerAnalystCard]s wrapped in a [ShimmerScope].
class ShimmerAnalystList extends StatelessWidget {
  const ShimmerAnalystList({super.key, this.count = 4, this.padding});

  final int count;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ShimmerScope(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding ??
            EdgeInsets.only(
              top: AppSize.h(context, 6),
              bottom: AppSize.h(context, 88),
            ),
        itemCount: count,
        separatorBuilder: (_, __) => SizedBox(height: AppSize.h(context, 20)),
        itemBuilder: (_, __) => const ShimmerAnalystCard(),
      ),
    );
  }
}
