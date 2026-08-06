import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/ota/ota_update_service.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../../core/widgets/common_button_widget.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _checkingUpdate = false;
  int? _patchNumber;

  @override
  void initState() {
    super.initState();
    OtaUpdateService.instance.currentPatchNumber().then((n) {
      if (mounted) setState(() => _patchNumber = n);
    });
  }

  Future<void> _onCheckForUpdates() async {
    if (_checkingUpdate) return;
    setState(() => _checkingUpdate = true);
    final messenger = ScaffoldMessenger.of(context);
    final result = await OtaUpdateService.instance.checkAndDownload(
      silent: false,
    );
    if (!mounted) return;
    setState(() => _checkingUpdate = false);

    final String message;
    switch (result) {
      case OtaCheckResult.updateReady:
        message =
            'Update downloaded. Close and reopen StoXify to apply it.';
        break;
      case OtaCheckResult.upToDate:
        message = 'You are on the latest version.';
        break;
      case OtaCheckResult.unavailable:
        message =
            'Updates unavailable in this build. Use a Shorebird release.';
        break;
      case OtaCheckResult.failed:
        message = 'Could not check for updates. Try again later.';
        break;
    }

    messenger.showSnackBar(SnackBar(content: Text(message)));

    final n = await OtaUpdateService.instance.currentPatchNumber();
    if (mounted) setState(() => _patchNumber = n);
  }

  @override
  Widget build(BuildContext context) {
    final patchLabel = _patchNumber == null
        ? 'Check for app fixes over the air'
        : 'OTA patch #$_patchNumber · Tap to check for more';

    return Scaffold(
      backgroundColor: ColorConstants.transparent,
      body: Stack(
        children: <Widget>[
          const AppScreenBackground(),
          SafeArea(
            child: Padding(
              padding: AppSize.insets(context, left: 16, right: 16, top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppBackHeader(
                    title: 'Settings',
                    onBack: () => context.pop(),
                  ),
                  SizedBox(height: AppSize.h(context, 18)),
                  AppMenuListTile(
                    title: 'Notifications',
                    subtitle: 'Push alerts for trades & renewals',
                    onTap: () => context.push(AppRoutingName.notifications),
                  ),
                  SizedBox(height: AppSize.h(context, 10)),
                  AppMenuListTile(
                    title: 'Privacy',
                    subtitle: 'How we use your data',
                    onTap: () {},
                  ),
                  if (!kIsWeb) ...<Widget>[
                    SizedBox(height: AppSize.h(context, 10)),
                    AppMenuListTile(
                      title: _checkingUpdate
                          ? 'Checking for updates…'
                          : 'Check for updates',
                      subtitle: patchLabel,
                      onTap: _checkingUpdate ? () {} : _onCheckForUpdates,
                    ),
                  ],
                  const Spacer(),
                  CommonButtonWidget(
                    label: 'Sign out',
                    backgroundColor: ColorConstants.white,
                    foregroundColor: ColorConstants.red,
                    borderColor: ColorConstants.red.withValues(alpha: 0.35),
                    onPressed: () => context.go(AppRoutingName.login),
                  ),
                  SizedBox(height: AppSize.h(context, 16)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
