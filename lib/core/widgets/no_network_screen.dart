import 'package:flutter/material.dart';

import '../constants/color_constants.dart';
import '../constants/text_style_constants.dart';
import '../utils/app_size.dart';
import 'app_screen_background.dart';

/// Full-screen overlay shown when the device has no network.
/// Follows the same light brand surface used by Home / Discover / Trades.
/// Dismissed automatically — caller pops it when connectivity returns.
class NoNetworkScreen extends StatefulWidget {
  const NoNetworkScreen({super.key});

  @override
  State<NoNetworkScreen> createState() => _NoNetworkScreenState();
}

class _NoNetworkScreenState extends State<NoNetworkScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const AppScreenBackground(),
          SafeArea(
            child: Center(
              child: Padding(
                padding: AppSize.symmetric(context, horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: AppSize.insets(
                    context,
                    left: 22,
                    right: 22,
                    top: 28,
                    bottom: 28,
                  ),
                  decoration: BoxDecoration(
                    color: ColorConstants.white,
                    borderRadius: BorderRadius.circular(AppSize.r(context, 16)),
                    border: Border.all(color: ColorConstants.line),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color:
                            ColorConstants.shadowSoft.withValues(alpha: 0.06),
                        blurRadius: AppSize.r(context, 16),
                        offset: Offset(0, AppSize.h(context, 6)),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: AppSize.r(context, 72),
                        height: AppSize.r(context, 72),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ColorConstants.liveBg,
                          border: Border.all(
                            color: ColorConstants.brandBlue
                                .withValues(alpha: 0.18),
                          ),
                        ),
                        child: Icon(
                          Icons.wifi_off_rounded,
                          size: AppSize.r(context, 32),
                          color: ColorConstants.brandBlue,
                        ),
                      ),
                      SizedBox(height: AppSize.h(context, 20)),
                      Text(
                        'No Internet Connection',
                        textAlign: TextAlign.center,
                        style: TextStyleConstants.cardTitle.copyWith(
                          fontSize: AppSize.sp(context, 18),
                          color: ColorConstants.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: AppSize.h(context, 8)),
                      Text(
                        'Check your Wi-Fi or mobile data and we\'ll reconnect automatically.',
                        textAlign: TextAlign.center,
                        style: TextStyleConstants.bodyMedium.copyWith(
                          fontSize: AppSize.sp(context, 13.5),
                          color: ColorConstants.mute,
                          height: 1.45,
                        ),
                      ),
                      SizedBox(height: AppSize.h(context, 22)),
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (context, _) => _StatusPill(
                          pulse: _pulseAnim.value,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.pulse});

  final double pulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSize.symmetric(context, horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.r(context, 24)),
        color: ColorConstants.lossBg,
        border: Border.all(
          color: ColorConstants.red.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: AppSize.r(context, 7),
            height: AppSize.r(context, 7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorConstants.red.withValues(alpha: 0.55 + 0.45 * pulse),
            ),
          ),
          SizedBox(width: AppSize.w(context, 8)),
          Text(
            'Waiting for connection…',
            style: TextStyleConstants.caption.copyWith(
              fontSize: AppSize.sp(context, 12),
              color: ColorConstants.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
