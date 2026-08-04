import 'package:flutter/material.dart';

import '../constants/color_constants.dart';
import '../utils/app_size.dart';
import 'shimmer.dart';

/// Skeleton that mirrors the shape of a notification list item.
class ShimmerNotificationRow extends StatelessWidget {
  const ShimmerNotificationRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSize.insets(context, left: 14, right: 14, top: 14, bottom: 14),
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(AppSize.r(context, 14)),
        border: Border.all(color: ColorConstants.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // icon bubble
          ShimmerBox(
            width: AppSize.r(context, 40),
            height: AppSize.r(context, 40),
            borderRadius: 12,
          ),
          SizedBox(width: AppSize.w(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ShimmerBox(
                  width: AppSize.w(context, 160),
                  height: AppSize.h(context, 13),
                  borderRadius: 5,
                ),
                SizedBox(height: AppSize.h(context, 7)),
                ShimmerBox(
                  width: double.infinity,
                  height: AppSize.h(context, 11),
                  borderRadius: 4,
                ),
                SizedBox(height: AppSize.h(context, 4)),
                ShimmerBox(
                  width: AppSize.w(context, 120),
                  height: AppSize.h(context, 11),
                  borderRadius: 4,
                ),
                SizedBox(height: AppSize.h(context, 8)),
                ShimmerBox(
                  width: AppSize.w(context, 60),
                  height: AppSize.h(context, 10),
                  borderRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Scrollable list of [ShimmerNotificationRow]s wrapped in [ShimmerScope].
class ShimmerNotificationList extends StatelessWidget {
  const ShimmerNotificationList({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ShimmerScope(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: AppSize.h(context, 24)),
        itemCount: count,
        separatorBuilder: (_, __) => SizedBox(height: AppSize.h(context, 10)),
        itemBuilder: (_, __) => const ShimmerNotificationRow(),
      ),
    );
  }
}
