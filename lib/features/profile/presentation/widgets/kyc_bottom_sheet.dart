import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/common_app_notification_bar.dart';
import '../../../../core/widgets/common_button_widget.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class KycBottomSheet extends StatefulWidget {
  const KycBottomSheet({
    super.key,
    this.isVerified = false,
  });

  final bool isVerified;

  @override
  State<KycBottomSheet> createState() => _KycBottomSheetState();
}

class _KycBottomSheetState extends State<KycBottomSheet> {
  final TextEditingController _aadhaarController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    if (widget.isVerified) {
      _aadhaarController.text = '•••• •••• ••••';
    }
  }

  void _onFocusChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _aadhaarController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitKyc() async {
    if (widget.isVerified) return;

    final rawDigits = _aadhaarController.text.replaceAll(RegExp(r'\D'), '');
    if (rawDigits.isEmpty) {
      setState(() => _error = 'Aadhaar number is required');
      return;
    }
    if (rawDigits.length != 12) {
      setState(() => _error = 'Please enter a valid 12-digit Aadhaar number');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final state = await GetIt.instance<AuthRepository>().submitKyc(
        aadhaarNumber: rawDigits,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);

      CommonAppNotificationBar.success(
        context: context,
        title: 'KYC Submitted',
        message: 'Your account is now $state',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVerified = widget.isVerified;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSize.r(context, 22)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Drag handle
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

            // Header row
            Padding(
              padding: AppSize.insets(
                context,
                left: 18,
                right: 10,
                top: 12,
                bottom: 8,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      isVerified ? 'KYC Verification' : 'Complete KYC',
                      style: TextStyleConstants.screenTitle.copyWith(
                        fontSize: AppSize.sp(context, 19),
                      ),
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

            Padding(
              padding: AppSize.insets(
                context,
                left: 20,
                right: 20,
                top: 20,
                bottom: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (isVerified) ...[
                    Container(
                      padding: AppSize.insets(
                        context,
                        left: 14,
                        right: 14,
                        top: 12,
                        bottom: 12,
                      ),
                      decoration: BoxDecoration(
                        color: ColorConstants.pillSuccessBg,
                        borderRadius: BorderRadius.circular(
                          AppSize.r(context, 12),
                        ),
                        border: Border.all(color: ColorConstants.profitBgStrong),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            color: ColorConstants.green,
                            size: AppSize.r(context, 20),
                          ),
                          SizedBox(width: AppSize.w(context, 10)),
                          Expanded(
                            child: Text(
                              'Your Aadhaar KYC is verified and active.',
                              style: TextStyleConstants.bodyMedium.copyWith(
                                color: ColorConstants.green,
                                fontWeight: FontWeight.w600,
                                fontSize: AppSize.sp(context, 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppSize.h(context, 18)),
                  ] else ...[
                    Text(
                      'Enter your 12-digit Aadhaar number to verify your identity and activate your account.',
                      style: TextStyleConstants.bodyMedium.copyWith(
                        color: ColorConstants.mute,
                        fontSize: AppSize.sp(context, 14),
                      ),
                    ),
                    SizedBox(height: AppSize.h(context, 20)),
                  ],

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 48,
                    decoration: BoxDecoration(
                      color: isVerified
                          ? ColorConstants.gray50
                          : ColorConstants.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isVerified
                            ? ColorConstants.green.withValues(alpha: 0.4)
                            : _error != null
                                ? ColorConstants.red
                                : _focusNode.hasFocus
                                    ? ColorConstants.brandBlue
                                    : ColorConstants.line,
                        width: isVerified
                            ? 1.5
                            : _focusNode.hasFocus
                                ? 1.5
                                : 1,
                      ),
                      boxShadow: isVerified
                          ? []
                          : [
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            isVerified
                                ? Icons.verified_user_rounded
                                : Icons.badge_outlined,
                            size: 20,
                            color: isVerified
                                ? ColorConstants.green
                                : _focusNode.hasFocus
                                    ? ColorConstants.brandBlue
                                    : ColorConstants.mute,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 18,
                            color: isVerified
                                ? ColorConstants.green.withValues(alpha: 0.3)
                                : ColorConstants.navy.withValues(
                                    alpha: 0.7,
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _aadhaarController,
                              focusNode: _focusNode,
                              enabled: !isVerified,
                              readOnly: isVerified,
                              keyboardType: TextInputType.number,
                              cursorColor: ColorConstants.brandBlue,
                              cursorWidth: 2,
                              cursorHeight: 18,
                              minLines: null,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.center,
                              style: TextStyleConstants.bodyMedium.copyWith(
                                color: isVerified
                                    ? ColorConstants.green
                                    : ColorConstants.ink,
                                fontWeight: isVerified
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                height: 1,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                _AadhaarNumberFormatter(),
                              ],
                              decoration: InputDecoration(
                                isCollapsed: true,
                                hintText: '8548 5864 9201',
                                hintStyle: TextStyleConstants.bodyMedium.copyWith(
                                  color: ColorConstants.ink.withValues(alpha: 0.32),
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
                              onChanged: (_) {
                                if (_error != null) setState(() => _error = null);
                              },
                              onTapOutside: (_) => _focusNode.unfocus(),
                              onFieldSubmitted: (_) => _submitKyc(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_error != null) ...[
                    SizedBox(height: AppSize.h(context, 6)),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        _error!,
                        style: TextStyleConstants.caption.copyWith(
                          color: ColorConstants.red,
                          fontSize: AppSize.sp(context, 12),
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: AppSize.h(context, 24)),

                  if (isVerified)
                    CommonButtonWidget(
                      label: 'KYC Verified',
                      onPressed: null,
                      backgroundColor: ColorConstants.green,
                      disabledBackgroundColor: ColorConstants.green,
                      disabledForegroundColor: ColorConstants.white,
                      leading: const Icon(
                        Icons.check_circle_rounded,
                        color: ColorConstants.white,
                        size: 20,
                      ),
                    )
                  else
                    CommonButtonWidget(
                      label: 'Submit KYC',
                      isLoading: _isLoading,
                      onPressed: _submitKyc,
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

class _AadhaarNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limitedDigits =
        digitsOnly.length > 12 ? digitsOnly.substring(0, 12) : digitsOnly;

    final buffer = StringBuffer();
    for (int i = 0; i < limitedDigits.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(limitedDigits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
