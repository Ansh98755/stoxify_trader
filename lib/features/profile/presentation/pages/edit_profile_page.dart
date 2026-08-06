import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../../core/widgets/common_button_widget.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.user});

  final AuthUser user;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;

  final _repo = GetIt.instance<AuthRepository>();
  final _picker = ImagePicker();

  String? _avatarUrl; // current hosted URL (from user or after upload)
  Uint8List? _pickedBytes; // locally picked preview (mobile + web safe)
  bool _uploadingAvatar = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _emailCtrl = TextEditingController(text: widget.user.email ?? '');
    _avatarUrl = widget.user.profilePicUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // ── Avatar ──────────────────────────────────────────────────────────────

  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: ColorConstants.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSize.r(context, 20)),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(height: AppSize.h(ctx, 8)),
            Container(
              width: AppSize.w(ctx, 36),
              height: AppSize.h(ctx, 4),
              decoration: BoxDecoration(
                color: ColorConstants.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: AppSize.h(ctx, 16)),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Take a photo'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            SizedBox(height: AppSize.h(ctx, 8)),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _pickedBytes = bytes;
      _error = null;
    });

    // Upload immediately so user sees the result before saving profile.
    setState(() => _uploadingAvatar = true);
    try {
      final base64Str = base64Encode(bytes);
      final name = picked.name.toLowerCase();
      final path = picked.path.toLowerCase();
      final contentType = name.endsWith('.png') || path.endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';

      final url = await _repo.uploadAvatar(
        imageBase64: base64Str,
        contentType: contentType,
      );
      if (mounted) setState(() => _avatarUrl = url);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Avatar upload failed. You can still save other changes.');
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_saving || _uploadingAvatar) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final updated = await _repo.updateProfile(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        profilePicUrl: _avatarUrl,
      );
      if (!mounted) return;
      // Return the updated user to the caller so the profile page refreshes.
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString().replaceFirst(RegExp(r'^.*Exception:\s*'), '');
        });
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.transparent,
      body: Stack(
        children: <Widget>[
          const AppScreenBackground(),
          SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: AppSize.insets(
                    context,
                    left: 16,
                    right: 16,
                    top: 8,
                  ),
                  child: AppBackHeader(
                    title: 'Edit profile',
                    trailing: _saving
                        ? SizedBox(
                            width: AppSize.r(context, 20),
                            height: AppSize.r(context, 20),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ColorConstants.brandBlue,
                            ),
                          )
                        : null,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppSize.insets(
                      context,
                      left: 16,
                      right: 16,
                      top: 24,
                      bottom: 32,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // ── Avatar ──────────────────────────────────────
                          Center(child: _AvatarPicker(
                            pickedBytes: _pickedBytes,
                            avatarUrl: _avatarUrl,
                            uploading: _uploadingAvatar,
                            initials: _initials,
                            onTap: _pickAvatar,
                          )),
                          SizedBox(height: AppSize.h(context, 32)),

                          // ── Name ────────────────────────────────────────
                          _FieldLabel('Full name'),
                          SizedBox(height: AppSize.h(context, 6)),
                          TextFormField(
                            controller: _nameCtrl,
                            textCapitalization: TextCapitalization.words,
                            keyboardType: TextInputType.name,
                            style: TextStyleConstants.bodyMedium.copyWith(
                              fontSize: AppSize.sp(context, 14),
                              color: ColorConstants.ink,
                            ),
                            decoration: _inputDecoration(context, 'Your full name'),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Name cannot be empty';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: AppSize.h(context, 20)),

                          // ── Email ───────────────────────────────────────
                          _FieldLabel('Email address'),
                          SizedBox(height: AppSize.h(context, 6)),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyleConstants.bodyMedium.copyWith(
                              fontSize: AppSize.sp(context, 14),
                              color: ColorConstants.ink,
                            ),
                            decoration: _inputDecoration(context, 'you@example.com'),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final emailRe = RegExp(
                                r'^[\w.+\-]+@[a-zA-Z\d\-]+(\.[a-zA-Z\d\-]+)*\.[a-zA-Z]{2,}$',
                              );
                              if (!emailRe.hasMatch(v.trim())) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: AppSize.h(context, 8)),

                          // ── Phone (read-only) ───────────────────────────
                          _FieldLabel('Phone number'),
                          SizedBox(height: AppSize.h(context, 6)),
                          _ReadOnlyField(
                            context: context,
                            value: widget.user.phone,
                            hint: 'Phone number',
                          ),

                          if (_error != null) ...<Widget>[
                            SizedBox(height: AppSize.h(context, 20)),
                            Container(
                              width: double.infinity,
                              padding: AppSize.symmetric(
                                context,
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: ColorConstants.red.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(AppSize.r(context, 10)),
                                border: Border.all(
                                  color: ColorConstants.red.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                _error!,
                                style: TextStyleConstants.caption.copyWith(
                                  color: ColorConstants.red,
                                  fontSize: AppSize.sp(context, 12),
                                ),
                              ),
                            ),
                          ],

                          SizedBox(height: AppSize.h(context, 32)),
                          CommonButtonWidget(
                            label: 'Save changes',
                            isLoading: _saving,
                            onPressed: _saving || _uploadingAvatar ? null : _save,
                            height: AppSize.h(context, 50),
                            borderRadius: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _initials {
    final name = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text.trim()
        : widget.user.name;
    if (name.isEmpty) return '';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyleConstants.caption.copyWith(
        color: ColorConstants.soft,
        fontSize: AppSize.sp(context, 13),
      ),
      filled: true,
      fillColor: ColorConstants.white,
      contentPadding: AppSize.symmetric(context, horizontal: 14, vertical: 14),
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
        borderSide: const BorderSide(color: ColorConstants.red, width: 1.5),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.pickedBytes,
    required this.avatarUrl,
    required this.uploading,
    required this.initials,
    required this.onTap,
  });

  final Uint8List? pickedBytes;
  final String? avatarUrl;
  final bool uploading;
  final String initials;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = AppSize.r(context, 88);
    final badgeSize = AppSize.r(context, 28);

    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ColorConstants.brandBlueLight,
                width: 2,
              ),
              gradient: const LinearGradient(
                colors: <Color>[
                  ColorConstants.brandBlueLight,
                  ColorConstants.brandBlue,
                ],
              ),
            ),
            child: ClipOval(
              child: uploading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ColorConstants.white,
                      ),
                    )
                  : pickedBytes != null
                      ? Image.memory(pickedBytes!, fit: BoxFit.cover)
                      : avatarUrl != null
                          ? Image.network(
                              avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _Initials(initials: initials, size: size),
                            )
                          : _Initials(initials: initials, size: size),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: ColorConstants.brandBlue,
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: AppSize.r(context, 14),
                color: ColorConstants.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials, required this.size});
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: TextStyleConstants.cardTitleSmall.copyWith(
          color: ColorConstants.white,
          fontSize: size * 0.28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyleConstants.caption.copyWith(
        fontSize: AppSize.sp(context, 12),
        fontWeight: FontWeight.w600,
        color: ColorConstants.mute,
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.context,
    required this.value,
    required this.hint,
  });
  final BuildContext context;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext ctx) {
    return Container(
      width: double.infinity,
      padding: AppSize.symmetric(context, horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: ColorConstants.gray50,
        borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
        border: Border.all(color: ColorConstants.line),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              value.isNotEmpty ? value : hint,
              style: TextStyleConstants.bodyMedium.copyWith(
                fontSize: AppSize.sp(context, 14),
                color: value.isNotEmpty ? ColorConstants.mute : ColorConstants.soft,
              ),
            ),
          ),
          Icon(
            Icons.lock_outline_rounded,
            size: AppSize.r(context, 16),
            color: ColorConstants.soft,
          ),
        ],
      ),
    );
  }
}
