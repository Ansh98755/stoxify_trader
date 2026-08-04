import 'package:flutter/material.dart';

import '../constants/color_constants.dart';
import '../constants/text_style_constants.dart';
import '../utils/app_size.dart';
import 'common_button_widget.dart';
import 'risk_badge.dart';
import 'sebi_verified_pill.dart';
import 'segment_tag_chip.dart';
import 'tapered_divider.dart';

/// Shared batch / plan card used by Discover browse and Advisor profile.
class CommonBatchData {
  const CommonBatchData({
    required this.name,
    required this.risk,
    required this.analyst,
    required this.analystInit,
    required this.sebi,
    required this.description,
    required this.tags,
    required this.price,
    required this.subscriberCount,
    this.priceSuffix = '',
    this.avatarStart = ColorConstants.brandBlueLight,
    this.avatarEnd = ColorConstants.brandBlue,
  });

  final String name;
  final RiskLevel risk;
  final String analyst;
  final String analystInit;
  final String sebi;
  final String description;
  final List<String> tags;
  final String price;
  final String? subscriberCount;
  final String priceSuffix;
  final Color avatarStart;
  final Color avatarEnd;
}

class CommonBatchCard extends StatelessWidget {
  const CommonBatchCard({
    required this.data,
    super.key,
    this.onTap,
    this.onSubscribe,
    this.onAnalystTap,
    this.showAnalystProfile = true,
    this.isSubscribed = false,
  });

  final CommonBatchData data;
  final VoidCallback? onTap;
  final VoidCallback? onSubscribe;
  final VoidCallback? onAnalystTap;

  /// When false (e.g. advisor profile), hides the analyst strip and uses a divider.
  final bool showAnalystProfile;
  final bool isSubscribed;

