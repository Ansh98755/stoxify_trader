import 'package:flutter/material.dart';

import '../constants/color_constants.dart';
import '../utils/app_size.dart';
import '../utils/responsive_layout.dart';
import 'shimmer.dart';
import 'shimmer_trade_card.dart';

/// Full-page skeleton for BatchDetailsPage loading state.
class ShimmerBatchDetails extends StatelessWidget {
  const ShimmerBatchDetails({super.key});

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveLayout.cardGridColumns(context);
    return ShimmerScope(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: AppSize.insets(context, left: 16, right: 16, top: 16, bottom: 30),
        children: <Widget>[
          _headerCard(context),
          SizedBox(height: AppSize.h(context, 24)),
          _sectionCard(context),
          SizedBox(height: AppSize.h(context, 22)),
          _sectionHeading(context),
          SizedBox(height: AppSize.h(context, 12)),
          if (columns > 1)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: columns >= 3 ? 235 : 300,
              ),
              itemCount: columns * 2,
              itemBuilder: (_, __) => const Align(
                alignment: Alignment.topCenter,
                child: ShimmerTradeCard(),
              ),
            )
          else ...<Widget>[
            const ShimmerTradeCard(),
            SizedBox(height: AppSize.h(context, 14)),
            const ShimmerTradeCard(),
          ],
          SizedBox(height: AppSize.h(context, 22)),
          _sectionHeading(context),
          SizedBox(height: AppSize.h(context, 12)),
          _tierSkeleton(context),
          SizedBox(height: AppSize.h(context, 12)),
          _tierSkeleton(context),
        ],
      ),
    );
  }

  Widget _headerCard(BuildContext context) {
    return Container(
      padding: AppSize.insets(context, left: 12, right: 12, top: 12, bottom: 10),
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(AppSize.r(context, 14)),
        border: Border.all(color: ColorConstants.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ShimmerBox(width: AppSize.w(context, 180), height: AppSize.h(context, 16), borderRadius: 6),
          SizedBox(height: AppSize.h(context, 10)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSize.w(context, 8),
              vertical: AppSize.h(context, 6),
            ),
            decoration: BoxDecoration(
              color: ColorConstants.pageBackground,
              borderRadius: BorderRadius.circular(AppSize.r(context, 10)),
            ),
            child: Row(children: <Widget>[
              ShimmerBox(width: AppSize.r(context, 32), height: AppSize.r(context, 32), borderRadius: 10),
              SizedBox(width: AppSize.w(context, 8)),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                ShimmerBox(width: AppSize.w(context, 70), height: AppSize.h(context, 9), borderRadius: 4),
                SizedBox(height: AppSize.h(context, 4)),
                ShimmerBox(width: AppSize.w(context, 110), height: AppSize.h(context, 12), borderRadius: 4),
              ])),
            ]),
          ),
          SizedBox(height: AppSize.h(context, 10)),
          Row(children: <Widget>[
            ShimmerBox(width: AppSize.w(context, 52), height: AppSize.h(context, 22), borderRadius: 20),
            SizedBox(width: AppSize.w(context, 8)),
            ShimmerBox(width: AppSize.w(context, 60), height: AppSize.h(context, 22), borderRadius: 20),
          ]),
        ],
      ),
    );
  }

  Widget _sectionCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSize.r(context, 18)),
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(AppSize.r(context, 18)),
        border: Border.all(color: ColorConstants.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        _sectionHeading(context),
        SizedBox(height: AppSize.h(context, 12)),
        ShimmerBox(width: double.infinity, height: AppSize.h(context, 11), borderRadius: 4),
        SizedBox(height: AppSize.h(context, 5)),
        ShimmerBox(width: AppSize.w(context, 200), height: AppSize.h(context, 11), borderRadius: 4),
      ]),
    );
  }

  Widget _sectionHeading(BuildContext context) {
    return Row(children: <Widget>[
      ShimmerBox(width: AppSize.r(context, 34), height: AppSize.r(context, 34), borderRadius: 10),
      SizedBox(width: AppSize.w(context, 10)),
      ShimmerBox(width: AppSize.w(context, 130), height: AppSize.h(context, 16), borderRadius: 5),
    ]);
  }

  Widget _tierSkeleton(BuildContext context) {
    return Container(
      padding: AppSize.insets(context, left: 14, right: 14, top: 14, bottom: 14),
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(AppSize.r(context, 18)),
        border: Border.all(color: ColorConstants.line),
      ),
      child: Row(children: <Widget>[
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          ShimmerBox(width: AppSize.w(context, 100), height: AppSize.h(context, 14), borderRadius: 5),
          SizedBox(height: AppSize.h(context, 5)),
          ShimmerBox(width: AppSize.w(context, 60), height: AppSize.h(context, 10), borderRadius: 4),
          SizedBox(height: AppSize.h(context, 10)),
          ShimmerBox(width: AppSize.w(context, 80), height: AppSize.h(context, 22), borderRadius: 5),
        ])),
        ShimmerBox(width: AppSize.w(context, 96), height: AppSize.h(context, 36), borderRadius: 10),
      ]),
    );
  }
}
