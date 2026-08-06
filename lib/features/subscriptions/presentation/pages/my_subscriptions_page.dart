import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../../core/widgets/common_app_notification_bar.dart';
import '../../../../core/widgets/common_button_widget.dart';
import '../../../home/domain/entities/home_subscription.dart';
import '../../../home/domain/repositories/home_repository.dart';

class MySubscriptionsPage extends StatefulWidget {
  const MySubscriptionsPage({super.key});

  @override
  State<MySubscriptionsPage> createState() => _MySubscriptionsPageState();
}

class _MySubscriptionsPageState extends State<MySubscriptionsPage> {
  late Future<List<HomeSubscription>> _subscriptions;
  String? _cancellingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _subscriptions = GetIt.instance<HomeRepository>().fetchSubscriptions();
  }

  Future<void> _refresh() async {
    GetIt.instance<HomeRepository>().invalidateSubscriptions();
    setState(_load);
    await _subscriptions;
  }

  Future<void> _cancelSubscription(HomeSubscription subscription) async {
    if (_cancellingId != null) return;

    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _CancelSubscriptionDialog(),
    );
    if (reason == null || !mounted) return;

    setState(() => _cancellingId = subscription.id);
    try {
      await GetIt.instance<HomeRepository>().cancelSubscription(
        subscription.id,
        reason: reason,
      );
      if (!mounted) return;
      await CommonAppNotificationBar.success(
        context: context,
        title: 'Subscription cancelled',
        message: 'Your subscription has been cancelled successfully.',
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      final message = e is Failure
          ? e.message
          : 'Unable to cancel this subscription. Please try again.';
      await CommonAppNotificationBar.error(
        context: context,
        title: 'Cancellation failed',
        message: message,
      );
    } finally {
      if (mounted) setState(() => _cancellingId = null);
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
            child: Padding(
              padding: AppSize.insets(context, left: 16, right: 16, top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppBackHeader(
                    title: 'Subscriptions',
                    onBack: () => context.pop(),
                  ),
                  SizedBox(height: AppSize.h(context, 16)),
                  Expanded(
                    child: FutureBuilder<List<HomeSubscription>>(
                      future: _subscriptions,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return _ErrorState(
                            onRetry: () => setState(_load),
                          );
                        }
                        final items =
                            snapshot.data ?? const <HomeSubscription>[];
                        if (items.isEmpty) {
                          return const Center(
                            child: Text('No subscriptions found'),
                          );
                        }
                        return RefreshIndicator(
                          onRefresh: _refresh,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.only(
                              bottom: AppSize.h(context, 24),
                            ),
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                SizedBox(height: AppSize.h(context, 12)),
                            itemBuilder: (_, index) {
                              final item = items[index];
                              return _SubscriptionCard(
                                subscription: item,
                                isCancelling: _cancellingId == item.id,
                                onCancel: item.isActive
                                    ? () => _cancelSubscription(item)
                                    : null,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.subscription,
    this.onCancel,
    this.isCancelling = false,
  });

  final HomeSubscription subscription;
  final VoidCallback? onCancel;
  final bool isCancelling;

  String _date(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _money(double value) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: subscription.paymentCurrency == 'INR' ? '₹' : '',
      decimalDigits: value % 1 == 0 ? 0 : 2,
    ).format(value);
  }

  String get _statusLabel {
    return switch (subscription.status) {
      HomeSubscriptionStatus.active => 'ACTIVE',
      HomeSubscriptionStatus.expired => 'EXPIRED',
      HomeSubscriptionStatus.cancelled => 'CANCELLED',
      HomeSubscriptionStatus.paymentFailed => 'PAYMENT FAILED',
      HomeSubscriptionStatus.pending => 'PENDING',
    };
  }

  Color get _statusColor {
    return switch (subscription.status) {
      HomeSubscriptionStatus.active => ColorConstants.green,
      HomeSubscriptionStatus.expired => ColorConstants.mute,
      HomeSubscriptionStatus.cancelled ||
      HomeSubscriptionStatus.paymentFailed => ColorConstants.red,
      HomeSubscriptionStatus.pending => const Color(0xFFF59E0B),
    };
  }

  @override
  Widget build(BuildContext context) {
    final planName = subscription.planName?.trim().isNotEmpty == true
        ? subscription.planName!.trim()
        : subscription.batchName;
    return Container(
      padding: AppSize.insets(
        context,
        left: 14,
        right: 14,
        top: 14,
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(AppSize.r(context, 16)),
        border: Border.all(color: ColorConstants.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: AppSize.r(context, 44),
                height: AppSize.r(context, 44),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorConstants.brandBlue.withValues(alpha: 0.1),
                ),
                child: Text(
                  subscription.initials,
                  style: TextStyleConstants.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.brandBlue,
                    fontSize: AppSize.sp(context, 13),
                  ),
                ),
              ),
              SizedBox(width: AppSize.w(context, 11)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      planName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyleConstants.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ColorConstants.ink,
                        fontSize: AppSize.sp(context, 14),
                      ),
                    ),
                    SizedBox(height: AppSize.h(context, 3)),
                    Text(
                      '${subscription.analystName ?? 'Analyst'} • '
                      '${subscription.batchName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyleConstants.caption.copyWith(
                        fontSize: AppSize.sp(context, 11.5),
                        color: ColorConstants.mute,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSize.w(context, 8)),
              Container(
                padding: AppSize.symmetric(
                  context,
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSize.r(context, 20)),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyleConstants.caption.copyWith(
                    color: _statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: AppSize.sp(context, 9.5),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSize.h(context, 12)),
          const Divider(height: 1, color: ColorConstants.line),
          SizedBox(height: AppSize.h(context, 10)),
          Row(
            children: <Widget>[
              Expanded(
                child: _Detail(
                  label: 'Started',
                  value: _date(subscription.startDate),
                ),
              ),
              Expanded(
                child: _Detail(
                  label: subscription.isActive ? 'Valid until' : 'Ended',
                  value: _date(subscription.endDate),
                  alignRight: true,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSize.h(context, 10)),
          Row(
            children: <Widget>[
              Expanded(
                child: _Detail(
                  label: 'Paid',
                  value: _money(subscription.paymentAmount),
                ),
              ),
              Expanded(
                child: _Detail(
                  label: 'Auto-renew',
                  value: subscription.autoRenew ? 'Enabled' : 'Disabled',
                  alignRight: true,
                ),
              ),
            ],
          ),
          if (subscription.discountAmount > 0 ||
              (subscription.couponApplied ?? '').isNotEmpty) ...<Widget>[
            SizedBox(height: AppSize.h(context, 10)),
            Container(
              width: double.infinity,
              padding: AppSize.symmetric(
                context,
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: ColorConstants.green.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(AppSize.r(context, 9)),
              ),
              child: Text(
                'Discount ${_money(subscription.discountAmount)}'
                '${(subscription.couponApplied ?? '').isNotEmpty ? ' • ${subscription.couponApplied}' : ''}',
                style: TextStyleConstants.caption.copyWith(
                  color: ColorConstants.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (onCancel != null) ...<Widget>[
            SizedBox(height: AppSize.h(context, 12)),
            CommonButtonWidget(
              label: 'Cancel subscription',
              onPressed: onCancel,
              isLoading: isCancelling,
              backgroundColor: ColorConstants.white,
              foregroundColor: ColorConstants.red,
              disabledBackgroundColor: ColorConstants.white,
              disabledForegroundColor: ColorConstants.red,
              borderColor: ColorConstants.red.withValues(alpha: 0.35),
              height: 42,
              borderRadius: 10,
            ),
          ],
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.label,
    required this.value,
    this.alignRight = false,
  });

  final String label;
  final String value;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyleConstants.caption.copyWith(
            color: ColorConstants.mute,
            fontSize: AppSize.sp(context, 10.5),
          ),
        ),
        SizedBox(height: AppSize.h(context, 2)),
        Text(
          value,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: TextStyleConstants.bodyMedium.copyWith(
            color: ColorConstants.ink,
            fontWeight: FontWeight.w600,
            fontSize: AppSize.sp(context, 12),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Unable to load subscriptions'),
          SizedBox(height: AppSize.h(context, 10)),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _CancelSubscriptionDialog extends StatefulWidget {
  const _CancelSubscriptionDialog();

  @override
  State<_CancelSubscriptionDialog> createState() =>
      _CancelSubscriptionDialogState();
}

class _CancelSubscriptionDialogState extends State<_CancelSubscriptionDialog> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _reasonController.text.trim().isNotEmpty;
    return AlertDialog(
      title: const Text('Cancel subscription?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'You will lose access to this plan after cancellation. '
            'Please tell us why you are cancelling.',
          ),
          SizedBox(height: AppSize.h(context, 16)),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            maxLength: 250,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'Why are you cancelling?',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: AppSize.h(context, 8)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorConstants.brandBlue,
                    side: const BorderSide(color: ColorConstants.brandBlue),
                    padding: AppSize.symmetric(
                      context,
                      horizontal: 8,
                      vertical: 12,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSize.r(context, 12),
                      ),
                    ),
                  ),
                  child: Text(
                    'Keep subscription',
                    textAlign: TextAlign.center,
                    style: TextStyleConstants.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ColorConstants.brandBlue,
                      fontSize: AppSize.sp(context, 12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppSize.w(context, 10)),
              Expanded(
                child: FilledButton(
                  onPressed: canSubmit
                      ? () => Navigator.of(context)
                          .pop(_reasonController.text.trim())
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: ColorConstants.red,
                    disabledBackgroundColor:
                        ColorConstants.red.withValues(alpha: 0.35),
                    foregroundColor: ColorConstants.white,
                    padding: AppSize.symmetric(
                      context,
                      horizontal: 8,
                      vertical: 12,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSize.r(context, 12),
                      ),
                    ),
                  ),
                  child: Text(
                    'Cancel subscription',
                    textAlign: TextAlign.center,
                    style: TextStyleConstants.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ColorConstants.white,
                      fontSize: AppSize.sp(context, 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
