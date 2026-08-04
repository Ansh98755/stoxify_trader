import 'package:flutter/material.dart';

import '../constants/color_constants.dart';
import '../utils/app_size.dart';
import 'shimmer.dart';

/// Full-page skeleton for BatchDetailsPage loading state.
class ShimmerBatchDetails extends StatelessWidget {
  const ShimmerBatchDetails({super.key});

  @override
  Widget build(BuildContext context) {
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
          _tradeCardSkeleton(context),
          SizedBox(height: AppSize.h(context, 14)),
          _tradeCardSkeleton(context),
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
      padding: AppSize.insets(context, left: 18, right: 18, top: 20, bottom: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A5CC8),
        borderRadius: BorderRadius.circular(AppSize.r(context, 22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ShimmerBox(width: AppSize.w(context, 180), height: AppSize.h(context, 22), borderRadius: 6),
          SizedBox(height: AppSize.h(context, 18)),
          Container(
            padding: AppSize.insets(context, left: 12, right: 12, top: 12, bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(AppSize.r(context, 16)),
            ),
            child: Row(children: <Widget>[
              ShimmerBox(width: AppSize.r(context, 48), height: AppSize.r(context, 48), borderRadius: 14),
              SizedBox(width: AppSize.w(context, 12)),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                ShimmerBox(width: AppSize.w(context, 80), height: AppSize.h(context, 10), borderRadius: 4),
                SizedBox(height: AppSize.h(context, 6)),
                ShimmerBox(width: AppSize.w(context, 130), height: AppSize.h(context, 13), borderRadius: 4),
              ])),
            ]),
          ),
          SizedBox(height: AppSize.h(context, 14)),
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

  Widget _tradeCardSkeleton(BuildContext context) {
    return Container(
      padding: AppSize.insets(context, left: 12, right: 12, top: 12, bottom: 12),
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(AppSize.r(context, 14)),
        border: Border.all(color: ColorConstants.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Row(children: <Widget>[
          ShimmerBox(width: AppSize.r(context, 36), height: AppSize.r(context, 36), isCircle: true),
          SizedBox(width: AppSize.w(context, 10)),
          Expanded(child: ShimmerBox(width: double.infinity, height: AppSize.h(context, 13), borderRadius: 5)),
          SizedBox(width: AppSize.w(context, 16)),
          ShimmerBox(width: AppSize.w(context, 60), height: AppSize.h(context, 13), borderRadius: 5),
        ]),
        SizedBox(height: AppSize.h(context, 10)),
        ShimmerBox(width: double.infinity, height: AppSize.h(context, 26), borderRadius: 6),
        SizedBox(height: AppSize.h(context, 8)),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List<Widget>.generate(
          3, (_) => ShimmerBox(width: AppSize.w(context, 70), height: AppSize.h(context, 10), borderRadius: 4),
        )),
      ]),
    );
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
