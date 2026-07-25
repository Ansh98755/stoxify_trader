import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../../core/widgets/common_batch_card.dart';
import '../../../../core/widgets/common_trading_card.dart';
import '../../../../core/widgets/risk_badge.dart';
import '../../../../core/widgets/sebi_verified_pill.dart';

class AdvisorProfilePage extends StatefulWidget {
  const AdvisorProfilePage({super.key});

  @override
  State<AdvisorProfilePage> createState() => _AdvisorProfilePageState();
}

class _AdvisorProfilePageState extends State<AdvisorProfilePage> {
  int _tab = 0;

  static const List<CommonBatchData> _batches = <CommonBatchData>[
    CommonBatchData(
      name: 'FNO Batch',
      risk: RiskLevel.medium,
      analyst: 'Akash Garg',
      analystInit: 'AG',
      sebi: 'INH53999999999',
      description:
          'Index and stock F&O calls with NSE timestamps and full modification history.',
      tags: <String>['F&O', 'Equity', 'Intraday'],
      price: '₹99',
      subscriberCount: '34',
    ),
    CommonBatchData(
      name: 'Equity Swing',
      risk: RiskLevel.low,
      analyst: 'Akash Garg',
      analystInit: 'AG',
      sebi: 'INH53999999999',
      description: 'Mid-cap equity swing ideas with rationale on every publish.',
      tags: <String>['Equity', 'Swing'],
      price: '₹999',
      subscriberCount: '142',
    ),
  ];

