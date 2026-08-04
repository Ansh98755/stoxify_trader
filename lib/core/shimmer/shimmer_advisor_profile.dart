import 'package:flutter/material.dart';

import '../constants/color_constants.dart';
import '../utils/app_size.dart';
import 'shimmer.dart';

/// Full-page skeleton for AdvisorProfilePage loading state.
class ShimmerAdvisorProfile extends StatelessWidget {
  const ShimmerAdvisorProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerScope(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: AppSize.insets(context, left: 16, right: 16, top: 4, bottom: 24),
        child: Column(
          children: <Widget>[
            _header(context),
            SizedBox(height: AppSize.h(context, 10)),
            _statsRow(context),
            SizedBox(height: AppSize.h(context, 16)),
            _tabs(context),
            SizedBox(height: AppSize.h(context, 16)),
            _batchCardSkeleton(context),
            SizedBox(height: AppSize.h(context, 18)),
            _batchCardSkeleton(context),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: <Widget>[
        Align(
          alignment: Alignment.topLeft,
          child: ShimmerBox(
            width: AppSize.r(context, 40),
            height: AppSize.r(context, 40),
            borderRadius: 12,
          ),
        ),
        Column(
          children: <Widget>[
            ShimmerBox(
              width: AppSize.r(context, 64),
              height: AppSize.r(context, 64),
              isCircle: true,
            ),
            SizedBox(height: AppSize.h(context, 10)),
            ShimmerBox(width: AppSize.w(context, 140), height: AppSize.h(context, 16), borderRadius: 6),
            SizedBox(height: AppSize.h(context, 8)),
            ShimmerBox(width: AppSize.w(context, 100), height: AppSize.h(context, 11), borderRadius: 4),
          ],
        ),
      ],
    );
  }

  Widget _statsRow(BuildContext context) {
    return Container(
      padding: AppSize.insets(context, left: 14, right: 14, top: 12, bottom: 12),
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(AppSize.r(context, 16)),
        border: Border.all(color: ColorConstants.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List<Widget>.generate(4, (_) => Column(
          children: <Widget>[
            ShimmerBox(width: AppSize.w(context, 44), height: AppSize.h(context, 16), borderRadius: 4),
            SizedBox(height: AppSize.h(context, 4)),
            ShimmerBox(width: AppSize.w(context, 52), height: AppSize.h(context, 10), borderRadius: 3),
          ],
        )),
      ),
    );
  }

  Widget _tabs(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: ShimmerBox(width: double.infinity, height: AppSize.h(context, 36), borderRadius: 12)),
        SizedBox(width: AppSize.w(context, 8)),
        Expanded(child: ShimmerBox(width: double.infinity, height: AppSize.h(context, 36), borderRadius: 12)),
      ],
    );
  }

  Widget _batchCardSkeleton(BuildContext context) {
    return Container(
      padding: AppSize.insets(context, left: 14, right: 14, top: 14, bottom: 14),
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(AppSize.r(context, 16)),
        border: Border.all(color: ColorConstants.navy.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(children: <Widget>[
            Expanded(child: ShimmerBox(width: double.infinity, height: AppSize.h(context, 14), borderRadius: 5)),
            SizedBox(width: AppSize.w(context, 12)),
            ShimmerBox(width: AppSize.w(context, 52), height: AppSize.h(context, 22), borderRadius: 20),
          ]),
          SizedBox(height: AppSize.h(context, 10)),
          const Divider(height: 1, color: ColorConstants.line),
          SizedBox(height: AppSize.h(context, 10)),
          Row(children: <Widget>[
            Expanded(child: ShimmerBox(width: double.infinity, height: AppSize.h(context, 16), borderRadius: 4)),
            SizedBox(width: AppSize.w(context, 40)),
            ShimmerBox(width: AppSize.w(context, 88), height: AppSize.h(context, 32), borderRadius: 10),
          ]),
        ],
      ),
    );
  }
}
