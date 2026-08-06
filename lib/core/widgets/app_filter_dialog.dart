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
    this.horizon = 'All',
    this.riskLevel = 'All',
    this.segments = const <String>{},
    this.categories = const <String>{},
    this.statuses = const <String>{},
    this.horizons = const <String>{},
    this.riskLevels = const <String>{},
  });

  /// Single-select segment (Discover / legacy). Prefer [segments] when multi.
  final String segment;
  final String sort;
  final String horizon;
  final String riskLevel;

  /// Multi-select API values (no "All" — empty means no filter).
  final Set<String> segments;
  final Set<String> categories;
  final Set<String> statuses;
  final Set<String> horizons;
  final Set<String> riskLevels;

  bool get isDefault =>
      (segment == 'All' || segment.isEmpty) &&
      (horizon == 'All' || horizon.isEmpty) &&
      (riskLevel == 'All' || riskLevel.isEmpty) &&
      segments.isEmpty &&
      categories.isEmpty &&
      statuses.isEmpty &&
      horizons.isEmpty &&
      riskLevels.isEmpty;

  AppFilterResult copyWith({
    String? segment,
    String? sort,
    String? horizon,
    String? riskLevel,
    Set<String>? segments,
    Set<String>? categories,
    Set<String>? statuses,
    Set<String>? horizons,
    Set<String>? riskLevels,
  }) {
    return AppFilterResult(
      segment: segment ?? this.segment,
      sort: sort ?? this.sort,
      horizon: horizon ?? this.horizon,
      riskLevel: riskLevel ?? this.riskLevel,
      segments: segments ?? this.segments,
      categories: categories ?? this.categories,
      statuses: statuses ?? this.statuses,
      horizons: horizons ?? this.horizons,
      riskLevels: riskLevels ?? this.riskLevels,
    );
  }
}

Future<AppFilterResult?> showAppFilterDialog({
  required BuildContext context,
  required AppFilterResult initial,
  required List<String> segments,
  required List<String> sortOptions,
  List<String> horizons = const <String>[],
  List<String> riskLevels = const <String>[],
  List<String> categories = const <String>[],
  List<String> statuses = const <String>[],

  /// When true, segment / category / status (and optional horizon / risk)
  /// chips are multi-select. Empty selection means no filter for that group.
  bool multiSelect = false,
}) {
  return showGeneralDialog<AppFilterResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Filters',
    barrierColor: ColorConstants.scrim,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return const SizedBox.shrink();
        },
    transitionBuilder:
        (
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
                  horizons: horizons,
                  riskLevels: riskLevels,
                  categories: categories,
                  statuses: statuses,
                  sortOptions: sortOptions,
                  multiSelect: multiSelect,
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
    required this.horizons,
    required this.riskLevels,
    required this.categories,
    required this.statuses,
    required this.sortOptions,
    required this.multiSelect,
  });

  final AppFilterResult initial;
  final List<String> segments;
  final List<String> horizons;
  final List<String> riskLevels;
  final List<String> categories;
  final List<String> statuses;
  final List<String> sortOptions;
  final bool multiSelect;

  @override
  State<_AppFilterDialog> createState() => _AppFilterDialogState();
}

class _AppFilterDialogState extends State<_AppFilterDialog> {
  late String _segment;
  late String _sort;
  late String _horizon;
  late String _riskLevel;
  late Set<String> _segments;
  late Set<String> _categories;
  late Set<String> _statuses;
  late Set<String> _horizons;
  late Set<String> _riskLevels;

  @override
  void initState() {
    super.initState();
    _segment = widget.initial.segment;
    _sort = widget.initial.sort;
    _horizon = widget.initial.horizon;
    _riskLevel = widget.initial.riskLevel;
    _segments = Set<String>.from(widget.initial.segments);
    _categories = Set<String>.from(widget.initial.categories);
    _statuses = Set<String>.from(widget.initial.statuses);
    _horizons = Set<String>.from(widget.initial.horizons);
    _riskLevels = Set<String>.from(widget.initial.riskLevels);
  }

  void _reset() {
    setState(() {
      _segment = 'All';
      _sort = widget.sortOptions.isNotEmpty
          ? widget.sortOptions.first
          : 'Newest';
      _horizon = 'All';
      _riskLevel = 'All';
      _segments = <String>{};
      _categories = <String>{};
      _statuses = <String>{};
      _horizons = <String>{};
      _riskLevels = <String>{};
    });
  }

