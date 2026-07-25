import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/app_size.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final storage = getIt<SecureStorage>();
    final hasToken = await storage.hasToken;
    if (!mounted) return;
    if (hasToken) {
      try {
        await getIt<AuthRepository>().getMe();
        if (!mounted) return;
        context.go(AppRoutingName.home);
        return;
      } catch (_) {
        await storage.delete(SecureStorage.accessToken);
        await storage.delete(SecureStorage.refreshToken);
      }
    }
    if (!mounted) return;
    context.go(AppRoutingName.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.navy,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyleConstants.displaySmall.copyWith(
                    color: ColorConstants.white,
                    fontSize: AppSize.sp(context, 32),
                  ),
                  children: [
                    const TextSpan(text: 'Sto'),
                    TextSpan(
                      text: 'X',
                      style: TextStyle(
                        color: ColorConstants.brandBlueLight,
                        fontFamily: TextStyleConstants.fontFamilyDisplay,
                        fontWeight: FontWeight.w700,
                        fontSize: AppSize.sp(context, 32),
                      ),
                    ),
                    const TextSpan(text: 'ify'),
                  ],
                ),
              ),
              SizedBox(height: AppSize.h(context, 12)),
              Text(
                StringConstants.brandTagline,
                style: TextStyleConstants.caption.copyWith(
                  color: ColorConstants.soft,
                  fontSize: AppSize.sp(context, 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
