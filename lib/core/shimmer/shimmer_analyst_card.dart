import 'package:flutter/material.dart';

import '../constants/color_constants.dart';
import '../utils/app_size.dart';
import '../utils/responsive_layout.dart';
import 'shimmer.dart';

/// Skeleton that mirrors the shape of DiscoverAnalystCard.
/// Wrap a list of these in ShimmerScope so all animate together.
class ShimmerAnalystCard extends StatelessWidget {
  const ShimmerAnalystCard({super.key});

  @override
  Widget build(BuildContext context) {
    final r = AppSize.r(context, 16);
    // Match hanging-tag reserve on the real DiscoverAnalystCard.
    final tagLane = AppSize.h(context, 14);
    return Padding(
      padding: EdgeInsets.only(top: tagLane),
      child: Container(
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
          top: 12,
          bottom: 14,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Transform.translate(
              offset: Offset(0, -AppSize.h(context, 22)),
              child: Row(
                children: <Widget>[
                  ShimmerBox(
                    width: AppSize.w(context, 52),
                    height: AppSize.h(context, 18),
                    borderRadius: 6,
                  ),
                  SizedBox(width: AppSize.w(context, 5)),
                  ShimmerBox(
                    width: AppSize.w(context, 40),
                    height: AppSize.h(context, 18),
                    borderRadius: 6,
                  ),
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
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
                      ShimmerBox(
                        width: AppSize.w(context, 140),
                        height: AppSize.h(context, 14),
                        borderRadius: 5,
                      ),
                      SizedBox(height: AppSize.h(context, 7)),
                      ShimmerBox(
                        width: AppSize.w(context, 110),
                        height: AppSize.h(context, 10),
                        borderRadius: 4,
                      ),
                      SizedBox(height: AppSize.h(context, 6)),
                      ShimmerBox(
                        width: AppSize.w(context, 80),
                        height: AppSize.h(context, 9),
                        borderRadius: 4,
                      ),
                    ],
                  ),
                ),
                ShimmerBox(
                  width: AppSize.r(context, 18),
                  height: AppSize.r(context, 18),
                  borderRadius: 4,
                ),
              ],
            ),
            SizedBox(height: AppSize.h(context, 14)),
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
      ),
    );
  }
}

class _MetricCellShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          ShimmerBox(
            width: AppSize.r(context, 16),
            height: AppSize.r(context, 16),
            isCircle: true,
          ),
          SizedBox(height: AppSize.h(context, 5)),
          ShimmerBox(
            width: AppSize.w(context, 48),
            height: AppSize.h(context, 14),
            borderRadius: 4,
          ),
          SizedBox(height: AppSize.h(context, 4)),
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

/// List/grid of [ShimmerAnalystCard]s matching Discover layout on web.
class ShimmerAnalystList extends StatelessWidget {
  const ShimmerAnalystList({super.key, this.count = 4, this.padding});

  final int count;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveLayout.cardGridColumns(context);

    if (columns > 1) {
      final itemCount = columns * 2;
      return ShimmerScope(
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          clipBehavior: Clip.none,
          padding: padding ??
              EdgeInsets.only(
                top: AppSize.h(context, 18),
                bottom: AppSize.h(context, 24),
              ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 20,
            crossAxisSpacing: 16,
            mainAxisExtent: columns >= 3 ? 172 : 180,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) => const Align(
            alignment: Alignment.topCenter,
            child: ShimmerAnalystCard(),
          ),
        ),
      );
    }

    return ShimmerScope(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding ??
            EdgeInsets.only(
              top: AppSize.h(context, 6),
              bottom: AppSize.h(context, 88),
            ),
        itemCount: count,
        separatorBuilder: (context, index) =>
            SizedBox(height: AppSize.h(context, 20)),
        itemBuilder: (context, index) => const ShimmerAnalystCard(),
      ),
    );
  }
}
