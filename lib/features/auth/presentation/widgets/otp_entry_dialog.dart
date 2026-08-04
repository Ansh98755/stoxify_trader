import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/common_app_notification_bar.dart';
import '../../../../core/widgets/common_button_widget.dart';

Future<String?> showOtpEntryDialog({
  required BuildContext context,
  required String phoneNumber,
  VoidCallback? onResend,
  String title = 'Enter verification code',
  String confirmLabel = 'Verify OTP',
}) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Dismiss OTP dialog',
    barrierColor: ColorConstants.navy.withValues(alpha: 0.58),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _OtpEntryDialog(
        phoneNumber: phoneNumber,
        onResend: onResend,
        title: title,
        confirmLabel: confirmLabel,
      );
    },
    transitionBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInCubic,
          );

          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.88,
                end: 1,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
  );
}

class _OtpEntryDialog extends StatefulWidget {
  const _OtpEntryDialog({
    required this.phoneNumber,
    this.onResend,
    required this.title,
    required this.confirmLabel,
  });

  final String phoneNumber;
  final VoidCallback? onResend;
  final String title;
  final String confirmLabel;

  @override
  State<_OtpEntryDialog> createState() => _OtpEntryDialogState();
}

class _OtpEntryDialogState extends State<_OtpEntryDialog> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  Timer? _resendTimer;
  int _remainingSeconds = 0;

  String get _otp => _otpController.text;
  bool get _isComplete => _otp.length == 6;
  bool get _isResendTimerActive => _remainingSeconds > 0;

  String get _formattedRemainingTime {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _remainingSeconds = 120);

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        return;
      }

      setState(() => _remainingSeconds--);
    });
  }

  String get _maskedPhoneNumber {
    if (widget.phoneNumber.contains('•')) return widget.phoneNumber;
    if (widget.phoneNumber.length != 10) return '+91 ${widget.phoneNumber}';
    return '+91 ${widget.phoneNumber.substring(0, 5)} '
        '${widget.phoneNumber.substring(5)}';
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: Center(
          child: Material(
            color: ColorConstants.transparent,
            child: Container(
              width: AppSize.w(context, 350),
              constraints: BoxConstraints(
                maxWidth: AppSize.screenWidth(context) - AppSize.w(context, 32),
              ),
              padding: AppSize.insets(
                context,
                left: 20,
                top: 18,
                right: 20,
                bottom: 20,
              ),
              decoration: BoxDecoration(
                color: ColorConstants.white,
                borderRadius: BorderRadius.circular(AppSize.r(context, 22)),
                border: Border.all(color: ColorConstants.line),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: ColorConstants.navy.withValues(alpha: 0.22),
                    blurRadius: AppSize.r(context, 32),
                    offset: Offset(0, AppSize.h(context, 14)),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: ColorConstants.mute,
                        tooltip: 'Close',
                      ),
                    ),
                    Container(
                      width: AppSize.r(context, 58),
                      height: AppSize.r(context, 58),
                      decoration: const BoxDecoration(
                        color: ColorConstants.profitBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        color: ColorConstants.green,
                        size: AppSize.r(context, 28),
                      ),
                    ),
                    SizedBox(height: AppSize.h(context, 16)),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: TextStyleConstants.sectionHeader.copyWith(
                        fontSize: AppSize.sp(context, 20),
                      ),
                    ),
                    SizedBox(height: AppSize.h(context, 7)),
                    Text(
                      'Enter the 6-digit OTP sent to $_maskedPhoneNumber',
                      textAlign: TextAlign.center,
                      style: TextStyleConstants.bodyMedium.copyWith(
                        fontSize: AppSize.sp(context, 13),
                      ),
                    ),
                    SizedBox(height: AppSize.h(context, 24)),
                    SizedBox(
                      height: AppSize.h(context, 54),
                      child: Stack(
                        children: <Widget>[
                          Positioned.fill(
                            child: TextField(
                              controller: _otpController,
                              focusNode: _otpFocusNode,
                              autofocus: true,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              showCursor: false,
                              enableSuggestions: false,
                              autocorrect: false,
                              maxLength: 6,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              style: const TextStyle(
                                color: ColorConstants.transparent,
                              ),
                              decoration: const InputDecoration(
                                counterText: '',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onTapOutside: (_) => _otpFocusNode.unfocus(),
                              onChanged: (_) {
                                setState(() {});
                                if (_isComplete) {
                                  _otpFocusNode.unfocus();
                                }
                              },
                              onSubmitted: (_) {
                                if (_isComplete) {
                                  Navigator.of(context).pop(_otp);
                                }
                              },
                            ),
                          ),
                          IgnorePointer(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List<Widget>.generate(6, (int index) {
                                final hasDigit = index < _otp.length;
                                final isActive =
                                    index == _otp.length && !_isComplete;

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  width: AppSize.w(context, 40),
                                  height: AppSize.h(context, 52),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: hasDigit
                                        ? ColorConstants.profitBg
                                        : ColorConstants.gray50,
                                    borderRadius: BorderRadius.circular(
                                      AppSize.r(context, 12),
                                    ),
                                    border: Border.all(
                                      color: hasDigit
                                          ? ColorConstants.green
                                          : isActive
                                          ? ColorConstants.brandBlue
                                          : ColorConstants.line,
                                      width: isActive || hasDigit ? 1.5 : 1,
                                    ),
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 140),
                                    transitionBuilder: (child, animation) {
                                      return ScaleTransition(
                                        scale: animation,
                                        child: child,
                                      );
                                    },
                                    child: Text(
                                      hasDigit ? _otp[index] : '',
                                      key: ValueKey<String>(
                                        hasDigit ? _otp[index] : 'empty-$index',
                                      ),
                                      style: TextStyleConstants.numericLarge
                                          .copyWith(
                                            color: ColorConstants.ink,
                                            fontSize: AppSize.sp(context, 18),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppSize.h(context, 24)),
                    CommonButtonWidget(
                      label: widget.confirmLabel,
                      onPressed: _isComplete
                          ? () => Navigator.of(context).pop(_otp)
                          : null,
                    ),
                    SizedBox(height: AppSize.h(context, 10)),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _isResendTimerActive
                          ? Padding(
                              key: const ValueKey<String>('resend-timer'),
                              padding: AppSize.symmetric(context, vertical: 12),
                              child: Text(
                                'Resend OTP in $_formattedRemainingTime',
                                style: TextStyleConstants.bodyMedium.copyWith(
                                  color: ColorConstants.mute,
                                  fontSize: AppSize.sp(context, 13),
                                ),
                              ),
                            )
                          : TextButton(
                              key: const ValueKey<String>('resend-button'),
                              onPressed: () {
                                widget.onResend?.call();
                                _otpController.clear();
                                _startResendTimer();
                                _otpFocusNode.requestFocus();
                                CommonAppNotificationBar.info(
                                  context: context,
                                  title: 'OTP resent',
                                  message:
                                      'A fresh 6-digit code has been sent.',
                                );
                              },
                              child: const Text('Resend OTP'),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