  @override
  Widget build(BuildContext context) {
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
                    right: 14,
                    top: hasTags ? 12 : 14,
                    bottom: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  data.name,
                                  style: TextStyleConstants.cardTitle.copyWith(
                                    fontSize: AppSize.sp(context, 16.5),
                                    height: 1.2,
                                    color: ColorConstants.ink,
                                  ),
                                ),
                                if (data.subscriberCount != null) ...<Widget>[
                                  SizedBox(height: AppSize.h(context, 4)),
                                  Text(
                                    '${data.subscriberCount} subscribers',
                                    style:
                                        TextStyleConstants.caption.copyWith(
                                      fontSize: AppSize.sp(context, 11.5),
                                      fontWeight: FontWeight.w600,
                                      color: ColorConstants.mute,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          RiskBadge(level: data.risk),
                        ],
                      ),
                      if (showAnalystProfile) ...<Widget>[
                        SizedBox(height: AppSize.h(context, 8)),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onAnalystTap,
                          child: Container(
                            padding: AppSize.insets(
                            context,
                            left: 12,
                            right: 12,
                            top: 12,
                            bottom: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(AppSize.r(context, 16)),
                              border: Border.all(
                                color: ColorConstants.navy
                                    .withValues(alpha: 0.15),
                              ),
                              color: ColorConstants.white,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                              Container(
                                width: AppSize.r(context, 44),
                                height: AppSize.r(context, 44),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: <Color>[
                                      data.avatarStart,
                                      data.avatarEnd,
                                    ],
                                  ),
                                ),
                                child: Text(
                                  data.analystInit,
                                  style: TextStyleConstants.caption.copyWith(
                                    color: ColorConstants.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: AppSize.sp(context, 14),
                                  ),
                                ),
                              ),
                              SizedBox(width: AppSize.w(context, 12)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      data.analyst,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyleConstants.bodyMedium
                                          .copyWith(
                                        fontSize: AppSize.sp(context, 14),
                                        fontWeight: FontWeight.w700,
                                        color: ColorConstants.ink,
                                      ),
                                    ),
                                    SizedBox(height: AppSize.h(context, 4)),
                                    Text(
                                      data.sebi,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          TextStyleConstants.caption.copyWith(
                                        fontSize: AppSize.sp(context, 11),
                                        fontWeight: FontWeight.w600,
                                        color: ColorConstants.brandBlue,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: AppSize.w(context, 10)),
                              const SebiVerifiedPill(compact: true),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: AppSize.h(context, 6)),
                      ] else ...<Widget>[
                        // const TaperedHorizontalDivider(verticalPadding: 10),
                        SizedBox(height: 14,)
                      ],
                      // Text(
                      //   "About Batch",
                      //   style: TextStyleConstants.bodyMedium.copyWith(color: ColorConstants.navyDark),
                      // ),
                      // SizedBox(height: AppSize.h(context,8),),
                      // TaperedHorizontalDivider(),
                      // SizedBox(height: AppSize.h(context,8),),
                      // Text(data.description),
                      Container(
                        padding: AppSize.insets(
                          context,
                          left: 12,
                          right: 12,
                          top: 12,
                          bottom: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius:
                          BorderRadius.circular(AppSize.r(context, 16)),
                          border: Border.all(
                            color: ColorConstants.navy
                                .withValues(alpha: 0.15),
                          ),
                          color: ColorConstants.white,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            // Container(
                            //   width: AppSize.r(context, 44),
                            //   height: AppSize.r(context, 44),
                            //   alignment: Alignment.center,
                            //   decoration: BoxDecoration(
                            //     shape: BoxShape.circle,
                            //     gradient: LinearGradient(
                            //       begin: Alignment.topLeft,
                            //       end: Alignment.bottomRight,
                            //       colors: <Color>[
                            //         data.avatarStart,
                            //         data.avatarEnd,
                            //       ],
                            //     ),
                            //   ),
                            //   child: Text(
                            //     'About Batch',
                            //     style: TextStyleConstants.caption.copyWith(
                            //       color: ColorConstants.white,
                            //       fontWeight: FontWeight.w700,
                            //       fontSize: AppSize.sp(context, 14),
                            //     ),
                            //   ),
                            // ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    'About Batch',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyleConstants.bodyMedium
                                        .copyWith(
                                      fontSize: AppSize.sp(context, 14),
                                      fontWeight: FontWeight.w700,
                                      color: ColorConstants.mute,
                                    ),
                                  ),
                                  SizedBox(height: AppSize.h(context, 4)),
                                  Text(
                                    data.description,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                    TextStyleConstants.caption.copyWith(
                                      fontSize: AppSize.sp(context, 11),
                                      fontWeight: FontWeight.w600,
                                      color: ColorConstants.soft,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // SizedBox(width: AppSize.w(context, 10)),
                            // const SebiVerifiedPill(compact: true),
                          ],
                        ),
                      ),
                      SizedBox(height: 12,),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'From',
                                  style: TextStyleConstants.caption.copyWith(
                                    fontSize: AppSize.sp(context, 11),
                                    fontWeight: FontWeight.w600,
                                    color: ColorConstants.mute,
                                  ),
                                ),
                                SizedBox(height: AppSize.h(context, 2)),
                                RichText(
                                  text: TextSpan(
                                    children: <InlineSpan>[
                                      TextSpan(
                                        text: data.price,
                                        style: TextStyleConstants.cardTitle
                                            .copyWith(
                                          fontSize: AppSize.sp(context, 18),
                                          color: ColorConstants.ink,
                                        ),
                                      ),
                                      TextSpan(
                                        text: data.priceSuffix,
                                        style: TextStyleConstants.bodyMedium
                                            .copyWith(
                                          fontSize: AppSize.sp(context, 12),
                                          color: ColorConstants.mute,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CommonButtonWidget(
                            label: isSubscribed ? 'Subscribed' : 'Subscribe',
                            onPressed: isSubscribed ? null : (onSubscribe ?? () {}),
                            width: null,
                            height: 40,
                            borderRadius: 10,
                            horizontalPadding: 16,
                            backgroundColor: isSubscribed
                                ? ColorConstants.pillSuccessBg
                                : ColorConstants.brandBlue,
                            foregroundColor: isSubscribed
                                ? ColorConstants.green
                                : ColorConstants.white,
                            disabledBackgroundColor: ColorConstants.pillSuccessBg,
                            disabledForegroundColor: ColorConstants.green,
                            borderColor: isSubscribed
                                ? ColorConstants.green.withValues(alpha: 0.35)
                                : null,
                          ),
                        ],
                      ),
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
