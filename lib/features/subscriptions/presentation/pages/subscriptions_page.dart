import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/payments/payment_checkout.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/common_app_notification_bar.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../../core/widgets/common_button_widget.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../discover/data/models/discover_batch_model.dart';
import '../../../discover/domain/repositories/discover_repository.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../home/domain/repositories/home_repository.dart';

class SubscriptionPageArgs {
  const SubscriptionPageArgs({
    required this.planId,
    required this.analystId,
    this.batchId,
  });

  final String planId;
  final String analystId;
  final String? batchId;
}

/// App-side coupon cut: flat ₹ off or % of base. Never goes below 0.
double couponDiscountAmount({
  required double basePrice,
  required String type,
  required double discountValue,
}) {
  if (basePrice <= 0 || discountValue <= 0) return 0;
  final t = type.trim().toUpperCase();
  final isPercent = t == 'PERCENTAGE' ||
      t == 'PERCENT' ||
      t == 'PCT' ||
      t.contains('PERCENT');
  final cut = isPercent ? basePrice * (discountValue / 100.0) : discountValue;
  if (cut <= 0) return 0;
  return cut > basePrice ? basePrice : cut;
}

double couponPayableAmount({
  required double basePrice,
  required String type,
  required double discountValue,
}) {
  final discount = couponDiscountAmount(
    basePrice: basePrice,
    type: type,
    discountValue: discountValue,
  );
  final payable = basePrice - discount;
  return payable < 0 ? 0 : payable;
}

String _moneyLabel(double amount) {
  if (amount % 1 == 0) return '₹${amount.toInt()}';
  return '₹${amount.toStringAsFixed(2)}';
}

class SubscriptionsPage extends StatefulWidget {
  const SubscriptionsPage({super.key, this.planId, this.analystId, this.batchId});

  final String? planId;
  final String? analystId;
  final String? batchId;

