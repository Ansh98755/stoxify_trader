import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/utils/main_tab_navigation.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../../core/widgets/bottom_navbar.dart';
import '../../../../core/widgets/common_trading_card.dart';
import '../widgets/trades_status_tabs.dart';

class TradesPage extends StatefulWidget {
  const TradesPage({super.key});

  @override
  State<TradesPage> createState() => _TradesPageState();
}

class _TradesPageState extends State<TradesPage> {
  TradesStatusTab _statusTab = TradesStatusTab.active;

  static const List<TradingCardData> _allTrades = <TradingCardData>[
    TradingCardData(
      symbol: 'Tata Motors',
      batchName: 'Equity Swing Pro',
      currentPrice: '₹985',
      change: '+₹23.40 (+1.18%)',
      tradeStatus: 'In profit',
      entry: '₹978',
      sl: '₹952',
      target: '₹1,045',
      estGain: '+18.00%',
      liveRet: '+3.86%',
      segment: 'Swing',
      asset: 'Equity',
      rationale:
          'Price holding above entry with stable volume. Review the stop-loss before deciding next steps.',
    ),
    TradingCardData(
      symbol: 'Reliance',
      batchName: 'Equity Swing Pro',
      currentPrice: '₹2,860',
      change: '+₹15.00 (+0.53%)',
      tradeStatus: 'In profit',
      entry: '₹2,845',
      sl: '₹2,790',
      target: '₹2,960',
      estGain: '+5.20%',
      liveRet: '+2.11%',
      segment: 'Swing',
      asset: 'Equity',
    ),
    TradingCardData(
      symbol: 'Nifty 24800 CE',
      batchName: 'FNO Mastery 1',
      currentPrice: '₹186',
      change: '+₹4.00 (+2.20%)',
      tradeStatus: 'At cost',
      entry: '₹182',
      sl: '₹168',
      target: '₹210',
      estGain: '+15.40%',
      liveRet: '+2.20%',
      segment: 'Intraday',
      asset: 'Options',
    ),
    TradingCardData(
      symbol: 'Infosys',
      batchName: 'Equity Swing Pro',
      currentPrice: '₹1,540',
      change: '+₹58.00 (+3.91%)',
      tradeStatus: 'Closed in profit',
      entry: '₹1,482',
      sl: '₹1,440',
      target: '₹1,560',
      estGain: '+5.26%',
      liveRet: '+3.91%',
      segment: 'Intraday',
      asset: 'Equity',
    ),
    TradingCardData(
      symbol: 'HDFC Bank',
      batchName: 'FNO Mastery 1',
      currentPrice: '₹1,612',
      change: '-₹28.00 (-1.71%)',
      tradeStatus: 'Closed in loss',
      entry: '₹1,640',
      sl: '₹1,605',
      target: '₹1,720',
      estGain: '-2.13%',
      liveRet: '-1.71%',
      segment: 'F&O',
      asset: 'Equity',
    ),
  ];

  bool _isClosedTrade(TradingCardData card) {
    final status = card.tradeStatus?.toLowerCase() ?? '';
    return status.contains('closed');
  }

  List<TradingCardData> get _visibleTrades {
    return _allTrades.where((TradingCardData card) {
      final isClosed = _isClosedTrade(card);
      return _statusTab == TradesStatusTab.closed ? isClosed : !isClosed;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final trades = _visibleTrades;
    final sectionLabel = _statusTab == TradesStatusTab.active
        ? 'Active trades'
        : 'Closed trades';

    return Scaffold(
      extendBody: true,
      backgroundColor: ColorConstants.transparent,
      body: Stack(
        children: <Widget>[
          const AppScreenBackground(
            variant: AppScreenBackgroundVariant.trades,
          ),
          SafeArea(
            child: Padding(
              padding: AppSize.insets(context, left: 16, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Text(
                  //   'Trades',
                  //   style: TextStyleConstants.screenTitle.copyWith(
                  //     fontSize: AppSize.sp(context, 22),
                  //   ),
                  // ),
                  // SizedBox(height: AppSize.h(context, 4)),
                  // Text(
                  //   'From analysts you subscribe to',
                  //   style: TextStyleConstants.caption.copyWith(
                  //     fontSize: AppSize.sp(context, 12.5),
                  //     color: ColorConstants.mute,
                  //   ),
                  // ),
                  SizedBox(height: AppSize.h(context, 18)),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          TradesStatusTabs(
                            active: _statusTab,
                            onChanged: (TradesStatusTab tab) {
                              setState(() => _statusTab = tab);
                            },
                          ),
                          SizedBox(height: AppSize.h(context, 12)),
                          Text(
                            sectionLabel,
                            style: TextStyleConstants.bodyMedium.copyWith(
                              fontSize: AppSize.sp(context, 13),
                              fontWeight: FontWeight.w600,
                              color: ColorConstants.mute,
                            ),
                          ),
                          SizedBox(height: AppSize.h(context, 8)),
                          if (trades.isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: AppSize.h(context, 40),
                              ),
                              child: Center(
                                child: Text(
                                  _statusTab == TradesStatusTab.active
                                      ? 'No active trades yet'
                                      : 'No closed trades yet',
                                  style: TextStyleConstants.bodyMedium.copyWith(
                                    color: ColorConstants.mute,
                                    fontSize: AppSize.sp(context, 13),
                                  ),
                                ),
                              ),
                            )
                          else
                            ...trades.map(
                              (TradingCardData card) => Padding(
                                padding: EdgeInsets.only(
                                  top: AppSize.h(context, 8),
                                  bottom: AppSize.h(context, 12),
                                ),
                                child: CommonTradingCard(
                                  data: card,
                                  onViewDetails: () => context
                                      .push(AppRoutingName.tradeDetails),
                                ),
                              ),
                            ),
                          SizedBox(height: AppSize.h(context, 88)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavbar(
              currentIndex: 2,
              onItemSelected: (int index) {
                if (index == 2) return;
                navigateMainTab(context, index);
              },
            ),
          ),
        ],
      ),
    );
  }
}
