import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../../core/widgets/common_button_widget.dart';

class SubscriptionsPage extends StatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  State<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends State<SubscriptionsPage> {
  final TextEditingController _couponController = TextEditingController();
  String? _appliedCoupon;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
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
                            child: Column(
                              children: const <Widget>[
                                _Kv('Batch', 'FNO Batch'),
                                _Kv('Plan', 'Monthly'),
                                _Kv('Duration', '30 days'),
                                _Kv('Price', '₹99', emphasize: true),
                              ],
                            ),
                          ),
                          SizedBox(height: AppSize.h(context, 14)),
                          const AppSectionLabel('Coupon'),
                          SizedBox(height: AppSize.h(context, 8)),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Material(
                                  color: ColorConstants.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSize.r(context, 12),
                                    ),
                                    side: const BorderSide(
                                      color: ColorConstants.line,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: AppSize.symmetric(
                                      context,
                                      horizontal: 12,
                                    ),
                                    child: TextField(
                                      controller: _couponController,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Enter code',
                                        hintStyle:
                                            TextStyleConstants.body.copyWith(
                                          color: ColorConstants.soft,
                                          fontSize: AppSize.sp(context, 13),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: AppSize.w(context, 8)),
                              CommonButtonWidget(
                                label: 'Apply',
                                width: null,
                                height: 44,
                                borderRadius: 10,
                                horizontalPadding: 16,
                                onPressed: () {
                                  setState(() {
                                    _appliedCoupon =
                                        _couponController.text.trim().isEmpty
                                            ? null
                                            : _couponController.text.trim();
                                  });
                                },
                              ),
                            ],
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
                          SizedBox(height: AppSize.h(context, 12)),
                          _CouponTile(
                            code: 'WELCOME50',
                            discount: '₹50 off',
                            subtitle: 'New subscribers',
                            onTap: () {
                              _couponController.text = 'WELCOME50';
                              setState(() => _appliedCoupon = 'WELCOME50');
                            },
                          ),
                          SizedBox(height: AppSize.h(context, 8)),
                          _CouponTile(
                            code: 'FNO10',
                            discount: '10% off',
                            subtitle: 'F&O batches',
                            onTap: () {
                              _couponController.text = 'FNO10';
                              setState(() => _appliedCoupon = 'FNO10');
                            },
                          ),
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
                              '₹99',
                              style: TextStyleConstants.cardTitle.copyWith(
                                fontSize: AppSize.sp(context, 20),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSize.h(context, 10)),
                        CommonButtonWidget(
                          label: 'Pay ₹99',
                          onPressed: () =>
                              context.go(AppRoutingName.paymentSuccess),
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
        ],
      ),
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
