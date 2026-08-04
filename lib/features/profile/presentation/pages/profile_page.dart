import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routing.dart';
import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/utils/main_tab_navigation.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/common_app_notification_bar.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../../core/widgets/bottom_navbar.dart';
import '../../../../core/widgets/web_side_drawer.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/widgets/otp_entry_dialog.dart';
import '../../../discover/domain/repositories/discover_repository.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../notifications/domain/repositories/notifications_repository.dart';
import '../widgets/kyc_bottom_sheet.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<AuthUser> _profileFuture;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    _profileFuture = GetIt.instance<AuthRepository>().getMe();
  }

  void _retry() {
    setState(_loadProfile);
  }

  Future<void> _showPersonalInfo() async {
    try {
      final user = await _profileFuture;
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: ColorConstants.transparent,
        builder: (context) => _PersonalInfoSheet(user: user),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load profile information')),
      );
    }
  }

  Future<void> _openEditProfile() async {
    try {
      final user = await _profileFuture;
      if (!mounted) return;
      final updated = await context.push<AuthUser>(
        AppRoutingName.editProfile,
        extra: AuthUserExtra(user),
      );
      if (updated != null && mounted) {
        // Re-fetch from the API so the header shows all fields correctly
        // (the PATCH response may not include every field like phone).
        setState(_loadProfile);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open profile editor')),
      );
    }
  }

  Future<void> _openKyc([AuthUser? user]) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorConstants.transparent,
      builder: (context) => KycBottomSheet(
        isVerified: user?.aadhaarVerified ?? false,
      ),
    );
    if (result == true && mounted) {
      setState(_loadProfile);
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to use StoXify.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loggingOut = true);
    // Clear all in-memory caches before logout so the next user
    // session starts completely fresh.
    GetIt.instance<HomeRepository>().clearAll();
    GetIt.instance<DiscoverRepository>().clearAll();
    GetIt.instance<NotificationsRepository>().clearAll();
    await GetIt.instance<HomeBloc>().resetForLogout();
    await GetIt.instance<AuthRepository>().logout();
    if (!mounted) return;
    context.go(AppRoutingName.login);
  }

  Future<void> _deleteAccount() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (reason == null || !mounted) return;

    final auth = GetIt.instance<AuthRepository>();
    String maskedPhone;
    try {
      maskedPhone = await auth.requestAccountDeletionOtp();
    } catch (_) {
      if (!mounted) return;
      await CommonAppNotificationBar.error(
        context: context,
        title: 'Could not send OTP',
        message: 'Please try requesting account deletion again.',
      );
      return;
    }
    if (!mounted) return;

    final otp = await showOtpEntryDialog(
      context: context,
      phoneNumber: maskedPhone,
      title: 'Confirm account deletion',
      confirmLabel: 'Confirm deletion',
    );
    if (otp == null || !mounted) return;

    try {
      final scheduledAt = await auth.deleteAccount(otp: otp, reason: reason);
      if (!mounted) return;
      final schedule = scheduledAt == null
          ? 'Your account is scheduled for deletion.'
          : 'Deletion is scheduled for ${scheduledAt.day.toString().padLeft(2, '0')}/'
              '${scheduledAt.month.toString().padLeft(2, '0')}/${scheduledAt.year}.';
      await CommonAppNotificationBar.success(
        context: context,
        title: 'Deletion requested',
        message: schedule,
        duration: const Duration(seconds: 2),
      );
      if (!mounted) return;
      GetIt.instance<HomeRepository>().clearAll();
      GetIt.instance<DiscoverRepository>().clearAll();
      GetIt.instance<NotificationsRepository>().clearAll();
      await GetIt.instance<HomeBloc>().resetForLogout();
      await auth.logout();
      if (mounted) context.go(AppRoutingName.login);
    } catch (_) {
      if (!mounted) return;
      await CommonAppNotificationBar.error(
        context: context,
        title: 'Deletion not confirmed',
        message: 'The OTP is invalid or has expired. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = isDesktopWeb(context);

    final scaffold = Scaffold(
      extendBody: !isWeb,
      backgroundColor: ColorConstants.transparent,
      body: Stack(
        children: <Widget>[
          const AppScreenBackground(),
          SafeArea(
            bottom: !isWeb,
            child: Padding(
              padding: isWeb
                  ? const EdgeInsets.fromLTRB(24, 16, 24, 0)
                  : AppSize.insets(context, left: 16, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Profile',
                    style: TextStyleConstants.screenTitle.copyWith(
                      fontSize: isWeb ? 22 : AppSize.sp(context, 22),
                    ),
                  ),
                  SizedBox(height: isWeb ? 14 : AppSize.h(context, 14)),
                  FutureBuilder<AuthUser>(
                    future: _profileFuture,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _ProfileErrorCard(onRetry: _retry);
                      }
                      return _ProfileHeaderCard(
                        user: snapshot.data,
                        onEditTap: snapshot.data != null ? _openEditProfile : null,
                      );
                    },
                  ),
                  SizedBox(height: isWeb ? 16 : AppSize.h(context, 16)),
                  Expanded(
                    child: ListView(
                      children: <Widget>[
                        AppMenuListTile(
                          title: 'Personal info',
                          subtitle: 'Account, KYC & activity details',
                          leading: _icon(Icons.person_outline_rounded),
                          onTap: _showPersonalInfo,
                        ),
                        SizedBox(height: isWeb ? 10 : AppSize.h(context, 10)),
                        AppMenuListTile(
                          title: 'Trading preferences',
                          subtitle: 'Segments you follow',
                          leading: _icon(Icons.tune_rounded),
                          onTap: () => context.push(AppRoutingName.interest),
                        ),
                        SizedBox(height: isWeb ? 10 : AppSize.h(context, 10)),
                        AppMenuListTile(
                          title: 'My subscriptions',
                          subtitle: 'Manage active plans',
                          leading: _icon(Icons.subscriptions_outlined),
                          onTap: () =>
                              context.push(AppRoutingName.mySubscriptions),
                        ),
                        SizedBox(height: isWeb ? 10 : AppSize.h(context, 10)),
                        AppMenuListTile(
                          title: 'Payment history',
                          subtitle: 'View completed and failed payments',
                          leading: _icon(Icons.receipt_long_outlined),
                          onTap: () =>
                              context.push(AppRoutingName.paymentHistory),
                        ),
                        SizedBox(height: isWeb ? 10 : AppSize.h(context, 10)),
                        AppMenuListTile(
                          title: 'Saved trades',
                          subtitle: 'Trades you bookmarked',
                          leading: _icon(Icons.bookmark_outline_rounded),
                          onTap: () =>
                              context.push(AppRoutingName.savedTrades),
                        ),
                        SizedBox(height: isWeb ? 10 : AppSize.h(context, 10)),
                        AppMenuListTile(
                          title: 'Notifications',
                          subtitle: 'Trade alerts & renewals',
                          leading: _icon(Icons.notifications_none_rounded),
                          onTap: () =>
                              context.push(AppRoutingName.notifications),
                        ),
                        SizedBox(height: isWeb ? 10 : AppSize.h(context, 10)),
                        FutureBuilder<AuthUser>(
                          future: _profileFuture,
                          builder: (context, snapshot) {
                            final isVerified =
                                snapshot.data?.aadhaarVerified ?? false;
                            return Column(
                              children: [
                                AppMenuListTile(
                                  title: isVerified
                                      ? 'KYC Verification'
                                      : 'Complete KYC',
                                  subtitle: isVerified
                                      ? 'KYC Verified'
                                      : 'Verify your Aadhaar',
                                  leading: _icon(
                                    isVerified
                                        ? Icons.verified_user_rounded
                                        : Icons.verified_user_outlined,
                                    color: isVerified
                                        ? ColorConstants.green
                                        : ColorConstants.brandBlue,
                                  ),
                                  onTap: () => _openKyc(snapshot.data),
                                ),
                                SizedBox(
                                    height: isWeb
                                        ? 10
                                        : AppSize.h(context, 10)),
                              ],
                            );
                          },
                        ),
                        AppMenuListTile(
                          title: 'Settings',
                          subtitle: 'Privacy & account',
                          leading: _icon(Icons.settings_outlined),
                          onTap: () => context.push(AppRoutingName.settings),
                        ),
                        SizedBox(height: isWeb ? 10 : AppSize.h(context, 10)),
                        AppMenuListTile(
                          title: _loggingOut ? 'Logging out...' : 'Log out',
                          subtitle: 'Sign out of this device',
                          leading: _loggingOut
                              ? SizedBox(
                                  width: AppSize.r(context, 36),
                                  height: AppSize.r(context, 36),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : _icon(
                                  Icons.logout_rounded,
                                  color: ColorConstants.red,
                                ),
                          destructive: true,
                          onTap: _logout,
                        ),
                        SizedBox(height: isWeb ? 10 : AppSize.h(context, 10)),
                        AppMenuListTile(
                          title: 'Delete account',
                          leading: _icon(
                            Icons.delete_outline_rounded,
                            color: ColorConstants.red,
                          ),
                          destructive: true,
                          onTap: _deleteAccount,
                        ),
                        SizedBox(height: isWeb ? 24 : AppSize.h(context, 88)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isWeb)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNavbar(
                currentIndex: 3,
                onItemSelected: (int index) {
                  if (index == 3) return;
                  navigateMainTab(context, index);
                },
              ),
            ),
        ],
      ),
    );

    if (isWeb) {
      return WebSideDrawer(currentIndex: 3, child: scaffold);
    }
    return scaffold;
  }

  static Widget _icon(IconData icon, {Color color = ColorConstants.brandBlue}) {
    return Builder(
      builder: (BuildContext context) {
        return Container(
          width: AppSize.r(context, 36),
          height: AppSize.r(context, 36),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSize.r(context, 10)),
          ),
          child: Icon(icon, color: color, size: AppSize.r(context, 20)),
        );
      },
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Delete account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'We will send an OTP to your registered phone number to confirm this request.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              maxLength: 250,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Reason for deletion',
                hintText: 'Tell us why you are leaving',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _reasonController.text.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop(_reasonController.text.trim()),
            style: TextButton.styleFrom(foregroundColor: ColorConstants.red),
            child: const Text('Send OTP'),
          ),
        ],
      );
}

