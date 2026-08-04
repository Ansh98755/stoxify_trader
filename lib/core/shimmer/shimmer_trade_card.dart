import 'package:flutter/material.dart';

import '../constants/color_constants.dart';
import '../utils/app_size.dart';
import 'shimmer.dart';

/// Skeleton that mirrors the shape of CommonTradingCard.
/// Wrap a list of these in ShimmerScope so all animate together.
class ShimmerTradeCard extends StatelessWidget {
  const ShimmerTradeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final r = AppSize.r(context, 14);
    return Container(
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: ColorConstants.line),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: ColorConstants.navy.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: AppSize.insets(context, left: 12, right: 12, top: 12, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // direction pill
          ShimmerBox(
            width: AppSize.w(context, 52),
            height: AppSize.h(context, 20),
            borderRadius: 6,
          ),
          SizedBox(height: AppSize.h(context, 8)),
          // instrument row: avatar + symbol + price
          Row(
            children: <Widget>[
              ShimmerBox(
                width: AppSize.r(context, 42),
                height: AppSize.r(context, 42),
                isCircle: true,
              ),
              SizedBox(width: AppSize.w(context, 10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ShimmerBox(
                      width: AppSize.w(context, 120),
                      height: AppSize.h(context, 14),
                      borderRadius: 5,
                    ),
                    SizedBox(height: AppSize.h(context, 6)),
                    ShimmerBox(
                      width: AppSize.w(context, 80),
                      height: AppSize.h(context, 10),
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  ShimmerBox(
                    width: AppSize.w(context, 64),
                    height: AppSize.h(context, 14),
                    borderRadius: 5,
                  ),
                  SizedBox(height: AppSize.h(context, 6)),
                  ShimmerBox(
                    width: AppSize.w(context, 80),
                    height: AppSize.h(context, 10),
                    borderRadius: 4,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: AppSize.h(context, 12)),
          // timeline bar
          ShimmerBox(
            width: double.infinity,
            height: AppSize.h(context, 28),
            borderRadius: 6,
          ),
          SizedBox(height: AppSize.h(context, 10)),
          // stats row: est gain + live return
          Row(
            children: <Widget>[
              Expanded(
                child: ShimmerBox(
                  width: double.infinity,
                  height: AppSize.h(context, 36),
                  borderRadius: 8,
                ),
              ),
              SizedBox(width: AppSize.w(context, 8)),
              Expanded(
                child: ShimmerBox(
                  width: double.infinity,
                  height: AppSize.h(context, 36),
                  borderRadius: 8,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSize.h(context, 8)),
          // levels row: entry / SL / target
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List<Widget>.generate(3, (_) => ShimmerBox(
              width: AppSize.w(context, 70),
              height: AppSize.h(context, 10),
              borderRadius: 4,
            )),
          ),
        ],
      ),
    );
  }
}

/// A scrollable list of [ShimmerTradeCard]s wrapped in a [ShimmerScope].
class ShimmerTradeList extends StatelessWidget {
  const ShimmerTradeList({super.key, this.count = 3, this.padding});

  final int count;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ??
        AppSize.insets(context, left: 16, right: 16, top: 8, bottom: 16);
    return ShimmerScope(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: effectivePadding,
        child: Column(
          children: <Widget>[
            for (int i = 0; i < count; i++) ...<Widget>[
              const ShimmerTradeCard(),
              if (i < count - 1) SizedBox(height: AppSize.h(context, 20)),
            ],
          ],
        ),
      ),
    );
  }
}