  @override
  State<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends State<SubscriptionsPage> {
  final TextEditingController _couponController = TextEditingController();
  final FocusNode _couponFocusNode = FocusNode();
  String? _appliedCoupon;
  String? _appliedType;
  double _appliedDiscountValue = 0;
  Future<List<AvailableCoupon>>? _coupons;
  bool _verifyingCoupon = false;
  bool _creatingPayment = false;
  late final PaymentCheckout _paymentCheckout;
  SubscriptionCheckout? _pendingCheckout;

  DiscoverBatchModel? _plan;
  DiscoverBatchTierModel? _tier;
  bool _loadingPlan = true;
  double _basePrice = 0;

  double get _discountCut {
    if (_appliedCoupon == null || _appliedType == null) return 0;
    return couponDiscountAmount(
      basePrice: _basePrice,
      type: _appliedType!,
      discountValue: _appliedDiscountValue,
    );
  }

  double get _payableAmount {
    if (_appliedCoupon == null || _appliedType == null) return _basePrice;
    return couponPayableAmount(
      basePrice: _basePrice,
      type: _appliedType!,
      discountValue: _appliedDiscountValue,
    );
  }

  @override
  void initState() {
    super.initState();
    _paymentCheckout = createPaymentCheckout()
      ..on(
        success: _onPaymentSuccess,
        error: _onPaymentError,
        externalWallet: (_) {},
      );
    _couponFocusNode.addListener(_onCouponFocusChanged);
    final planId = widget.planId?.trim();
    final analystId = widget.analystId?.trim();
    if (planId?.isNotEmpty == true && analystId?.isNotEmpty == true) {
      _coupons = GetIt.instance<DiscoverRepository>().fetchAvailableCoupons(
        planId: planId!,
        analystId: analystId!,
      );
    }
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    final planId = widget.planId?.trim();
    if (planId == null || planId.isEmpty) {
      if (mounted) setState(() => _loadingPlan = false);
      return;
    }
    try {
      final plan =
          await GetIt.instance<DiscoverRepository>().fetchPlan(planId);
      if (!mounted) return;
      final batchId = widget.batchId?.trim();
      DiscoverBatchTierModel? tier;
      if (batchId != null && batchId.isNotEmpty) {
        for (final t in plan.tiers) {
          if (t.id == batchId) {
            tier = t;
            break;
          }
        }
      }
      tier ??= plan.cheapestTier;
      setState(() {
        _plan = plan;
        _tier = tier;
        // Use list price (not already-discounted) so coupons cut from original.
        _basePrice = tier?.price ?? plan.price;
        _loadingPlan = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPlan = false);
    }
  }

  void _onCouponFocusChanged() {
    if (mounted) setState(() {});
  }

  void _clearAppliedCoupon() {
    _appliedCoupon = null;
    _appliedType = null;
    _appliedDiscountValue = 0;
  }

  Future<void> _verifyCoupon({AvailableCoupon? fromList}) async {
    final code = _couponController.text.trim().toUpperCase();
    final planId = widget.planId?.trim();
    _couponFocusNode.unfocus();

    if (code.isEmpty) {
      await CommonAppNotificationBar.warning(
        context: context,
        title: 'Enter a coupon code',
        message: 'Enter a code before applying it.',
      );
      return;
    }
    if (planId == null || planId.isEmpty) {
      await CommonAppNotificationBar.error(
        context: context,
        title: 'Coupon unavailable',
        message: 'The selected plan is unavailable. Please try again.',
      );
      return;
    }

    setState(() => _verifyingCoupon = true);
    try {
      // Still verify eligibility with the server, but cut discount only in-app.
      final verification = await GetIt.instance<DiscoverRepository>()
          .verifyCoupon(code: code, planId: planId);
      if (!mounted) return;
      if (!verification.valid) {
        setState(_clearAppliedCoupon);
        await CommonAppNotificationBar.error(
          context: context,
          title: 'Invalid coupon',
          message: 'This coupon cannot be applied to the selected plan.',
        );
        return;
      }

      final type = (fromList?.type.isNotEmpty == true
              ? fromList!.type
              : verification.type)
          .trim();
      final value = (fromList != null && fromList.discountValue > 0)
          ? fromList.discountValue
          : verification.discountValue;

      final appliedCode = verification.code.isEmpty
          ? code
          : verification.code.trim().toUpperCase();
      final cut = couponDiscountAmount(
        basePrice: _basePrice,
        type: type,
        discountValue: value,
      );

      setState(() {
        _couponController.text = appliedCode;
        _appliedCoupon = appliedCode;
        _appliedType = type;
        _appliedDiscountValue = value;
      });
      await CommonAppNotificationBar.success(
        context: context,
        title: 'Coupon applied',
        message: cut > 0
            ? 'You saved ${_moneyLabel(cut)}.'
            : 'Coupon applied to this plan.',
        duration: const Duration(seconds: 2),
      );
    } catch (_) {
      if (!mounted) return;
      setState(_clearAppliedCoupon);
      await CommonAppNotificationBar.error(
        context: context,
        title: 'Coupon could not be verified',
        message: 'Check the code and try again.',
      );
    } finally {
      if (mounted) setState(() => _verifyingCoupon = false);
    }
  }

  void _removeCoupon() {
    _couponFocusNode.unfocus();
    setState(() {
      _couponController.clear();
      _clearAppliedCoupon();
    });
  }

  Future<void> _startSubscription() async {
    if (_creatingPayment) return;
    final planId = widget.planId?.trim();
    if (planId == null || planId.isEmpty) {
      await CommonAppNotificationBar.error(
        context: context,
        title: 'Subscription unavailable',
        message: 'The selected plan is unavailable. Please try again.',
      );
      return;
    }

    setState(() => _creatingPayment = true);
    try {
      AuthUser? user;
      try {
        user = await GetIt.instance<AuthRepository>().getMe();
      } catch (_) {
        // Payment can still proceed when the profile refresh is unavailable.
      }
      final payable = _payableAmount;
      final discount = _discountCut;
      final checkout = await GetIt.instance<DiscoverRepository>()
          .createSubscription(
            planId: planId,
            batchId: widget.batchId?.trim(),
            couponCode: _appliedCoupon,
            amount: payable,
            discountAmount: discount > 0 ? discount : null,
          );
      if (!mounted) return;
      if (checkout.subscriptionId.isEmpty ||
          checkout.razorpayOrderId.isEmpty ||
          checkout.amount <= 0 ||
          (kReleaseMode && checkout.keyId.isEmpty)) {
        throw Exception('Invalid payment order');
      }
      _pendingCheckout = checkout;
      setState(() => _creatingPayment = false);
      _paymentCheckout.open(<String, dynamic>{
        'key': checkout.keyId.isEmpty ? 'rzp_test_T4nri4iE8zYsih' : checkout.keyId,
        // Prefer server order amount (required for Razorpay), which should
        // match the client-computed payable once coupon is applied.
        'amount': checkout.amount,
        'currency': checkout.currency,
        'name': 'Stoxify',
        'description': 'Plan subscription',
        'order_id': checkout.razorpayOrderId,
        'prefill': <String, String>{
          if (user != null && _razorpayContact(user.phone).isNotEmpty)
            'contact': _razorpayContact(user.phone),
          if (user?.email?.trim().isNotEmpty == true) 'email': user!.email!.trim(),
        },
      });
    } catch (_) {
      if (!mounted) return;
      await CommonAppNotificationBar.error(
        context: context,
        title: 'Unable to start payment',
        message: 'Please try again in a moment.',
      );
    } finally {
      if (mounted && _creatingPayment) {
        setState(() => _creatingPayment = false);
      }
    }
  }

  String _razorpayContact(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length == 12 && digits.startsWith('91')
        ? digits.substring(2)
        : digits;
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResult response) async {
    final checkout = _pendingCheckout;
    if (checkout == null || !mounted || _creatingPayment) return;
    setState(() => _creatingPayment = true);
    try {
      await GetIt.instance<DiscoverRepository>().verifySubscriptionPayment(
        subscriptionId: checkout.subscriptionId,
        razorpayOrderId: response.orderId ?? checkout.razorpayOrderId,
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      );
      if (!mounted) return;
      GetIt.instance<HomeRepository>().invalidateSubscriptions();
      GetIt.instance<DiscoverRepository>().invalidatePlan(
        widget.planId!,
        analystId: widget.analystId,
      );
      context.go(AppRoutingName.paymentSuccess);
    } catch (_) {
      if (!mounted) return;
      await CommonAppNotificationBar.error(
        context: context,
        title: 'Payment verification failed',
        message: 'Your payment is pending. Please contact support if charged.',
      );
    } finally {
      if (mounted) setState(() => _creatingPayment = false);
    }
  }

  Future<void> _onPaymentError(PaymentFailureResult response) async {
    if (!mounted) return;
    _pendingCheckout = null;
    await CommonAppNotificationBar.error(
      context: context,
      title: 'Payment failed',
      message: response.message ?? 'Your payment could not be completed.',
    );
  }

  @override
  void dispose() {
    _paymentCheckout.clear();
    _couponFocusNode.removeListener(_onCouponFocusChanged);
    _couponController.dispose();
    _couponFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final priceLabel = _moneyLabel(_basePrice);
    final totalLabel = _moneyLabel(_payableAmount);
    final batchName = _plan?.name ?? '—';
    final planName = _tier?.name.isNotEmpty == true
        ? _tier!.name
        : (_tier?.billingCycle?.isNotEmpty == true
            ? _tier!.billingCycle!
            : 'Plan');
    final duration = (_tier?.days ?? 0) > 0
        ? '${_tier!.days} days'
        : '—';

    return Scaffold(
      backgroundColor: ColorConstants.transparent,
      body: Stack(
        children: <Widget>[
          const AppScreenBackground(),
          SafeArea(
            child: Padding(
              padding: AppSize.insets(context, left: 16, right: 16, top: 8),
              child: Column(
                children: <Widget>[
                  AppBackHeader(
                    title: 'Review',
                    onBack: () => context.pop(),
                  ),
                  SizedBox(height: AppSize.h(context, 14)),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: double.infinity,
                            padding: AppSize.insets(
                              context,
                              left: 14,
                              right: 14,
                              top: 14,
                              bottom: 14,
                            ),
                            decoration: BoxDecoration(
                              color: ColorConstants.white,
                              borderRadius:
                                  BorderRadius.circular(AppSize.r(context, 14)),
                              border: Border.all(color: ColorConstants.line),
                            ),
                            child: _loadingPlan
                                ? SizedBox(
                                    height: AppSize.h(context, 80),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: <Widget>[
                                      _Kv('Batch', batchName),
                                      _Kv('Plan', planName),
                                      _Kv('Duration', duration),
                                      _Kv('Price', priceLabel, emphasize: true),
                                      if (_appliedCoupon != null &&
                                          _discountCut > 0)
                                        _Kv(
                                          'Discount',
                                          '-${_moneyLabel(_discountCut)}',
                                        ),
                                    ],
                                  ),
                          ),
                          SizedBox(height: AppSize.h(context, 14)),
                          const AppSectionLabel('Coupon'),
                          SizedBox(height: AppSize.h(context, 8)),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 48,
                            decoration: BoxDecoration(
                              color: ColorConstants.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _couponFocusNode.hasFocus
                                    ? ColorConstants.brandBlue
                                    : ColorConstants.line,
                                width: _couponFocusNode.hasFocus ? 1.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: ColorConstants.navy.withValues(
                                    alpha: 0.08,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Expanded(
                                    child: TextFormField(
                                      controller: _couponController,
                                      focusNode: _couponFocusNode,
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      textAlignVertical:
                                          TextAlignVertical.center,
                                      cursorColor: ColorConstants.brandBlue,
                                      cursorWidth: 2,
                                      cursorHeight: 18,
                                      style:
                                          TextStyleConstants.bodyMedium.copyWith(
                                        color: ColorConstants.ink,
                                        height: 1,
                                      ),
                                      decoration: InputDecoration(
                                        isCollapsed: true,
                                        hintText: 'Enter code',
                                        hintStyle:
                                            TextStyleConstants.bodyMedium
                                                .copyWith(
                                          color: ColorConstants.ink.withValues(
                                            alpha: 0.32,
                                          ),
                                          height: 1,
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        disabledBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        focusedErrorBorder: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onTapOutside: (_) =>
                                          _couponFocusNode.unfocus(),
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 18,
                                    color: ColorConstants.line,
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: _verifyingCoupon
                                        ? null
                                        : (_appliedCoupon != null
                                            ? _removeCoupon
                                            : () => _verifyCoupon()),
                                    style: TextButton.styleFrom(
                                      foregroundColor: _appliedCoupon != null
                                          ? ColorConstants.red
                                          : ColorConstants.brandBlue,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      minimumSize: const Size(0, 48),
                                      alignment: Alignment.center,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      textStyle:
                                          TextStyleConstants.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: AppSize.sp(context, 14),
                                        height: 1,
                                      ),
                                    ),
                                    child: _verifyingCoupon
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            _appliedCoupon != null
                                                ? 'Remove'
                                                : 'Apply',
                                            style: TextStyleConstants.bodyMedium
                                                .copyWith(
                                              color: _appliedCoupon != null
                                                  ? ColorConstants.red
                                                  : ColorConstants.brandBlue,
                                              fontWeight: FontWeight.w700,
                                              fontSize: AppSize.sp(context, 14),
                                              height: 1,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_appliedCoupon != null) ...<Widget>[
                            SizedBox(height: AppSize.h(context, 8)),
                            Text(
                              'Applied: $_appliedCoupon',
                              style: TextStyleConstants.caption.copyWith(
                                color: ColorConstants.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (_coupons == null) ...<Widget>[
                            SizedBox(height: AppSize.h(context, 12)),
                            _CouponTile(
                              code: 'WELCOME50',
                              discount: '₹50 off',
                              subtitle: 'New subscribers',
                              onTap: () {
                                _couponController.text = 'WELCOME50';
                                setState(_clearAppliedCoupon);
                              },
                            ),
                            SizedBox(height: AppSize.h(context, 8)),
                            _CouponTile(
                              code: 'FNO10',
                              discount: '10% off',
                              subtitle: 'F&O batches',
                              onTap: () {
                                _couponController.text = 'FNO10';
                                setState(_clearAppliedCoupon);
                              },
                            ),
                          ],
                          _buildAvailableCoupons(context),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: AppSize.symmetric(context, vertical: 12),
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Total',
                                style: TextStyleConstants.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: ColorConstants.mute,
                                ),
                              ),
                            ),
                            Text(
                              totalLabel,
                              style: TextStyleConstants.cardTitle.copyWith(
                                fontSize: AppSize.sp(context, 20),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSize.h(context, 10)),
                        CommonButtonWidget(
                          label: 'Pay $totalLabel',
                          onPressed:
                              _creatingPayment || _loadingPlan
                                  ? null
                                  : _startSubscription,
                        ),
                        SizedBox(height: AppSize.h(context, 8)),
                        Text(
                          'Secured by Razorpay',
                          style: TextStyleConstants.caption.copyWith(
                            fontSize: AppSize.sp(context, 11),
                            color: ColorConstants.soft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_creatingPayment)
            const Positioned.fill(child: AppLoaderOverlay()),
        ],
      ),
    );
  }

  Widget _buildAvailableCoupons(BuildContext context) {
    if (_coupons == null) return const SizedBox.shrink();
    return FutureBuilder<List<AvailableCoupon>>(
      future: _coupons,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final coupons = snapshot.data!
            .where((coupon) => coupon.applicable && coupon.code.isNotEmpty)
            .toList();
        if (coupons.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.only(top: AppSize.h(context, 12)),
          child: Column(
            children: coupons
                .map(
                  (coupon) => Padding(
                    padding: EdgeInsets.only(bottom: AppSize.h(context, 8)),
                    child: _CouponTile(
                      code: coupon.code,
                      discount: coupon.discountLabel,
                      subtitle: coupon.validTo == null
                          ? 'Available now'
                          : 'Limited time offer',
                      onTap: () {
                        _couponController.text = coupon.code;
                        setState(_clearAppliedCoupon);
                        // Apply with listed type/value so flat/% cut is local.
                        unawaited(_verifyCoupon(fromList: coupon));
                      },
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _Kv extends StatelessWidget {
  const _Kv(this.label, this.value, {this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.h(context, 10)),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyleConstants.caption.copyWith(
                fontSize: AppSize.sp(context, 12.5),
                color: ColorConstants.mute,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyleConstants.bodyMedium.copyWith(
              fontSize: AppSize.sp(context, emphasize ? 15 : 13),
              fontWeight: FontWeight.w700,
              color: ColorConstants.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponTile extends StatelessWidget {
  const _CouponTile({
    required this.code,
    required this.discount,
    required this.subtitle,
    required this.onTap,
  });

  final String code;
  final String discount;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorConstants.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
        side: const BorderSide(color: ColorConstants.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
        child: Padding(
          padding: AppSize.insets(context, left: 12, right: 12, top: 12, bottom: 12),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.local_offer_outlined,
                color: ColorConstants.brandBlue,
                size: AppSize.r(context, 20),
              ),
              SizedBox(width: AppSize.w(context, 10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '$code · $discount',
                      style: TextStyleConstants.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ColorConstants.ink,
                        fontSize: AppSize.sp(context, 13),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyleConstants.caption.copyWith(
                        fontSize: AppSize.sp(context, 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
