import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/common_button_widget.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key, this.phoneNumber = ''});

  final String phoneNumber;

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  static const int _length = 6;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _controllers = List<TextEditingController>.generate(
      _length,
      (_) => TextEditingController(),
    );
    _nodes = List<FocusNode>.generate(_length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onChanged(int index, String value) {
    if (value.length == 1 && index < _length - 1) {
      _nodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final phone = widget.phoneNumber.isEmpty
        ? '+91 ••••••••••'
        : '+91 ${widget.phoneNumber}';

    return Scaffold(
      backgroundColor: ColorConstants.pageBackground,
      body: SafeArea(
        child: Padding(
          padding: AppSize.insets(context, left: 20, right: 20, top: 16, bottom: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: AppSize.r(context, 48),
                height: AppSize.r(context, 48),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[
                      ColorConstants.brandBlue,
                      ColorConstants.brandBlueLight,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSize.r(context, 14)),
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  color: ColorConstants.white,
                  size: AppSize.r(context, 26),
                ),
              ),
              SizedBox(height: AppSize.h(context, 20)),
              Text(
                'Enter the 6-digit code',
                style: TextStyleConstants.screenTitle.copyWith(
                  fontSize: AppSize.sp(context, 24),
                ),
              ),
              SizedBox(height: AppSize.h(context, 8)),
              Text(
                'We sent a verification code to $phone',
                style: TextStyleConstants.bodyMedium.copyWith(
                  fontSize: AppSize.sp(context, 13.5),
                  color: ColorConstants.mute,
                ),
              ),
              SizedBox(height: AppSize.h(context, 28)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List<Widget>.generate(_length, (int i) {
                  return SizedBox(
                    width: AppSize.w(context, 46),
                    height: AppSize.h(context, 54),
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _nodes[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: TextStyleConstants.cardTitle.copyWith(
                        fontSize: AppSize.sp(context, 20),
                      ),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: ColorConstants.white,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSize.r(context, 12)),
                          borderSide: const BorderSide(color: ColorConstants.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSize.r(context, 12)),
                          borderSide: const BorderSide(
                            color: ColorConstants.brandBlue,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (String v) => _onChanged(i, v),
                    ),
                  );
                }),
              ),
              SizedBox(height: AppSize.h(context, 16)),
              Text(
                'Resend code in 0:28',
                style: TextStyleConstants.caption.copyWith(
                  fontSize: AppSize.sp(context, 12),
                  color: ColorConstants.mute,
                ),
              ),
              const Spacer(),
              CommonButtonWidget(
                label: 'Verify & Continue',
                onPressed: _code.length == _length
                    ? () => context.go(AppRoutingName.interest)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