  void _toggleMulti(Set<String> current, String value) {
    setState(() {
      if (value == 'All') {
        current.clear();
        return;
      }
      if (current.contains(value)) {
        current.remove(value);
      } else {
        current.add(value);
        // "All" is mutually exclusive with concrete values.
        current.remove('All');
      }
    });
  }

  bool _isSelected({
    required String label,
    required String singleValue,
    required Set<String> multiValues,
  }) {
    if (!widget.multiSelect) return singleValue == label;
    if (label == 'All') {
      return multiValues.isEmpty;
    }
    return multiValues.contains(label);
  }

  void _onChipTap({
    required String label,
    required void Function(String) setSingle,
    required Set<String> multiValues,
  }) {
    if (widget.multiSelect) {
      _toggleMulti(multiValues, label);
    } else {
      setState(() => setSingle(label));
    }
  }

  Widget _section({
    required String title,
    required List<String> options,
    required String singleValue,
    required Set<String> multiValues,
    required void Function(String) setSingle,
  }) {
    if (options.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: AppSize.h(context, 16)),
        Text(
          title,
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
          children: options
              .map(
                (String label) => FilterChipPill(
                  label: label,
                  selected: _isSelected(
                    label: label,
                    singleValue: singleValue,
                    multiValues: multiValues,
                  ),
                  onTap: () => _onChipTap(
                    label: label,
                    setSingle: setSingle,
                    multiValues: multiValues,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
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
                maxHeight: MediaQuery.sizeOf(context).height * 0.82,
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
                          borderRadius: BorderRadius.circular(
                            AppSize.r(context, 8),
                          ),
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(
                              AppSize.r(context, 8),
                            ),
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
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (widget.segments.isNotEmpty) ...<Widget>[
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
                                        selected: _isSelected(
                                          label: label,
                                          singleValue: _segment,
                                          multiValues: _segments,
                                        ),
                                        onTap: () => _onChipTap(
                                          label: label,
                                          setSingle: (v) => _segment = v,
                                          multiValues: _segments,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                            _section(
                              title: 'Category',
                              options: widget.categories,
                              singleValue: '',
                              multiValues: _categories,
                              setSingle: (_) {},
                            ),
                            _section(
                              title: 'Status',
                              options: widget.statuses,
                              singleValue: '',
                              multiValues: _statuses,
                              setSingle: (_) {},
                            ),
                            if (widget.horizons.isNotEmpty)
                              _section(
                                title: 'Horizon',
                                options: widget.horizons,
                                singleValue: _horizon,
                                multiValues: _horizons,
                                setSingle: (v) => _horizon = v,
                              ),
                            if (widget.riskLevels.isNotEmpty)
                              _section(
                                title: 'Risk level',
                                options: widget.riskLevels,
                                singleValue: _riskLevel,
                                multiValues: _riskLevels,
                                setSingle: (v) => _riskLevel = v,
                              ),
                            if (widget.sortOptions.isNotEmpty) ...<Widget>[
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
                                        onTap: () =>
                                            setState(() => _sort = label),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
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
                              final multiSegments = Set<String>.from(_segments)
                                ..remove('All');
                              final multiHorizons = Set<String>.from(_horizons)
                                ..remove('All');
                              final multiRisk = Set<String>.from(_riskLevels)
                                ..remove('All');
                              final multiCategories =
                                  Set<String>.from(_categories)..remove('All');
                              final multiStatuses =
                                  Set<String>.from(_statuses)..remove('All');

                              final String resolvedSegment =
                                  widget.multiSelect
                                      ? (multiSegments.isEmpty
                                          ? 'All'
                                          : multiSegments.first)
                                      : _segment;
                              final String resolvedHorizon =
                                  widget.multiSelect
                                      ? (multiHorizons.isEmpty
                                          ? 'All'
                                          : multiHorizons.first)
                                      : _horizon;
                              final String resolvedRisk =
                                  widget.multiSelect
                                      ? (multiRisk.isEmpty
                                          ? 'All'
                                          : multiRisk.first)
                                      : _riskLevel;

                              Navigator.of(context).pop(
                                AppFilterResult(
                                  segment: resolvedSegment,
                                  sort: _sort,
                                  horizon: resolvedHorizon,
                                  riskLevel: resolvedRisk,
                                  segments: multiSegments,
                                  categories: multiCategories,
                                  statuses: multiStatuses,
                                  horizons: multiHorizons,
                                  riskLevels: multiRisk,
                                ),
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