  static const List<TradingCardData> _trades = <TradingCardData>[
    TradingCardData(
      symbol: 'NIFTY 100',
      batchName: 'FNO Batch',
      currentPrice: '₹25,286',
      change: '−0.02%',
      tradeStatus: 'At cost',
      entry: '₹25,291',
      sl: '₹25,270',
      target: '₹25,300',
      estGain: '+0.04%',
      liveRet: '−0.02%',
      segment: 'Intraday',
      asset: 'Equity',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.transparent,
      body: Stack(
        children: <Widget>[
          const AppScreenBackground(),
          SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: AppSize.insets(context, left: 16, right: 16, top: 4),
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          color: ColorConstants.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSize.r(context, 12)),
                            side: const BorderSide(color: ColorConstants.line),
                          ),
                          child: InkWell(
                            onTap: () => context.pop(),
                            borderRadius:
                                BorderRadius.circular(AppSize.r(context, 12)),
                            child: SizedBox(
                              width: AppSize.r(context, 40),
                              height: AppSize.r(context, 40),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                size: AppSize.r(context, 20),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        children: <Widget>[
                          Container(
                            width: AppSize.r(context, 64),
                            height: AppSize.r(context, 64),
                            padding: EdgeInsets.all(AppSize.r(context, 2.5)),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ColorConstants.brandBlueLight,
                                width: 2,
                              ),
                            ),
                            child: DecoratedBox(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: <Color>[
                                    ColorConstants.brandBlueLight,
                                    ColorConstants.brandBlue,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'AG',
                                  style: TextStyleConstants.cardTitle.copyWith(
                                    color: ColorConstants.white,
                                    fontSize: AppSize.sp(context, 18),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: AppSize.h(context, 8)),
                          Text(
                            'Akash Garg',
                            textAlign: TextAlign.center,
                            style: TextStyleConstants.cardTitle.copyWith(
                              fontSize: AppSize.sp(context, 20),
                            ),
                          ),
                          SizedBox(height: AppSize.h(context, 3)),
                          Text(
                            'INH53999999999',
                            textAlign: TextAlign.center,
                            style: TextStyleConstants.caption.copyWith(
                              fontSize: AppSize.sp(context, 12),
                              fontWeight: FontWeight.w600,
                              color: ColorConstants.brandBlue,
                            ),
                          ),
                          SizedBox(height: AppSize.h(context, 6)),
                          const SebiVerifiedPill(),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSize.h(context, 10)),
                Padding(
                  padding: AppSize.symmetric(context, horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: AppSize.insets(
                      context,
                      left: 14,
                      right: 14,
                      top: 12,
                      bottom: 12,
                    ),
                    decoration: BoxDecoration(
                      color: ColorConstants.white,
                      borderRadius:
                          BorderRadius.circular(AppSize.r(context, 16)),
                      border: Border.all(color: ColorConstants.line),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: ColorConstants.navy.withValues(alpha: 0.04),
                          blurRadius: AppSize.r(context, 12),
                          offset: Offset(0, AppSize.h(context, 3)),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Row(
                          children: <Widget>[
                            _Stat('41%', 'Win rate', ColorConstants.green),
                            _Stat('+2.93%', 'Avg P&L', ColorConstants.green),
                            _Stat('27', 'Trades', ColorConstants.ink),
                            _Stat('34', 'Subscribers', ColorConstants.ink),
                          ],
                        ),
                        // const TaperedHorizontalDivider(verticalPadding: 10),
                        // Text(
                        //   'About',
                        //   style: TextStyleConstants.cardTitleSmall.copyWith(
                        //     fontSize: AppSize.sp(context, 14),
                        //   ),
                        // ),
                        // SizedBox(height: AppSize.h(context, 5)),
                        // Text(
                        //   'Index and stock F&O research with NSE timestamps on every publish. Full modification history and rationale on each call.',
                        //   style: TextStyleConstants.bodyMedium.copyWith(
                        //     fontSize: AppSize.sp(context, 12.5),
                        //     color: ColorConstants.mute,
                        //     height: 1.4,
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: AppSize.h(context, 16)),
                Padding(
                  padding: AppSize.symmetric(context, horizontal: 16),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _ProfileTab(
                          label: 'Batches & Plans',
                          selected: _tab == 0,
                          onTap: () => setState(() => _tab = 0),
                        ),
                      ),
                      SizedBox(width: AppSize.w(context, 8)),
                      Expanded(
                        child: _ProfileTab(
                          label: 'Recent Trades',
                          selected: _tab == 1,
                          onTap: () => setState(() => _tab = 1),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSize.h(context, 12)),
                Expanded(
                  child: ListView(
                    padding: AppSize.insets(
                      context,
                      left: 16,
                      right: 16,
                      top: 6,
                      bottom: 110,
                    ),
                    children: _tab == 0
                        ? _batches
                            .map(
                              (CommonBatchData b) => Padding(
                                padding: EdgeInsets.only(
                                  bottom: AppSize.h(context, 18),
                                ),
                                child: CommonBatchCard(
                                  data: b,
                                  showAnalystProfile: false,
                                  onSubscribe: () => context.push(
                                    AppRoutingName.subscriptions,
                                  ),
                                ),
                              ),
                            )
                            .toList()
                        : _trades
                            .map(
                              (TradingCardData t) => Padding(
                                padding: EdgeInsets.only(
                                  bottom: AppSize.h(context, 12),
                                ),
                                child: CommonTradingCard(
                                  data: t,
                                  onViewDetails: () => context.push(
                                    AppRoutingName.tradeDetails,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
          ),
          // Positioned(
          //   left: 0,
          //   right: 0,
          //   bottom: 0,
          //   child: Container(
          //     padding: AppSize.insets(
          //       context,
          //       left: 16,
          //       right: 16,
          //       top: 12,
          //       bottom: 16,
          //     ),
          //     decoration: BoxDecoration(
          //       color: ColorConstants.white,
          //       border: Border(
          //         top: BorderSide(
          //           color: ColorConstants.line.withValues(alpha: 0.9),
          //         ),
          //       ),
          //       boxShadow: <BoxShadow>[
          //         BoxShadow(
          //           color: ColorConstants.navy.withValues(alpha: 0.08),
          //           blurRadius: 16,
          //           offset: const Offset(0, -4),
          //         ),
          //       ],
          //     ),
          //     child: SafeArea(
          //       top: false,
          //       child: Row(
          //         children: <Widget>[
          //           Expanded(
          //             child: Column(
          //               crossAxisAlignment: CrossAxisAlignment.start,
          //               mainAxisSize: MainAxisSize.min,
          //               children: <Widget>[
          //                 Text(
          //                   'From',
          //                   style: TextStyleConstants.caption.copyWith(
          //                     fontSize: AppSize.sp(context, 11),
          //                     color: ColorConstants.mute,
          //                   ),
          //                 ),
          //                 Text(
          //                   '₹99/month',
          //                   style: TextStyleConstants.cardTitleSmall.copyWith(
          //                     fontSize: AppSize.sp(context, 17),
          //                   ),
          //                 ),
          //               ],
          //             ),
          //           ),
          //           CommonButtonWidget(
          //             label: 'Subscribe',
          //             width: null,
          //             height: 44,
          //             borderRadius: 10,
          //             horizontalPadding: 22,
          //             onPressed: () =>
          //                 context.push(AppRoutingName.subscriptions),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, this.color);

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: TextStyleConstants.numeric.copyWith(
              fontSize: AppSize.sp(context, 14),
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(height: AppSize.h(context, 2)),
          Text(
            label,
            style: TextStyleConstants.caption.copyWith(
              fontSize: AppSize.sp(context, 10),
              color: ColorConstants.mute,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ColorConstants.white : ColorConstants.gray50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
        side: BorderSide(
          color: selected
              ? ColorConstants.navy.withValues(alpha: 0.35)
              : ColorConstants.line,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
        child: Padding(
          padding: AppSize.symmetric(context, vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyleConstants.bodyMedium.copyWith(
              fontSize: AppSize.sp(context, 12),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? ColorConstants.ink : ColorConstants.mute,
            ),
          ),
        ),
      ),
    );
  }
}
