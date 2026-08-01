import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../../core/widgets/common_button_widget.dart';
import '../../../../core/widgets/common_trading_card.dart';
import '../../../../core/widgets/risk_badge.dart';
import '../../../../core/widgets/sebi_verified_pill.dart';
import '../../../../core/widgets/segment_tag_chip.dart';
import '../../../discover/data/models/discover_batch_model.dart';
import '../../../discover/domain/repositories/discover_repository.dart';
import '../../../home/domain/entities/home_subscription.dart';
import '../../../home/domain/entities/home_trade.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../../home/presentation/mappers/home_ui_mapper.dart';

class BatchDetailsPage extends StatefulWidget {
  const BatchDetailsPage({super.key, this.planId});

  final String? planId;

  @override
  State<BatchDetailsPage> createState() => _BatchDetailsPageState();
}

class _BatchDetailsPageState extends State<BatchDetailsPage> {
  final DiscoverRepository _discover =
      GetIt.instance<DiscoverRepository>();
  final HomeRepository _home = GetIt.instance<HomeRepository>();

  DiscoverBatchModel? _plan;
  List<HomeTrade> _trades = const <HomeTrade>[];
  HomeSubscription? _subscription;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final planId = widget.planId?.trim();
    if (planId == null || planId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Batch information is unavailable.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plan = await _discover.fetchPlan(planId);
      final results = await Future.wait<Object>(<Future<Object>>[
        _home.fetchFeed(
          page: 1,
          analystId: plan.analystId,
          status: 'LIVE,CLOSED',
        ),
        _home.fetchSubscriptions(),
      ]);
      if (!mounted) return;
      final feed = results[0] as HomeFeedPage;
      final subscriptions = results[1] as List<HomeSubscription>;
      final matchingSubscriptions =
          subscriptions.where((item) => item.planId == plan.planId);
      setState(() {
        _plan = plan;
        _trades = feed.trades
            .where((trade) => trade.planId == plan.planId)
            .toList();
        _subscription =
            matchingSubscriptions.isEmpty ? null : matchingSubscriptions.first;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load this batch right now.';
      });
    }
  }

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
                  padding: AppSize.insets(
                    context,
                    left: 16,
                    right: 16,
                    top: 8,
                  ),
                  child: AppBackHeader(
                    title: 'Batch Details',
                    onBack: () => context.pop(),
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? _ErrorState(message: _error!, onRetry: _load)
                          : _content(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    final plan = _plan!;
    final tags = <String>[...plan.segments, ...plan.horizons];
    final initials = _initials(plan.analystName);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSize.insets(
          context,
          left: 16,
          right: 16,
          top: 16,
          bottom: _subscription?.isActive == true ? 110 : 30,
        ),
        children: <Widget>[
          Container(
            padding: AppSize.insets(
              context,
              left: 18,
              right: 18,
              top: 20,
              bottom: 18,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFF0B2A63), Color(0xFF1A5CC8)],
              ),
              borderRadius: BorderRadius.circular(AppSize.r(context, 22)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: ColorConstants.brandBlue.withValues(alpha: 0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  plan.name,
                  style: TextStyleConstants.screenTitle.copyWith(
                    fontSize: AppSize.sp(context, 24),
                    color: ColorConstants.white,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: AppSize.h(context, 18)),
                Material(
                  color: ColorConstants.white.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(AppSize.r(context, 16)),
                  child: InkWell(
                    onTap: () => context.push(
                      AppRoutingName.advisorProfile,
                      extra: plan.analystId,
                    ),
                    borderRadius:
                        BorderRadius.circular(AppSize.r(context, 16)),
                    child: Padding(
                      padding: EdgeInsets.all(AppSize.r(context, 12)),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: AppSize.r(context, 48),
                            height: AppSize.r(context, 48),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: ColorConstants.white,
                              borderRadius:
                                  BorderRadius.circular(AppSize.r(context, 14)),
                            ),
                            child: Text(
                              initials,
                              style: TextStyleConstants.cardTitle.copyWith(
                                color: ColorConstants.brandBlue,
                              ),
                            ),
                          ),
                          SizedBox(width: AppSize.w(context, 12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Managed by',
                                  style: TextStyleConstants.caption.copyWith(
                                    color: ColorConstants.white
                                        .withValues(alpha: 0.72),
                                  ),
                                ),
                                SizedBox(height: AppSize.h(context, 2)),
                                Text(
                                  plan.analystName,
                                  style:
                                      TextStyleConstants.cardTitle.copyWith(
                                    fontSize: AppSize.sp(context, 15),
                                    color: ColorConstants.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (plan.analystSebiNumber?.isNotEmpty == true)
                            const SebiVerifiedPill(compact: true),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: ColorConstants.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSize.h(context, 16)),
                Wrap(
                  spacing: AppSize.w(context, 8),
                  runSpacing: AppSize.h(context, 8),
                  children: <Widget>[
                    RiskBadge(
                      level: RiskBadge.fromString(plan.riskLevel ?? ''),
                    ),
                    ...tags.map((tag) => SegmentTagChip(label: tag)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: AppSize.h(context, 24)),
          _SectionCard(
            icon: Icons.info_outline_rounded,
            title: 'About this batch',
            child: Text(
              plan.description?.trim().isNotEmpty == true
                  ? plan.description!.trim()
                  : plan.name,
              style: TextStyleConstants.bodyMedium.copyWith(
                color: ColorConstants.mute,
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: AppSize.h(context, 22)),
          _SectionHeading(
            icon: Icons.candlestick_chart_rounded,
            title: 'Recent trades',
          ),
          SizedBox(height: AppSize.h(context, 12)),
          if (_trades.isEmpty)
            Container(
              width: double.infinity,
              padding: AppSize.symmetric(context, vertical: 28),
              decoration: BoxDecoration(
                color: ColorConstants.white,
                borderRadius: BorderRadius.circular(AppSize.r(context, 18)),
                border: Border.all(color: ColorConstants.line),
              ),
              child: Column(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.all(AppSize.r(context, 10)),
                    decoration: const BoxDecoration(
                      color: ColorConstants.liveBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.show_chart_rounded,
                      color: ColorConstants.brandBlue,
                    ),
                  ),
                  SizedBox(height: AppSize.h(context, 10)),
                  Text(
                    'No recent trades yet',
                    style: TextStyleConstants.cardTitle.copyWith(
                      fontSize: AppSize.sp(context, 15),
                    ),
                  ),
                  SizedBox(height: AppSize.h(context, 4)),
                  Text(
                    'New trade ideas from this batch will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyleConstants.caption.copyWith(
                      color: ColorConstants.mute,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._trades.take(3).map(
                  (trade) => Padding(
                    padding: EdgeInsets.only(
                      bottom: AppSize.h(context, 14),
                    ),
                    child: CommonTradingCard(
                      data: mapHomeTradeToCard(trade),
                      onViewDetails: () => context.push(
                        AppRoutingName.tradeDetails,
                        extra: trade,
                      ),
                    ),
                  ),
                ),
          SizedBox(height: AppSize.h(context, 22)),
          _SectionHeading(
            icon: Icons.workspace_premium_outlined,
            title: 'Plans & Pricing',
          ),
          SizedBox(height: AppSize.h(context, 12)),
          ...plan.tiers.where((tier) => tier.isActive).map(_tierCard),
          if (_subscription?.isActive == true) ...<Widget>[
            SizedBox(height: AppSize.h(context, 18)),
            _ActiveSubscription(subscription: _subscription!),
          ],
        ],
      ),
    );
  }

  Widget _tierCard(DiscoverBatchTierModel tier) {
    final subscribed = _subscription?.isActive == true &&
        (_subscription?.batchId == tier.id ||
            _subscription?.planId == _plan?.planId);
    final price = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: tier.effectivePrice % 1 == 0 ? 0 : 2,
    ).format(tier.effectivePrice);
    return Container(
      margin: EdgeInsets.only(bottom: AppSize.h(context, 12)),
      padding: AppSize.insets(
        context,
        left: 14,
        right: 14,
        top: 14,
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(AppSize.r(context, 18)),
        border: Border.all(
          color: subscribed
              ? ColorConstants.green
              : ColorConstants.brandBlue.withValues(alpha: 0.16),
          width: subscribed ? 2 : 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: ColorConstants.shadowSoft.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  tier.name,
                  style: TextStyleConstants.cardTitle.copyWith(
                    fontSize: AppSize.sp(context, 16),
                  ),
                ),
                Text(
                  '${tier.days} days',
                  style: TextStyleConstants.caption.copyWith(
                    color: ColorConstants.mute,
                  ),
                ),
                SizedBox(height: AppSize.h(context, 12)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      price,
                      style: TextStyleConstants.screenTitle.copyWith(
                        fontSize: AppSize.sp(context, 24),
                        color: ColorConstants.brandBlue,
                      ),
                    ),
                    if (tier.billingCycle?.isNotEmpty == true) ...<Widget>[
                      SizedBox(width: AppSize.w(context, 4)),
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: AppSize.h(context, 3),
                        ),
                        child: Text(
                          '/${tier.billingCycle!.toLowerCase()}',
                          style: TextStyleConstants.caption.copyWith(
                            color: ColorConstants.mute,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          CommonButtonWidget(
            label: subscribed ? 'Subscribed' : 'Subscribe',
            onPressed: subscribed
                ? null
                : () => context.push(AppRoutingName.subscriptions),
            width: null,
            horizontalPadding: 16,
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}

class _ActiveSubscription extends StatelessWidget {
  const _ActiveSubscription({required this.subscription});

  final HomeSubscription subscription;

  @override
  Widget build(BuildContext context) {
    final endDate = subscription.endDate == null
        ? ''
        : DateFormat('dd MMM yyyy').format(subscription.endDate!);
    return Row(
      children: <Widget>[
        const Icon(Icons.check_circle, color: ColorConstants.green),
        SizedBox(width: AppSize.w(context, 8)),
        Expanded(
          child: Text(
            endDate.isEmpty
                ? 'Active subscription'
                : 'Active subscription — expires $endDate',
            style: TextStyleConstants.bodyMedium.copyWith(
              color: ColorConstants.green,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: () => context.push(AppRoutingName.mySubscriptions),
          child: const Text('Manage'),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: AppSize.r(context, 34),
          height: AppSize.r(context, 34),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ColorConstants.liveBg,
            borderRadius: BorderRadius.circular(AppSize.r(context, 10)),
          ),
          child: Icon(
            icon,
            size: AppSize.r(context, 19),
            color: ColorConstants.brandBlue,
          ),
        ),
        SizedBox(width: AppSize.w(context, 10)),
        Text(
          title,
          style: TextStyleConstants.cardTitle.copyWith(
            fontSize: AppSize.sp(context, 19),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSize.r(context, 18)),
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(AppSize.r(context, 18)),
        border: Border.all(color: ColorConstants.line),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: ColorConstants.shadowSoft.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SectionHeading(icon: icon, title: title),
          SizedBox(height: AppSize.h(context, 14)),
          child,
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(message),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
