import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../../core/widgets/common_button_widget.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class KycPage extends StatefulWidget {
  const KycPage({super.key});

  @override
  State<KycPage> createState() => _KycPageState();
}

class _KycPageState extends State<KycPage> {
  final _formKey = GlobalKey<FormState>();
  final _aadhaarCtrl = TextEditingController();
  final _repo = GetIt.instance<AuthRepository>();

  bool _submitting = false;
  bool _success = false;
  String? _error;

  @override
  void dispose() {
    _aadhaarCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_submitting) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await _repo.submitKyc(
        aadhaarNumber: _aadhaarCtrl.text.replaceAll(' ', ''),
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _success = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString().replaceFirst(RegExp(r'^.*Exception:\s*'), '');
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: AppSize.insets(
                    context,
                    left: 16,
                    right: 16,
                    top: 8,
                  ),
                  child: AppBackHeader(title: 'KYC Verification'),
                ),
                Expanded(
                  child: _success ? _SuccessView() : _FormView(
                    formKey: _formKey,
                    aadhaarCtrl: _aadhaarCtrl,
                    submitting: _submitting,
                    error: _error,
                    onSubmit: _submit,
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

// ── Form view ────────────────────────────────────────────────────────────────

class _FormView extends StatelessWidget {
  const _FormView({
    required this.formKey,
    required this.aadhaarCtrl,
    required this.submitting,
    required this.error,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController aadhaarCtrl;
  final bool submitting;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSize.insets(
        context,
        left: 16,
        right: 16,
        top: 24,
        bottom: 32,
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header info card
            Container(
              width: double.infinity,
              padding: AppSize.insets(
                context,
                left: 16,
                right: 16,
                top: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                color: ColorConstants.brandBlue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppSize.r(context, 14)),
                border: Border.all(
                  color: ColorConstants.brandBlue.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.shield_outlined,
                    color: ColorConstants.brandBlue,
                    size: AppSize.r(context, 22),
                  ),
                  SizedBox(width: AppSize.w(context, 10)),
                  Expanded(
                    child: Text(
                      'Your Aadhaar number is used solely for identity '
                      'verification and is never stored on our servers.',
                      style: TextStyleConstants.caption.copyWith(
                        fontSize: AppSize.sp(context, 12),
                        color: ColorConstants.brandBlue,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSize.h(context, 28)),

            Text(
              'Aadhaar number',
              style: TextStyleConstants.caption.copyWith(
                fontSize: AppSize.sp(context, 12),
                fontWeight: FontWeight.w600,
                color: ColorConstants.mute,
              ),
            ),
            SizedBox(height: AppSize.h(context, 8)),
            TextFormField(
              controller: aadhaarCtrl,
              keyboardType: TextInputType.number,
              maxLength: 14, // 12 digits + 2 spaces
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                _AadhaarFormatter(),
              ],
              style: TextStyleConstants.bodyMedium.copyWith(
                fontSize: AppSize.sp(context, 16),
                color: ColorConstants.ink,
                letterSpacing: 1.5,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: 'XXXX XXXX XXXX',
                hintStyle: TextStyleConstants.caption.copyWith(
                  color: ColorConstants.soft,
                  fontSize: AppSize.sp(context, 16),
                  letterSpacing: 1.5,
                ),
                filled: true,
                fillColor: ColorConstants.white,
                contentPadding: AppSize.symmetric(
                  context,
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
                  borderSide: const BorderSide(color: ColorConstants.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
                  borderSide: const BorderSide(color: ColorConstants.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
                  borderSide: const BorderSide(
                    color: ColorConstants.brandBlue,
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
                  borderSide: const BorderSide(color: ColorConstants.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
                  borderSide:
                      const BorderSide(color: ColorConstants.red, width: 1.5),
                ),
              ),
              validator: (v) {
                final digits = (v ?? '').replaceAll(' ', '');
                if (digits.isEmpty) return 'Please enter your Aadhaar number';
                if (digits.length != 12) {
                  return 'Aadhaar number must be exactly 12 digits';
                }
                return null;
              },
            ),

            if (error != null) ...<Widget>[
              SizedBox(height: AppSize.h(context, 16)),
              Container(
                width: double.infinity,
                padding: AppSize.symmetric(
                  context,
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: ColorConstants.red.withValues(alpha: 0.08),
                  borderRadius:
                      BorderRadius.circular(AppSize.r(context, 10)),
                  border: Border.all(
                    color: ColorConstants.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  error!,
                  style: TextStyleConstants.caption.copyWith(
                    color: ColorConstants.red,
                    fontSize: AppSize.sp(context, 12),
                  ),
                ),
              ),
            ],

            SizedBox(height: AppSize.h(context, 32)),
            CommonButtonWidget(
              label: 'Submit KYC',
              isLoading: submitting,
              onPressed: submitting ? null : onSubmit,
              height: AppSize.h(context, 50),
              borderRadius: 14,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Success view ─────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSize.symmetric(context, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: AppSize.r(context, 80),
              height: AppSize.r(context, 80),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ColorConstants.green.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.verified_rounded,
                size: AppSize.r(context, 40),
                color: ColorConstants.green,
              ),
            ),
            SizedBox(height: AppSize.h(context, 20)),
            Text(
              'KYC Submitted',
              style: TextStyleConstants.screenTitle.copyWith(
                fontSize: AppSize.sp(context, 20),
                color: ColorConstants.ink,
              ),
            ),
            SizedBox(height: AppSize.h(context, 10)),
            Text(
              'Your Aadhaar verification has been submitted successfully. '
              'Your account is now active.',
              textAlign: TextAlign.center,
              style: TextStyleConstants.bodyMedium.copyWith(
                fontSize: AppSize.sp(context, 13),
                color: ColorConstants.mute,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppSize.h(context, 32)),
            CommonButtonWidget(
              label: 'Done',
              onPressed: () => Navigator.of(context).pop(true),
              height: AppSize.h(context, 50),
              borderRadius: 14,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Aadhaar formatter — adds a space every 4 digits ──────────────────────────

class _AadhaarFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    if (digits.length > 12) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
