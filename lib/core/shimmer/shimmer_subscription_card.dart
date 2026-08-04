import 'package:flutter/material.dart';

import '../constants/color_constants.dart';
import '../utils/app_size.dart';
import 'shimmer.dart';

/// Skeleton that mirrors the shape of the subscription card in
/// MySubscriptionsPage and HomeSubscriptionsStrip detail view.
class ShimmerSubscriptionCard extends StatelessWidget {
  const ShimmerSubscriptionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSize.insets(context, left: 14, right: 14, top: 14, bottom: 14),
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(AppSize.r(context, 16)),
        border: Border.all(color: ColorConstants.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // avatar + name + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ShimmerBox(
                width: AppSize.r(context, 44),
                height: AppSize.r(context, 44),
                isCircle: true,
              ),
              SizedBox(width: AppSize.w(context, 11)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ShimmerBox(
                      width: AppSize.w(context, 140),
                      height: AppSize.h(context, 13),
                      borderRadius: 5,
                    ),
                    SizedBox(height: AppSize.h(context, 6)),
                    ShimmerBox(
                      width: AppSize.w(context, 110),
                      height: AppSize.h(context, 10),
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
              ShimmerBox(
                width: AppSize.w(context, 58),
                height: AppSize.h(context, 20),
                borderRadius: 20,
              ),
            ],
          ),
          SizedBox(height: AppSize.h(context, 12)),
          const Divider(height: 1, color: ColorConstants.line),
          SizedBox(height: AppSize.h(context, 12)),
          // date row
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ShimmerBox(
                      width: AppSize.w(context, 50),
                      height: AppSize.h(context, 10),
                      borderRadius: 4,
                    ),
                    SizedBox(height: AppSize.h(context, 5)),
                    ShimmerBox(
                      width: AppSize.w(context, 90),
                      height: AppSize.h(context, 12),
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    ShimmerBox(
                      width: AppSize.w(context, 60),
                      height: AppSize.h(context, 10),
                      borderRadius: 4,
                    ),
                    SizedBox(height: AppSize.h(context, 5)),
                    ShimmerBox(
                      width: AppSize.w(context, 90),
                      height: AppSize.h(context, 12),
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSize.h(context, 10)),
          // amount row
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ShimmerBox(
                      width: AppSize.w(context, 40),
                      height: AppSize.h(context, 10),
                      borderRadius: 4,
                    ),
                    SizedBox(height: AppSize.h(context, 5)),
                    ShimmerBox(
                      width: AppSize.w(context, 70),
                      height: AppSize.h(context, 12),
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    ShimmerBox(
                      width: AppSize.w(context, 70),
                      height: AppSize.h(context, 10),
                      borderRadius: 4,
                    ),
                    SizedBox(height: AppSize.h(context, 5)),
                    ShimmerBox(
                      width: AppSize.w(context, 60),
                      height: AppSize.h(context, 12),
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Scrollable list of [ShimmerSubscriptionCard]s wrapped in [ShimmerScope].
class ShimmerSubscriptionList extends StatelessWidget {
  const ShimmerSubscriptionList({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ShimmerScope(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: AppSize.h(context, 24)),
        itemCount: count,
        separatorBuilder: (_, __) => SizedBox(height: AppSize.h(context, 12)),
        itemBuilder: (_, __) => const ShimmerSubscriptionCard(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Strip shimmer — mirrors the small _SubscriptionCard pill used in
// HomeSubscriptionsStrip (circle avatar + name + date, fixed height 58).
// ─────────────────────────────────────────────────────────────────────────────

/// Single shimmer pill that mirrors the shape of the subscription strip card.
class ShimmerSubscriptionStripItem extends StatelessWidget {
  const ShimmerSubscriptionStripItem({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSize.w(context, 148),
      child: Container(
        padding: AppSize.insets(context, left: 10, right: 10, top: 10, bottom: 10),
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
          border: Border.all(color: ColorConstants.line),
        ),
        child: Row(
          children: <Widget>[
            // avatar circle
            ShimmerBox(
              width: AppSize.r(context, 36),
              height: AppSize.r(context, 36),
              isCircle: true,
            ),
            SizedBox(width: AppSize.w(context, 8)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ShimmerBox(
                    width: double.infinity,
                    height: AppSize.h(context, 11),
                    borderRadius: 4,
                  ),
                  SizedBox(height: AppSize.h(context, 5)),
                  ShimmerBox(
                    width: AppSize.w(context, 54),
                    height: AppSize.h(context, 9),
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal shimmer row of [ShimmerSubscriptionStripItem]s wrapped in
/// [ShimmerScope]. Matches the 62-pt height of the real strip.
class ShimmerSubscriptionStrip extends StatelessWidget {
  const ShimmerSubscriptionStrip({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSize.h(context, 62),
      child: ShimmerScope(
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: count,
          separatorBuilder: (_, __) => SizedBox(width: AppSize.w(context, 10)),
          itemBuilder: (_, __) => const ShimmerSubscriptionStripItem(),
        ),
      ),
    );
  }
}
