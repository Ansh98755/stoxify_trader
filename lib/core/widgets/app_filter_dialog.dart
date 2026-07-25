import 'package:flutter/material.dart';

import '../constants/color_constants.dart';
import '../constants/text_style_constants.dart';
import '../utils/app_size.dart';
import 'common_button_widget.dart';
import 'filter_chip_pill.dart';

class AppFilterResult {
  const AppFilterResult({
    required this.segment,
    required this.sort,
  });

  final String segment;
  final String sort;

  bool get isDefault => segment == 'All';

  AppFilterResult copyWith({String? segment, String? sort}) {
    return AppFilterResult(
      segment: segment ?? this.segment,
      sort: sort ?? this.sort,
    );
  }
}

Future<AppFilterResult?> showAppFilterDialog({
  required BuildContext context,
  required AppFilterResult initial,
  required List<String> segments,
  required List<String> sortOptions,
}) {
  return showGeneralDialog<AppFilterResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Filters',
    barrierColor: ColorConstants.scrim,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) {
      return const SizedBox.shrink();
    },
    transitionBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.08, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: _AppFilterDialog(
              initial: initial,
              segments: segments,
              sortOptions: sortOptions,
            ),
          ),
        ),
      );
    },
  );
}

class _AppFilterDialog extends StatefulWidget {
  const _AppFilterDialog({
    required this.initial,
    required this.segments,
    required this.sortOptions,
  });

  final AppFilterResult initial;
  final List<String> segments;
  final List<String> sortOptions;

  @override
  State<_AppFilterDialog> createState() => _AppFilterDialogState();
}

class _AppFilterDialogState extends State<_AppFilterDialog> {
  late String _segment;
  late String _sort;

  @override
  void initState() {
    super.initState();
    _segment = widget.initial.segment;
    _sort = widget.initial.sort;
  }

  void _reset() {
    setState(() {
      _segment = 'All';
      _sort = widget.sortOptions.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: AppSize.symmetric(context, horizontal: 20),
          child: Material(
            color: ColorConstants.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSize.r(context, 16)),
              side: const BorderSide(color: ColorConstants.line),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: AppSize.w(context, 360),
              ),
              child: Padding(
                padding: AppSize.insets(
                  context,
                  left: 16,
                  right: 16,
                  top: 14,
                  bottom: 14,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Filters',
                            style: TextStyleConstants.cardTitleSmall.copyWith(
                              fontSize: AppSize.sp(context, 15),
                              color: ColorConstants.navy,
                            ),
                          ),
                        ),
                        Material(
                          color: ColorConstants.gray50,
                          borderRadius:
                              BorderRadius.circular(AppSize.r(context, 8)),
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius:
                                BorderRadius.circular(AppSize.r(context, 8)),
                            child: SizedBox(
                              width: AppSize.r(context, 28),
                              height: AppSize.r(context, 28),
                              child: Icon(
                                Icons.close_rounded,
                                size: AppSize.r(context, 16),
                                color: ColorConstants.mute,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSize.h(context, 14)),
                    Text(
                      'Segment',
                      style: TextStyleConstants.caption.copyWith(
                        fontSize: AppSize.sp(context, 11),
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.mute,
                      ),
                    ),
                    SizedBox(height: AppSize.h(context, 8)),
                    Wrap(
                      spacing: AppSize.w(context, 8),
                      runSpacing: AppSize.h(context, 8),
                      children: widget.segments
                          .map(
                            (String label) => FilterChipPill(
                              label: label,
                              selected: _segment == label,
                              onTap: () => setState(() => _segment = label),
                            ),
                          )
                          .toList(),
                    ),
                    SizedBox(height: AppSize.h(context, 16)),
                    Text(
                      'Sort by',
                      style: TextStyleConstants.caption.copyWith(
                        fontSize: AppSize.sp(context, 11),
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.mute,
                      ),
                    ),
                    SizedBox(height: AppSize.h(context, 8)),
                    Wrap(
                      spacing: AppSize.w(context, 8),
                      runSpacing: AppSize.h(context, 8),
                      children: widget.sortOptions
                          .map(
                            (String label) => FilterChipPill(
                              label: label,
                              selected: _sort == label,
                              onTap: () => setState(() => _sort = label),
                            ),
                          )
                          .toList(),
                    ),
                    SizedBox(height: AppSize.h(context, 18)),
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: 2,
                          child: CommonButtonWidget(
                            label: 'Apply',
                            height: 44,
                            borderRadius: 10,
                            onPressed: () {
                              Navigator.of(context).pop(
                                AppFilterResult(segment: _segment, sort: _sort),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: AppSize.w(context, 8)),
                        Expanded(
                          child: CommonButtonWidget(
                            label: 'Reset',
                            height: 44,
                            borderRadius: 10,
                            backgroundColor: ColorConstants.white,
                            foregroundColor: ColorConstants.ink,
                            borderColor: ColorConstants.line,
                            onPressed: _reset,
                          ),
                        ),
                      ],
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
