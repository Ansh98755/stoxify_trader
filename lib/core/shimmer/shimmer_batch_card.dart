import 'package:flutter/material.dart';

import '../constants/color_constants.dart';
import '../utils/app_size.dart';
import 'shimmer.dart';

/// Skeleton that mirrors the shape of CommonBatchCard.
class ShimmerBatchCard extends StatelessWidget {
  const ShimmerBatchCard({super.key});

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
      padding: AppSize.insets(context, left: 14, right: 14, top: 14, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // name + risk badge row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ShimmerBox(
                      width: AppSize.w(context, 160),
                      height: AppSize.h(context, 14),
                      borderRadius: 5,
                    ),
                    SizedBox(height: AppSize.h(context, 6)),
                    ShimmerBox(
                      width: AppSize.w(context, 100),
                      height: AppSize.h(context, 10),
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
              ShimmerBox(
                width: AppSize.w(context, 52),
                height: AppSize.h(context, 22),
                borderRadius: 20,
              ),
            ],
          ),
          SizedBox(height: AppSize.h(context, 12)),
          // analyst strip
          Container(
            padding: AppSize.insets(context, left: 12, right: 12, top: 12, bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSize.r(context, 16)),
              border: Border.all(
                color: ColorConstants.navy.withValues(alpha: 0.10),
              ),
            ),
            child: Row(
              children: <Widget>[
                ShimmerBox(
                  width: AppSize.r(context, 44),
                  height: AppSize.r(context, 44),
                  isCircle: true,
                ),
                SizedBox(width: AppSize.w(context, 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ShimmerBox(
                        width: AppSize.w(context, 120),
                        height: AppSize.h(context, 12),
                        borderRadius: 4,
                      ),
                      SizedBox(height: AppSize.h(context, 6)),
                      ShimmerBox(
                        width: AppSize.w(context, 90),
                        height: AppSize.h(context, 10),
                        borderRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSize.h(context, 14)),
          // price + subscribe row
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
                    SizedBox(height: AppSize.h(context, 4)),
                    ShimmerBox(
                      width: AppSize.w(context, 80),
                      height: AppSize.h(context, 18),
                      borderRadius: 5,
                    ),
                  ],
                ),
              ),
              ShimmerBox(
                width: AppSize.w(context, 96),
                height: AppSize.h(context, 36),
                borderRadius: 10,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A scrollable list of [ShimmerBatchCard]s wrapped in a [ShimmerScope].
class ShimmerBatchList extends StatelessWidget {
  const ShimmerBatchList({super.key, this.count = 3, this.padding});

  final int count;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ShimmerScope(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding ??
            AppSize.insets(context, left: 16, right: 16, top: 6, bottom: 88),
        itemCount: count,
        separatorBuilder: (_, __) => SizedBox(height: AppSize.h(context, 20)),
        itemBuilder: (_, __) => const ShimmerBatchCard(),
      ),
    );
  }
}
