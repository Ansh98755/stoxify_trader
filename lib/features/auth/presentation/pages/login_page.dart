import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/notifications/notification_navigator.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/common_app_notification_bar.dart';
import '../../../../core/widgets/common_button_widget.dart';
import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';
import '../widgets/otp_entry_dialog.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LoginBloc>(
      create: (_) => getIt<LoginBloc>(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  bool _isOtpFlowActive = false;

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _phoneFocusNode.removeListener(_onFocusChanged);
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: <BlocListener<LoginBloc, LoginState>>[
        BlocListener<LoginBloc, LoginState>(
          listenWhen: (previous, current) =>
              previous.otpSentCount != current.otpSentCount,
          listener: (BuildContext context, LoginState state) async {
            if (_isOtpFlowActive) return;
            _isOtpFlowActive = true;
            try {
              _phoneFocusNode.unfocus();
              final otp = await showOtpEntryDialog(
                context: context,
                phoneNumber: state.phoneNumber,
                onResend: () {
                  context.read<LoginBloc>().add(
                        const LoginOtpResendRequested(),
                      );
                },
              );

              if (!context.mounted) return;
              if (otp != null && otp.length == 6) {
                context.read<LoginBloc>().add(LoginOtpSubmitted(otp));
              } else {
                // Cross / dismiss — always leave loading & OTP-active cleanly.
                context.read<LoginBloc>().add(const LoginOtpEntryClosed());
              }
            } catch (_) {
              if (context.mounted) {
                context.read<LoginBloc>().add(const LoginOtpEntryClosed());
              }
            } finally {
              _isOtpFlowActive = false;
            }
          },
        ),
        BlocListener<LoginBloc, LoginState>(
          listenWhen: (previous, current) =>
              previous.verifySuccessCount != current.verifySuccessCount,
          listener: (BuildContext context, LoginState state) {
            if (state.isNewUser) {
              context.go(AppRoutingName.interest);
            } else {
              context.go(AppRoutingName.home);
              NotificationNavigator.flushPendingAfterFrame();
            }
          },
        ),
        BlocListener<LoginBloc, LoginState>(
          listenWhen: (previous, current) =>
              current.errorMessage != null &&
              previous.errorMessage != current.errorMessage,
          listener: (BuildContext context, LoginState state) {
            final message = state.errorMessage;
            if (message == null) return;
            CommonAppNotificationBar.error(
              context: context,
              title: 'Error',
              message: message,
            );
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: ColorConstants.loginBackground,
        body: Stack(
          children: <Widget>[
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: AppSize.maxContentWidth(context),
                  ),
                  child: Padding(
                    padding: AppSize.insets(
                      context,
                      left: 20,
                      top: 12,
                      right: 20,
                      bottom: 22,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _LoginHero(),
                        SizedBox(height: AppSize.h(context, 28)),
                        Text(
                          'Welcome back !!!',
                          style: TextStyleConstants.screenTitleLarge.copyWith(
                            fontSize: AppSize.sp(context, 28),
                          ),
                        ),
                        SizedBox(height: AppSize.h(context, 16)),
                        BlocBuilder<LoginBloc, LoginState>(
                          buildWhen: (previous, current) =>
                              previous.phoneNumber != current.phoneNumber,
                          builder: (BuildContext context, LoginState state) {
                            return _PhoneInputField(
                              focused: _phoneFocusNode.hasFocus,
                              controller: _phoneController,
                              focusNode: _phoneFocusNode,
                              onChanged: (String value) {
                                context.read<LoginBloc>().add(
                                      LoginPhoneChanged(value),
                                    );
                              },
                              onSubmitted: () {
                                if (state.isPhoneValid &&
                                    !state.isSubmitting) {
                                  context.read<LoginBloc>().add(
                                        const LoginSubmitted(),
                                      );
                                }
                              },
                            );
                          },
                        ),
                        const Spacer(),
                        BlocBuilder<LoginBloc, LoginState>(
                          buildWhen: (previous, current) =>
                              previous.isPhoneValid != current.isPhoneValid ||
                              previous.isSubmitting != current.isSubmitting,
                          builder: (BuildContext context, LoginState state) {
                            return CommonButtonWidget(
                              label: 'Login',
                              onPressed: state.isPhoneValid && !state.isSubmitting
                                  ? () {
                                      context.read<LoginBloc>().add(
                                        const LoginSubmitted(),
                                      );
                                    }
                                  : null,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Full-screen loader overlay ──────────────────────────────────
            // Only while a network call is in flight (send OTP / verify OTP).
            // Do NOT gate on isOtpEntryActive — that left a stuck spinner when
            // the OTP dialog was dismissed (buildWhen only watched isSubmitting).
            BlocBuilder<LoginBloc, LoginState>(
              buildWhen: (previous, current) =>
                  previous.isSubmitting != current.isSubmitting,
              builder: (BuildContext context, LoginState state) {
                if (!state.isSubmitting) {
                  return const SizedBox.shrink();
                }
                return const Positioned.fill(
                  child: AppLoaderOverlay(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top:12),
      child: Container(
        width: double.infinity,
        // height: AppSize.h(context, 140),
        padding: AppSize.insets(
          context,
          left: 20,
          top: 28,
          right: 20,
          bottom: 20,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
        ),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Center(
                child: RichText(
                  text: TextSpan(
                    style: TextStyleConstants.cardTitleLarge.copyWith(
                      color: ColorConstants.navy,
                      fontSize: AppSize.sp(context, 38),
                      fontWeight: FontWeight(800)
                    ),
                    children: const <InlineSpan>[
                      TextSpan(text: 'Sto'),
                      TextSpan(
                        text: 'X',
                        style: TextStyle(color: ColorConstants.brandBlueLight),
                      ),
                      TextSpan(text: 'ify'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSize.h(context, 8)),
              Center(
                child: Text(
                  StringConstants.brandTagline,
                  style: TextStyleConstants.caption.copyWith(
                    color: const Color(0xFFA9B7D0),
                    fontSize: AppSize.sp(context, 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Phone input — one layout for Android, iOS, and Flutter web.
class _PhoneInputField extends StatelessWidget {
  const _PhoneInputField({
    required this.focused,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
  });

  final bool focused;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  static const double _height = 48;
  static const double _fontSize = 14;

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = TextStyleConstants.bodyMedium.copyWith(
      color: ColorConstants.ink,
      fontWeight: FontWeight.w500,
      fontSize: _fontSize,
      height: 1.15,
      leadingDistribution: TextLeadingDistribution.even,
      textBaseline: TextBaseline.alphabetic,
    );
    final TextStyle hintStyle = textStyle.copyWith(
      color: ColorConstants.ink.withValues(alpha: 0.32),
    );
    const StrutStyle strut = StrutStyle(
      fontSize: _fontSize,
      height: 1.15,
      forceStrutHeight: true,
      leadingDistribution: TextLeadingDistribution.even,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: _height,
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: focused ? ColorConstants.brandBlue : ColorConstants.line,
          width: focused ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.navy.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Align(
              alignment: Alignment.center,
              child: Text(
                '+91',
                style: textStyle.copyWith(fontWeight: FontWeight.w600),
                strutStyle: strut,
              ),
            ),
            const SizedBox(width: 6),
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 1,
                height: 14,
                color: ColorConstants.navy.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  height: 22,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: TextInputType.phone,
                    maxLines: 1,
                    style: textStyle,
                    strutStyle: strut,
                    textAlignVertical: TextAlignVertical.center,
                    cursorColor: ColorConstants.brandBlue,
                    cursorWidth: 2,
                    cursorHeight: 18,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: InputDecoration(
                      hintText: '98765 43210',
                      hintStyle: hintStyle,
                      isDense: true,
                      isCollapsed: true,
                      filled: false,
                      fillColor: ColorConstants.transparent,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                    ),
                    onChanged: onChanged,
                    onSubmitted: (_) => onSubmitted(),
                    onTapOutside: (_) => focusNode.unfocus(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


