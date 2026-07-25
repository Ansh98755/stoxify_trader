import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../../core/widgets/common_button_widget.dart';
import '../../../../core/widgets/sebi_verified_pill.dart';
import '../../../../core/widgets/tapered_divider.dart';
import '../../../../core/widgets/trade_signal_timeline.dart';

class TradeDetailsPage extends StatelessWidget {
  const TradeDetailsPage({super.key});

  static const _SignalDetails _data = _SignalDetails(
    symbol: 'Tata Motors',
    company: 'Tata Motors Ltd.',
    exchange: 'NSE',
    initials: 'TM',
    currentPrice: '₹985.20',
    change: '+₹23.40 (+1.18%)',
    isProfit: true,
    batchName: 'Equity Swing Pro',
    category: 'Swing',
    estimatedRisk: '-6.02%',
    liveReturn: '+3.97%',
    signalType: 'Analyst research',
    entry: '₹978',
    sl: '₹952',
    target: '₹1,045',
    direction: 'LONG',
    segment: 'Equity',
    entryDateTime: '23 Jul 2026, 1:56 PM',
    status: 'In profit',
    statusIsNeutral: false,
    entryZone: '₹962.80 - ₹994.40',
    exitZone: '₹1,020.00 - ₹1,070.00',
    nseTimestamp: '2026-07-23T13:56:11+05:30',
    rationale:
        'Price holding above entry with stable volume. Review the stop-loss before deciding next steps.',
    advisorName: 'Arjun Mehta',
    advisorInitials: 'AM',
    advisorSegmentTag: 'SWING',
    sebiReg: 'INH53999999999',
    actions: <_TradeAction>[
      _TradeAction(
        title: 'Target update',
        price: '₹1,045.00',
        updatedAt: 'Jul 23, 2026 2:10 PM',
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final d = _data;
    final Color changeColor =
        d.isProfit ? ColorConstants.green : ColorConstants.red;
    final Color statusColor = d.statusIsNeutral
        ? ColorConstants.amber
        : (d.isProfit ? ColorConstants.green : ColorConstants.red);
    final Color directionColor = d.direction.toUpperCase().contains('SHORT')
        ? ColorConstants.red
        : ColorConstants.green;

    return Scaffold(
      backgroundColor: ColorConstants.pageBackground,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const AppScreenBackground(),
          SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: AppSize.insets(context, left: 16, right: 16, top: 8),
                  child: AppBackHeader(
                    title: 'Live trade details',
                    onBack: () => context.pop(),
                    trailing: Material(
                      color: ColorConstants.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSize.r(context, 12)),
                        side: const BorderSide(color: ColorConstants.line),
                      ),
                      child: InkWell(
                        onTap: () {},
                        borderRadius:
                            BorderRadius.circular(AppSize.r(context, 12)),
                        child: SizedBox(
                          width: AppSize.r(context, 40),
                          height: AppSize.r(context, 40),
                          child: Icon(
                            Icons.ios_share_rounded,
                            size: AppSize.r(context, 20),
                            color: ColorConstants.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppSize.insets(
                      context,
                      left: 16,
                      right: 16,
                      top: 12,
                      bottom: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _SurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  _SymbolAvatar(initials: d.initials),
                                  SizedBox(width: AppSize.w(context, 12)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Wrap(
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          spacing: AppSize.w(context, 8),
                                          runSpacing: AppSize.h(context, 4),
                                          children: <Widget>[
                                            Text(
                                              d.symbol,
                                              style: TextStyleConstants
                                                  .cardTitle
                                                  .copyWith(
                                                fontSize:
                                                    AppSize.sp(context, 16),
                                              ),
                                            ),
                                            _ExchangePill(label: d.exchange),
                                          ],
                                        ),
                                        SizedBox(height: AppSize.h(context, 2)),
                                        Text(
                                          d.company,
                                          style: TextStyleConstants.caption
                                              .copyWith(
                                            fontSize: AppSize.sp(context, 12),
                                            color: ColorConstants.mute,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: <Widget>[
                                      Text(
                                        d.currentPrice,
                                        style: TextStyleConstants.numeric
                                            .copyWith(
                                          fontSize: AppSize.sp(context, 16),
                                          fontWeight: FontWeight.w700,
                                          color: ColorConstants.ink,
                                        ),
                                      ),
                                      SizedBox(height: AppSize.h(context, 2)),
                                      Text(
                                        d.change,
                                        style: TextStyleConstants.caption
                                            .copyWith(
                                          fontSize: AppSize.sp(context, 11),
                                          fontWeight: FontWeight.w600,
                                          color: changeColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: AppSize.h(context, 16)),
                              const TradeSignalTimeline(
                                timestamp: '23 Jul 13:56 PM',
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: AppSize.h(context, 12)),
                        _SurfaceCard(
                          child: Column(
                            children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(
                                    child: _LabeledValue(
                                      label: 'Direction',
                                      value: d.direction,
                                      valueColor: directionColor,
                                    ),
                                  ),
                                  const TaperedVerticalDivider(height: 44),
                                  Expanded(
                                    child: _LabeledValue(
                                      label: 'Segment',
                                      value: d.segment,
                                      alignCenter: true,
                                    ),
                                  ),
                                  const TaperedVerticalDivider(height: 44),
                                  Expanded(
                                    child: _LabeledValue(
                                      label: 'Category',
                                      value: d.category,
                                      alignEnd: true,
                                    ),
                                  ),
                                ],
                              ),
                              const TaperedHorizontalDivider(verticalPadding: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(
                                    child: _LabeledValue(
                                      label: 'Entry',
                                      value: d.entry,
                                    ),
                                  ),
                                  const TaperedVerticalDivider(height: 44),
                                  Expanded(
                                    child: _LabeledValue(
                                      label: 'Stop loss',
                                      value: d.sl,
                                      alignCenter: true,
                                    ),
                                  ),
                                  const TaperedVerticalDivider(height: 44),
                                  Expanded(
                                    child: _LabeledValue(
                                      label: 'Target',
                                      value: d.target,
                                      alignEnd: true,
                                    ),
                                  ),
                                ],
                              ),
                              const TaperedHorizontalDivider(verticalPadding: 12),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: _LabeledValue(
                                      label: 'Estimated risk',
                                      value: d.estimatedRisk,
                                      valueColor: ColorConstants.red,
                                    ),
                                  ),
                                  const TaperedVerticalDivider(height: 44),
                                  Expanded(
                                    child: _LabeledValue(
                                      label: 'Live return',
                                      value: d.liveReturn,
                                      valueColor: ColorConstants.amber,
                                      alignEnd: true,
                                    ),
                                  ),
                                ],
                              ),
                              const TaperedHorizontalDivider(verticalPadding: 12),
                              _DetailRow(
                                label: 'Entry date & time',
                                value: d.entryDateTime,
                              ),
                              const TaperedHorizontalDivider(verticalPadding: 10),
                              _DetailRow(
                                label: 'Status',
                                value: d.status,
                                valueColor: statusColor,
                              ),
                              const TaperedHorizontalDivider(verticalPadding: 10),
                              _DetailRow(label: 'Batch', value: d.batchName),
                              const TaperedHorizontalDivider(verticalPadding: 10),
                              _DetailRow(
                                label: 'Signal type',
                                value: d.signalType,
                              ),
                              const TaperedHorizontalDivider(verticalPadding: 10),
                              _DetailRow(
                                label: 'Entry zone',
                                value: d.entryZone,
                              ),
                              const TaperedHorizontalDivider(verticalPadding: 10),
                              _DetailRow(
                                label: 'Exit zone',
                                value: d.exitZone,
                              ),
                              const TaperedHorizontalDivider(verticalPadding: 10),
                              _DetailRow(
                                label: 'NSE timestamp',
                                value: d.nseTimestamp,
                                valueMono: true,
                              ),
                              if (d.rationale != null &&
                                  d.rationale!.isNotEmpty) ...<Widget>[
                                const TaperedHorizontalDivider(
                                  verticalPadding: 10,
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Rationale',
                                    style: TextStyleConstants.caption.copyWith(
                                      fontSize: AppSize.sp(context, 11),
                                      fontWeight: FontWeight.w600,
                                      color: ColorConstants.mute,
                                    ),
                                  ),
                                ),
                                SizedBox(height: AppSize.h(context, 6)),
                                Text(
                                  d.rationale!,
                                  style: TextStyleConstants.bodyMedium.copyWith(
                                    fontSize: AppSize.sp(context, 13),
                                    height: 1.45,
                                    color: ColorConstants.ink
                                        .withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: AppSize.h(context, 20)),
                        Text(
                          'Actions',
                          style: TextStyleConstants.cardTitle.copyWith(
                            fontSize: AppSize.sp(context, 16),
                          ),
                        ),
                        SizedBox(height: AppSize.h(context, 4)),
                        Text(
                          'This trade action has been performed.',
                          style: TextStyleConstants.caption.copyWith(
                            fontSize: AppSize.sp(context, 12),
                            fontStyle: FontStyle.italic,
                            color: ColorConstants.mute,
                          ),
                        ),
                        SizedBox(height: AppSize.h(context, 10)),
                        ...d.actions.map(
                          (_TradeAction action) => Padding(
                            padding: EdgeInsets.only(
                              bottom: AppSize.h(context, 10),
                            ),
                            child: _SurfaceCard(
                              child: Column(
                                children: <Widget>[
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Expanded(
                                        child: _LabeledValue(
                                          label: 'Action',
                                          value: action.title,
                                        ),
                                      ),
                                      _LabeledValue(
                                        label: 'Price',
                                        value: action.price,
                                        alignEnd: true,
                                      ),
                                    ],
                                  ),
                                  const TaperedHorizontalDivider(
                                    verticalPadding: 10,
                                  ),
                                  _DetailRow(
                                    label: 'Updated at',
                                    value: action.updatedAt,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: AppSize.h(context, 10)),
                        Text(
                          'Profile data',
                          style: TextStyleConstants.cardTitle.copyWith(
                            fontSize: AppSize.sp(context, 16),
                          ),
                        ),
                        SizedBox(height: AppSize.h(context, 10)),
                        _SurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  _AdvisorTagChip(label: d.advisorSegmentTag),
                                  SizedBox(width: AppSize.w(context, 10)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Wrap(
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          spacing: AppSize.w(context, 6),
                                          runSpacing: AppSize.h(context, 4),
                                          children: <Widget>[
                                            Text(
                                              d.advisorName,
                                              style: TextStyleConstants
                                                  .cardTitle
                                                  .copyWith(
                                                fontSize:
                                                    AppSize.sp(context, 15),
                                              ),
                                            ),
                                            const SebiVerifiedPill(
                                              compact: true,
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: AppSize.h(context, 4)),
                                        Text(
                                          'SEBI Reg: ${d.sebiReg}',
                                          style: TextStyleConstants.caption
                                              .copyWith(
                                            fontSize: AppSize.sp(context, 11),
                                            fontWeight: FontWeight.w600,
                                            color: ColorConstants.brandBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: AppSize.h(context, 14)),
                              CommonButtonWidget(
                                label: 'View profile',
                                height: 44,
                                borderRadius: 10,
                                backgroundColor: ColorConstants.white,
                                foregroundColor: ColorConstants.brandBlue,
                                borderColor: ColorConstants.brandBlue,
                                onPressed: () =>
                                    context.push(AppRoutingName.advisorProfile),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: AppSize.h(context, 16)),
                        const SebiDisclaimerStrip(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TradeAction {
  const _TradeAction({
    required this.title,
    required this.price,
    required this.updatedAt,
  });

  final String title;
  final String price;
  final String updatedAt;
}

class _SignalDetails {
  const _SignalDetails({
    required this.symbol,
    required this.company,
    required this.exchange,
    required this.initials,
    required this.currentPrice,
    required this.change,
    required this.isProfit,
    required this.batchName,
    required this.category,
    required this.estimatedRisk,
    required this.liveReturn,
    required this.signalType,
    required this.entry,
    required this.sl,
    required this.target,
    required this.direction,
    required this.segment,
    required this.entryDateTime,
    required this.status,
    required this.statusIsNeutral,
    required this.entryZone,
    required this.exitZone,
    required this.nseTimestamp,
    required this.advisorName,
    required this.advisorInitials,
    required this.advisorSegmentTag,
    required this.sebiReg,
    required this.actions,
    this.rationale,
  });

  final String symbol;
  final String company;
  final String exchange;
  final String initials;
  final String currentPrice;
  final String change;
  final bool isProfit;
  final String batchName;
  final String category;
  final String estimatedRisk;
  final String liveReturn;
  final String signalType;
  final String entry;
  final String sl;
  final String target;
  final String direction;
  final String segment;
  final String entryDateTime;
  final String status;
  final bool statusIsNeutral;
  final String entryZone;
  final String exitZone;
  final String nseTimestamp;
  final String advisorName;
  final String advisorInitials;
  final String advisorSegmentTag;
  final String sebiReg;
  final List<_TradeAction> actions;
  final String? rationale;
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSize.insets(context, left: 14, right: 14, top: 14, bottom: 14),
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(AppSize.r(context, 16)),
        border: Border.all(
          color: ColorConstants.navy.withValues(alpha: 0.06),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: ColorConstants.navy.withValues(alpha: 0.05),
            blurRadius: AppSize.r(context, 16),
            offset: Offset(0, AppSize.h(context, 4)),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SymbolAvatar extends StatelessWidget {
  const _SymbolAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSize.r(context, 48),
      height: AppSize.r(context, 48),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.r(context, 14)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            ColorConstants.avatarBlueStart,
            ColorConstants.avatarBlueEnd,
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: ColorConstants.brandBlue.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        initials,
        style: TextStyleConstants.cardTitleSmall.copyWith(
          color: ColorConstants.white,
          fontSize: AppSize.sp(context, 14),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AdvisorTagChip extends StatelessWidget {
  const _AdvisorTagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSize.r(context, 52),
      height: AppSize.r(context, 52),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ColorConstants.liveBg,
        borderRadius: BorderRadius.circular(AppSize.r(context, 10)),
        border: Border.all(color: ColorConstants.line),
      ),
      child: Text(
        label,
        style: TextStyleConstants.caption.copyWith(
          fontSize: AppSize.sp(context, 9),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: ColorConstants.brandBlue,
        ),
      ),
    );
  }
}

class _ExchangePill extends StatelessWidget {
  const _ExchangePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSize.symmetric(context, horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ColorConstants.liveBg,
        borderRadius: BorderRadius.circular(AppSize.r(context, 6)),
        border: Border.all(
          color: ColorConstants.brandBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: TextStyleConstants.caption.copyWith(
          fontSize: AppSize.sp(context, 10),
          fontWeight: FontWeight.w700,
          color: ColorConstants.brandBlue,
        ),
      ),
    );
  }
}

class _LabeledValue extends StatelessWidget {
  const _LabeledValue({
    required this.label,
    required this.value,
    this.valueColor = ColorConstants.ink,
    this.alignEnd = false,
    this.alignCenter = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool alignEnd;
  final bool alignCenter;

  CrossAxisAlignment get _crossAxisAlignment {
    if (alignEnd) return CrossAxisAlignment.end;
    if (alignCenter) return CrossAxisAlignment.center;
    return CrossAxisAlignment.start;
  }

  TextAlign get _textAlign {
    if (alignEnd) return TextAlign.right;
    if (alignCenter) return TextAlign.center;
    return TextAlign.left;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: _crossAxisAlignment,
      children: <Widget>[
        Text(
          label,
          textAlign: _textAlign,
          style: TextStyleConstants.caption.copyWith(
            fontSize: AppSize.sp(context, 11),
            fontWeight: FontWeight.w500,
            color: ColorConstants.mute,
          ),
        ),
        SizedBox(height: AppSize.h(context, 4)),
        Text(
          value,
          textAlign: _textAlign,
          style: TextStyleConstants.numeric.copyWith(
            fontSize: AppSize.sp(context, 14),
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor = ColorConstants.navy,
    this.valueMono = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool valueMono;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyleConstants.caption.copyWith(
              fontSize: AppSize.sp(context, 12),
              color: ColorConstants.mute,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: (valueMono
                    ? TextStyleConstants.caption
                    : TextStyleConstants.bodyMedium)
                .copyWith(
              fontSize: AppSize.sp(context, 12),
              fontWeight: FontWeight.w700,
              color: valueColor,
              fontFeatures: valueMono
                  ? const <FontFeature>[FontFeature.tabularFigures()]
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
