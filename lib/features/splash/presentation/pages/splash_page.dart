import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/asset_constants.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';

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
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    context.go(AppRoutingName.home);
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
                  ),
                  children: const [
                    TextSpan(text: 'Sto'),
                    TextSpan(
                      text: 'X',
                      style: TextStyle(
                        color: ColorConstants.brandBlueLight,
                        fontFamily: TextStyleConstants.fontFamilyDisplay,
                        fontWeight: FontWeight.w700,
                        fontSize: 32,
                      ),
                    ),
                    TextSpan(text: 'ify'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'SEBI-registered research marketplace',
                style: TextStyleConstants.caption.copyWith(
                  color: ColorConstants.soft,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 120,
                height: 120,
                child: Lottie.asset(
                  AssetConstants.tradingLoader,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
