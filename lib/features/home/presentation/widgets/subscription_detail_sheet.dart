import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/utils/app_size.dart';
import '../../domain/entities/home_subscription.dart';

void showSubscriptionDetailSheet(
  BuildContext context,
  HomeSubscription sub,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ColorConstants.transparent,
    builder: (_) => _SubscriptionDetailSheet(sub: sub),
  );
}

class _SubscriptionDetailSheet extends StatelessWidget {
  const _SubscriptionDetailSheet({required this.sub});

  final HomeSubscription sub;

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('dd MMM yyyy').format(dt.toLocal());
  }

  String _statusLabel(HomeSubscriptionStatus s) {
    switch (s) {
      case HomeSubscriptionStatus.active:
        return 'Active';
      case HomeSubscriptionStatus.expired:
        return 'Expired';
      case HomeSubscriptionStatus.cancelled:
        return 'Cancelled';
      case HomeSubscriptionStatus.paymentFailed:
        return 'Payment Failed';
      case HomeSubscriptionStatus.pending:
        return 'Pending';
    }
  }

  Color _statusColor(HomeSubscriptionStatus s) {
    switch (s) {
      case HomeSubscriptionStatus.active:
        return ColorConstants.green;
      case HomeSubscriptionStatus.expired:
      case HomeSubscriptionStatus.cancelled:
        return ColorConstants.mute;
      case HomeSubscriptionStatus.paymentFailed:
        return ColorConstants.red;
      case HomeSubscriptionStatus.pending:
        return ColorConstants.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = _statusLabel(sub.status);
    final statusColor = _statusColor(sub.status);
    final initials = sub.initials;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSize.r(context, 22)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // drag handle
            Padding(
              padding: EdgeInsets.only(top: AppSize.h(context, 10)),
              child: Center(
                child: Container(
                  width: AppSize.w(context, 36),
                  height: AppSize.h(context, 4),
                  decoration: BoxDecoration(
                    color: ColorConstants.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // header row
            Padding(
              padding: AppSize.insets(
                context,
                left: 18,
                right: 10,
                top: 14,
                bottom: 12,
              ),
              child: Row(
                children: <Widget>[
                  // avatar
                  Container(
                    width: AppSize.r(context, 44),
                    height: AppSize.r(context, 44),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          ColorConstants.brandBlueLight,
                          ColorConstants.brandBlue,
                        ],
                      ),
                    ),
                    child: Text(
                      initials,
                      style: TextStyleConstants.bodyMedium.copyWith(
                        color: ColorConstants.white,
                        fontSize: AppSize.sp(context, 15),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSize.w(context, 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          sub.displayName,
                          style: TextStyleConstants.cardTitle.copyWith(
                            fontSize: AppSize.sp(context, 16),
                          ),
                        ),
                        SizedBox(height: AppSize.h(context, 2)),
                        Row(
                          children: <Widget>[
                            Container(
                              padding: AppSize.symmetric(
                                context,
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  AppSize.r(context, 6),
                                ),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyleConstants.caption.copyWith(
                                  fontSize: AppSize.sp(context, 11),
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: ColorConstants.mute,
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: ColorConstants.line),

            // scrollable detail rows
            Flexible(
              child: ListView(
                padding: AppSize.insets(
                  context,
                  left: 18,
                  right: 18,
                  top: 8,
                  bottom: 24,
                ),
                shrinkWrap: true,
                children: <Widget>[
                  if (sub.planName != null)
                    _Row(label: 'Plan', value: sub.planName!),
                  if (sub.batchName.isNotEmpty)
                    _Row(label: 'Batch', value: sub.batchName),
                  _Row(label: 'Start date', value: _fmt(sub.startDate)),
                  _Row(label: 'End date', value: _fmt(sub.endDate)),
                  _Row(
                    label: 'Amount paid',
                    value:
                        '${sub.paymentCurrency} ${sub.paymentAmount.toStringAsFixed(2)}',
                  ),
                  if (sub.discountAmount > 0)
                    _Row(
                      label: 'Discount',
                      value:
                          '${sub.paymentCurrency} ${sub.discountAmount.toStringAsFixed(2)}',
                    ),
                  if (sub.couponApplied != null &&
                      sub.couponApplied!.isNotEmpty)
                    _Row(label: 'Coupon', value: sub.couponApplied!),
                  _Row(
                    label: 'Auto-renew',
                    value: sub.autoRenew ? 'On' : 'Off',
                  ),
                  if (sub.transactionId != null &&
                      sub.transactionId!.isNotEmpty)
                    _Row(
                      label: 'Transaction ID',
                      value: sub.transactionId!,
                      mono: true,
                    ),
                  _Row(
                    label: 'Subscription ID',
                    value: sub.id,
                    mono: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.mono = false,
  });

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSize.h(context, 11)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: AppSize.w(context, 130),
            child: Text(
              label,
              style: TextStyleConstants.bodyMedium.copyWith(
                fontSize: AppSize.sp(context, 13),
                color: ColorConstants.mute,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: (mono
                      ? TextStyleConstants.numeric
                      : TextStyleConstants.bodyMedium)
                  .copyWith(
                fontSize: AppSize.sp(context, 13),
                fontWeight: FontWeight.w600,
                color: ColorConstants.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