class _PersonalInfoSheet extends StatelessWidget {
  const _PersonalInfoSheet({required this.user});

  final AuthUser user;

  String _date(DateTime? value) {
    if (value == null) return 'Not available';
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year}, '
        '${two(local.hour)}:${two(local.minute)}';
  }

  String _value(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? 'Not available' : text;
  }

  @override
  Widget build(BuildContext context) {
    final rows = <({String label, String value})>[
      (label: 'Name', value: _value(user.name)),
      (label: 'Phone', value: _value(user.phone)),
      (label: 'Email', value: _value(user.email)),
      // (label: 'User ID', value: user.userId),
      // (label: 'Account ID', value: _value(user.databaseId)),
      // (label: 'User type', value: _value(user.userType)),
      (label: 'Account status', value: _value(user.state)),
      (
        label: 'Interests',
        value: user.interests.isEmpty
            ? 'No interests selected'
            : user.interests.join(', '),
      ),
      (
        label: 'Aadhaar verified',
        value: user.aadhaarVerified ? 'Yes' : 'No',
      ),
      (
        label: 'KYC attempts',
        value: user.verificationAttempts.toString(),
      ),
      (label: 'KYC verified at', value: _date(user.kycVerifiedAt)),
      (label: 'Last login', value: _date(user.lastLogin)),
      // (
      //   label: 'Failed login attempts',
      //   value: user.failedLoginAttempts.toString(),
      // ),
      // (label: 'Created at', value: _date(user.createdAt)),
      // (label: 'Updated at', value: _date(user.updatedAt)),
      // (
      //   label: 'Deletion requested',
      //   value: _date(user.deletionRequestedAt),
      // ),
      // (
      //   label: 'Deletion scheduled',
      //   value: _date(user.deletionScheduledAt),
      // ),
      // (
      //   label: 'Deletion reminder sent',
      //   value: _date(user.deletionReminderSentAt),
      // ),
      // (
      //   label: 'State before deletion',
      //   value: _value(user.stateBeforeDeletion),
      // ),
    ];

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSize.r(context, 22)),
          ),
        ),
        child: Column(
          children: <Widget>[
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
                      'Personal information',
                      style: TextStyleConstants.screenTitle.copyWith(
                        fontSize: AppSize.sp(context, 19),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: ColorConstants.line),
            Expanded(
              child: ListView(
                padding: AppSize.insets(
                  context,
                  left: 18,
                  right: 18,
                  top: 10,
                  bottom: 24,
                ),
                children: <Widget>[
                  ...rows.map(
                    (row) => _InfoRow(label: row.label, value: row.value),
                  ),
                  if (user.stateHistory.isNotEmpty) ...<Widget>[
                    SizedBox(height: AppSize.h(context, 12)),
                    Text(
                      'Account history',
                      style: TextStyleConstants.cardTitleSmall.copyWith(
                        fontSize: AppSize.sp(context, 15),
                      ),
                    ),
                    SizedBox(height: AppSize.h(context, 8)),
                    ...user.stateHistory.map(
                      (entry) => _HistoryCard(
                        entry: entry,
                        formattedDate: _date(entry.timestamp),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSize.symmetric(context, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyleConstants.caption.copyWith(
                color: ColorConstants.mute,
                fontSize: AppSize.sp(context, 12),
              ),
            ),
          ),
          SizedBox(width: AppSize.w(context, 12)),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyleConstants.bodyMedium.copyWith(
                fontSize: AppSize.sp(context, 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.entry,
    required this.formattedDate,
  });

  final AuthStateHistoryEntry entry;
  final String formattedDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: AppSize.h(context, 8)),
      padding: AppSize.symmetric(context, horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ColorConstants.gray50,
        borderRadius: BorderRadius.circular(AppSize.r(context, 10)),
        border: Border.all(color: ColorConstants.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${entry.fromState ?? 'New'} → ${entry.toState}',
            style: TextStyleConstants.bodyMedium.copyWith(
              fontSize: AppSize.sp(context, 12),
            ),
          ),
          if (entry.reason.isNotEmpty) ...<Widget>[
            SizedBox(height: AppSize.h(context, 4)),
            Text(
              entry.reason,
              style: TextStyleConstants.caption.copyWith(
                color: ColorConstants.mute,
              ),
            ),
          ],
          SizedBox(height: AppSize.h(context, 4)),
          Text(
            '$formattedDate • ${entry.changedBy}',
            style: TextStyleConstants.caption.copyWith(
              color: ColorConstants.mute,
              fontSize: AppSize.sp(context, 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({this.user, this.onEditTap});

  final AuthUser? user;
  final VoidCallback? onEditTap;

  String get _initials {
    final name = user?.name.trim() ?? '';
    if (name.isEmpty) return '';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      final first = parts.first;
      return (first.length <= 2 ? first : first.substring(0, 2)).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final loading = user == null;
    final avatarSize = AppSize.r(context, 52);
    return Container(
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
        borderRadius: BorderRadius.circular(AppSize.r(context, 16)),
        border: Border.all(color: ColorConstants.line),
      ),
      child: Row(
        children: <Widget>[
          // Avatar
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Container(
                width: avatarSize,
                height: avatarSize,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: <Color>[
                      ColorConstants.brandBlueLight,
                      ColorConstants.brandBlue,
                    ],
                  ),
                ),
                child: loading
                    ? SizedBox(
                        width: AppSize.r(context, 18),
                        height: AppSize.r(context, 18),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ColorConstants.white,
                        ),
                      )
                    : user!.profilePicUrl != null
                        ? ClipOval(
                            child: Image.network(
                              user!.profilePicUrl!,
                              fit: BoxFit.cover,
                              width: avatarSize,
                              height: avatarSize,
                              errorBuilder: (_, _, _) => Text(
                                _initials,
                                style: TextStyleConstants.cardTitleSmall.copyWith(
                                  color: ColorConstants.white,
                                  fontSize: AppSize.sp(context, 16),
                                ),
                              ),
                            ),
                          )
                        : Text(
                            _initials,
                            style: TextStyleConstants.cardTitleSmall.copyWith(
                              color: ColorConstants.white,
                              fontSize: AppSize.sp(context, 16),
                            ),
                          ),
              ),
              if (onEditTap != null)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: GestureDetector(
                    onTap: onEditTap,
                    child: Container(
                      width: AppSize.r(context, 20),
                      height: AppSize.r(context, 20),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorConstants.brandBlue,
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        size: AppSize.r(context, 11),
                        color: ColorConstants.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: AppSize.w(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  loading ? 'Loading profile...' : user!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyleConstants.cardTitleSmall.copyWith(
                    fontSize: AppSize.sp(context, 16),
                  ),
                ),
                SizedBox(height: AppSize.h(context, 3)),
                Text(
                  loading ? 'Please wait' : user!.phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyleConstants.caption.copyWith(
                    fontSize: AppSize.sp(context, 12),
                    color: ColorConstants.mute,
                  ),
                ),
                if (!loading && user!.aadhaarVerified) ...<Widget>[
                  SizedBox(height: AppSize.h(context, 4)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: ColorConstants.pillSuccessBg,
                      borderRadius: BorderRadius.circular(
                        AppSize.r(context, 6),
                      ),
                      border: Border.all(
                        color: ColorConstants.profitBgStrong,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.verified_rounded,
                          size: AppSize.r(context, 12),
                          color: ColorConstants.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'KYC Verified',
                          style: TextStyleConstants.caption.copyWith(
                            fontSize: AppSize.sp(context, 11),
                            fontWeight: FontWeight.w600,
                            color: ColorConstants.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onEditTap != null)
            IconButton(
              onPressed: onEditTap,
              icon: Icon(
                Icons.edit_outlined,
                size: AppSize.r(context, 20),
                color: ColorConstants.brandBlue,
              ),
              tooltip: 'Edit profile',
            ),
        ],
      ),
    );
  }
}

class _ProfileErrorCard extends StatelessWidget {
  const _ProfileErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSize.symmetric(context, horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(AppSize.r(context, 16)),
        border: Border.all(color: ColorConstants.line),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'Unable to load profile',
              style: TextStyleConstants.bodyMedium,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
