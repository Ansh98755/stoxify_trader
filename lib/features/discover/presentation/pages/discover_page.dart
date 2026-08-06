import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/shimmer/shimmer_widgets.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_filter_dialog.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../../core/widgets/main_tab_shell.dart';
import '../../../../core/widgets/common_batch_card.dart';
import '../../../home/presentation/widgets/home_search_row.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../../subscriptions/presentation/pages/subscriptions_page.dart';
import '../../data/models/discover_facets_model.dart';
import '../bloc/discover_bloc.dart';
import '../bloc/discover_event.dart';
import '../bloc/discover_state.dart';
import '../mappers/discover_ui_mapper.dart';
import '../widgets/discover_analyst_card.dart';
import '../widgets/discover_sub_tabs.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  late final DiscoverBloc _bloc;
  final HomeRepository _homeRepository = GetIt.instance<HomeRepository>();
  DiscoverBrowseTab _browseTab = DiscoverBrowseTab.analysts;
  Set<String> _activePlanIds = const <String>{};
  Set<String> _activeBatchIds = const <String>{};
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  AppFilterResult _filters = const AppFilterResult(
    segment: 'All',
    sort: 'Win rate',
  );

  // Analyst segment and horizon choices now come from
  // GET /users/analysts/facets.

  // Sort options remain local because the facets endpoint does not expose
  // supported sorting metadata.
  static const List<String> _analystSortOptions = <String>[
    'Win rate',
    'Avg P&L',
    'Subscribers',
  ];

  static const List<String> _batchSortOptions = <String>[
    'Most popular',
    'Price: low to high',
    'Price: high to low',
  ];

  List<String> get _analystSegments => <String>[
    'All',
    ...?_bloc.state.analystFacets?.segments.map(_facetLabel),
  ];

  List<String> get _analystHorizons => <String>[
    'All',
    ...?_bloc.state.analystFacets?.horizons.map(_facetLabel),
  ];

  List<String> get _batchSegments => <String>[
    'All',
    ...?_bloc.state.planFacets?.segments.map(_facetLabel),
  ];

  List<String> get _batchHorizons => <String>[
    'All',
    ...?_bloc.state.planFacets?.horizons.map(_facetLabel),
  ];

  List<String> get _batchRiskLevels => <String>[
    'All',
    ...?_bloc.state.planFacets?.riskLevels.map(_facetLabel),
  ];

  String _facetLabel(DiscoverFacetOption option) {
    return '${_facetPlainLabel(option.value)} (${option.count})';
  }

  String _facetPlainLabel(String raw) {
    if (raw.toUpperCase() == 'FNO') return 'F&O';
    return raw
        .toLowerCase()
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  String _stripCount(String label) {
    return label.replaceAll(RegExp(r'\s*\(\d+\)\s*$'), '').trim();
  }

  bool _labelMatchesOption(String selected, DiscoverFacetOption option) {
    if (selected == 'All' || selected.isEmpty) return false;
    if (_facetLabel(option) == selected) return true;
    final plain = _stripCount(selected).toLowerCase();
    final optPlain = _facetPlainLabel(option.value).toLowerCase();
    final optValue = option.value.toUpperCase();
    final selectedUpper = selected.trim().toUpperCase();
    return plain == optPlain ||
        plain == optValue.toLowerCase() ||
        selectedUpper == optValue ||
        (optValue == 'FNO' && (plain == 'f&o' || plain == 'fno' || plain == 'fo'));
  }

  String? _selectedFacetValue(
    String selected,
    List<DiscoverFacetOption>? options,
  ) {
    if (selected == 'All' || options == null) return null;
    // Already an API value?
    final selectedUpper = selected.trim().toUpperCase();
    for (final option in options) {
      if (option.value.toUpperCase() == selectedUpper) return option.value;
    }
    for (final option in options) {
      if (_labelMatchesOption(selected, option)) return option.value;
    }
    return null;
  }

  /// Resolves multi-select selections (labels or API values) into a
  /// comma-separated API param. Empty = no filter.
  String? _resolveFacetCsv(
    Set<String> selected,
    String singleSelected,
    List<DiscoverFacetOption>? options,
  ) {
    if (selected.isNotEmpty) {
      final values = <String>[];
      for (final item in selected) {
        if (item == 'All' || item.isEmpty) continue;
        // Prefer raw stored API values when present.
        final asApi = item.trim().toUpperCase();
        if (options != null &&
            options.any((o) => o.value.toUpperCase() == asApi)) {
          values.add(asApi);
          continue;
        }
        final mapped = _selectedFacetValue(item, options);
        if (mapped != null && mapped.isNotEmpty) {
          values.add(mapped.toUpperCase());
        } else if (options == null && asApi != 'ALL') {
          values.add(asApi);
        }
      }
      if (values.isEmpty) return null;
      return values.toSet().join(',');
    }
    return _selectedFacetValue(singleSelected, options);
  }

  Set<String> _apiValuesToChipLabels(
    Set<String> apiValues,
    List<DiscoverFacetOption>? options,
  ) {
    if (apiValues.isEmpty) return const <String>{};
    if (options == null) {
      return apiValues.map(_facetPlainLabel).toSet();
    }
    final labels = <String>{};
    for (final api in apiValues) {
      final upper = api.toUpperCase();
      DiscoverFacetOption? match;
      for (final o in options) {
        if (o.value.toUpperCase() == upper) {
          match = o;
          break;
        }
      }
      labels.add(match != null ? _facetLabel(match) : _facetPlainLabel(api));
    }
    return labels;
  }

  Set<String> _chipLabelsToApiValues(
    Set<String> labels,
    List<DiscoverFacetOption>? options,
  ) {
    if (labels.isEmpty) return const <String>{};
    final values = <String>{};
    for (final label in labels) {
      if (label == 'All') continue;
      final mapped = _selectedFacetValue(label, options);
      if (mapped != null && mapped.isNotEmpty) {
        values.add(mapped.toUpperCase());
      }
    }
    return values;
  }

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.instance<DiscoverBloc>();
    _fetchData();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    try {
      final subscriptions = await _homeRepository.fetchSubscriptions();
      if (!mounted) return;
      setState(() {
        _activePlanIds = subscriptions
            .where((subscription) => subscription.isActive)
            .map((subscription) => subscription.planId)
            .whereType<String>()
            .toSet();
        _activeBatchIds = subscriptions
            .where((subscription) => subscription.isActive)
            .map((subscription) => subscription.batchId)
            .whereType<String>()
            .toSet();
      });
    } catch (_) {
      // Subscription state is supplementary to browsing; keep cards usable.
    }
  }

  void _fetchData({bool isRefresh = false}) {
    if (_browseTab == DiscoverBrowseTab.analysts) {
      final facets = _bloc.state.analystFacets;
      _bloc.add(
        DiscoverLoadRequested(
          search: _searchController.text,
          segment: _resolveFacetCsv(
            _filters.segments,
            _filters.segment,
            facets?.segments,
          ),
          horizon: _resolveFacetCsv(
            _filters.horizons,
            _filters.horizon,
            facets?.horizons,
          ),
          sort: _filters.sort,
          isRefresh: isRefresh,
        ),
      );
    } else {
      final facets = _bloc.state.planFacets;
      _bloc.add(
        DiscoverBatchesLoadRequested(
          search: _searchController.text,
          segment: _resolveFacetCsv(
            _filters.segments,
            _filters.segment,
            facets?.segments,
          ),
          horizon: _resolveFacetCsv(
            _filters.horizons,
            _filters.horizon,
            facets?.horizons,
          ),
          riskLevel: _resolveFacetCsv(
            _filters.riskLevels,
            _filters.riskLevel,
            facets?.riskLevels,
          ),
          sort: _filters.sort,
          isRefresh: isRefresh,
        ),
      );
    }
  }

  Future<void> _refreshData() async {
    final Future<DiscoverState> refreshCompleted = _bloc.stream.firstWhere(
      (state) =>
          state.status == DiscoverStatus.success ||
          state.status == DiscoverStatus.failure,
    );
    _fetchData(isRefresh: true);
    await refreshCompleted;
  }

  Widget _withRefresh(Widget child) {
    return RefreshIndicator(
      color: ColorConstants.brandBlue,
      onRefresh: _refreshData,
      child: child,
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  List<String> get _segments => _browseTab == DiscoverBrowseTab.analysts
      ? _analystSegments
      : _batchSegments;

  List<String> get _sortOptions => _browseTab == DiscoverBrowseTab.analysts
      ? _analystSortOptions
      : _batchSortOptions;

  List<String> get _horizons => _browseTab == DiscoverBrowseTab.analysts
      ? _analystHorizons
      : _batchHorizons;

  List<String> get _riskLevels => _browseTab == DiscoverBrowseTab.analysts
      ? const <String>[]
      : _batchRiskLevels;

  Future<void> _openFilters() async {
    final List<DiscoverFacetOption>? segmentFacets;
    final List<DiscoverFacetOption>? horizonFacets;
    final List<DiscoverFacetOption>? riskFacets;

    if (_browseTab == DiscoverBrowseTab.analysts) {
      final facets = _bloc.state.analystFacets;
      segmentFacets = facets?.segments;
      horizonFacets = facets?.horizons;
      riskFacets = null;
    } else {
      final facets = _bloc.state.planFacets;
      segmentFacets = facets?.segments;
      horizonFacets = facets?.horizons;
      riskFacets = facets?.riskLevels;
    }

    final result = await showAppFilterDialog(
      context: context,
      multiSelect: true,
      initial: AppFilterResult(
        segment: 'All',
        sort: _filters.sort,
        horizon: 'All',
        riskLevel: 'All',
        segments: _apiValuesToChipLabels(_filters.segments, segmentFacets),
        horizons: _apiValuesToChipLabels(_filters.horizons, horizonFacets),
        riskLevels: _apiValuesToChipLabels(_filters.riskLevels, riskFacets),
      ),
      segments: _segments,
      horizons: _horizons,
      riskLevels: _riskLevels,
      sortOptions: _sortOptions,
    );
    if (result == null || !mounted) return;

    setState(() {
      _filters = AppFilterResult(
        segment: 'All',
        sort: result.sort,
        horizon: 'All',
        riskLevel: 'All',
        // Persist stable API values so changing facet counts cannot break filters.
        segments: _chipLabelsToApiValues(result.segments, segmentFacets),
        horizons: _chipLabelsToApiValues(result.horizons, horizonFacets),
        riskLevels: _chipLabelsToApiValues(result.riskLevels, riskFacets),
      );
    });
    _fetchData();
  }

  void _onBrowseTabChanged(DiscoverBrowseTab tab) {
    setState(() {
      _browseTab = tab;
      _filters = AppFilterResult(
        segment: 'All',
        horizon: 'All',
        sort: tab == DiscoverBrowseTab.analysts
            ? _analystSortOptions.first
            : _batchSortOptions.first,
      );
    });
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        extendBody: true,
        backgroundColor: ColorConstants.transparent,
        body: MainTabShell(
          currentIndex: 1,
          child: Stack(
          children: <Widget>[
            const AppScreenBackground(),
            SafeArea(
              child: Padding(
                padding: AppSize.insets(context, left: 16, right: 16, top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    DiscoverSubTabs(
                      active: _browseTab,
                      onChanged: _onBrowseTabChanged,
                    ),
                    SizedBox(height: AppSize.h(context, 18)),
                    HomeSearchRow(
                      controller: _searchController,
                      hintText: _browseTab == DiscoverBrowseTab.analysts
                          ? 'Search analysts'
                          : 'Search batches',
                      onChanged: (String value) {
                        // Rebuild so the clear affordance reflects text state.
                        setState(() {});
                        _searchDebounce?.cancel();
                        _searchDebounce = Timer(
                          const Duration(milliseconds: 300),
                          _fetchData,
                        );
                      },
                      onFilterTap: _openFilters,
                      hasActiveFilters:
                          !_filters.isDefault ||
                          _filters.sort != _sortOptions.first,
                    ),
                    SizedBox(height: AppSize.h(context, 12)),
                    Expanded(
                      child: BlocBuilder<DiscoverBloc, DiscoverState>(
                        builder: (context, state) {
                          if (state.status == DiscoverStatus.loading) {
                            return _browseTab == DiscoverBrowseTab.analysts
                                ? const ShimmerAnalystList(count: 4)
                                : const ShimmerBatchList(count: 3);
                          }

                          if (state.status == DiscoverStatus.failure) {
                            return _withRefresh(
                              _EmptyState(
                                message: 'Error: ${state.error}',
                              ),
                            );
                          }

                          if (_browseTab == DiscoverBrowseTab.analysts) {
                            final analysts = state.analysts
                                .map((m) => DiscoverUiMapper.toAnalystData(m))
                                .toList();
                            if (analysts.isEmpty) {
                              return _withRefresh(
                                const _EmptyState(
                                  message: 'No analysts match your search',
                                ),
                              );
                            }
                            final columns =
                                ResponsiveLayout.cardGridColumns(context);
                            if (columns > 1) {
                              return _withRefresh(
                                GridView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  clipBehavior: Clip.none,
                                  padding: EdgeInsets.only(
                                    top: AppSize.h(context, 18),
                                    bottom: AppSize.h(context, 24),
                                  ),
                                  gridDelegate:
                                      (SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    mainAxisSpacing: 20,
                                    crossAxisSpacing: 16,
                                    mainAxisExtent:
                                        columns >= 3 ? 172 : 180,
                                  )),
                                  itemCount: analysts.length,
                                  itemBuilder: (context, index) {
                                    return Align(
                                      alignment: Alignment.topCenter,
                                      child: DiscoverAnalystCard(
                                        data: analysts[index],
                                        onTap: () => context.push(
                                          AppRoutingName.advisorProfile,
                                          extra: state.analysts[index],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }
                            return _withRefresh(
                              ListView.separated(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                clipBehavior: Clip.none,
                                padding: EdgeInsets.only(
                                  top: AppSize.h(context, 6),
                                  bottom: AppSize.h(context, 88),
                                ),
                                itemCount: analysts.length,
                                separatorBuilder: (context, index) =>
                                    SizedBox(height: AppSize.h(context, 20)),
                                itemBuilder: (context, index) {
                                  return DiscoverAnalystCard(
                                    data: analysts[index],
                                    onTap: () => context.push(
                                      AppRoutingName.advisorProfile,
                                      extra: state.analysts[index],
                                    ),
                                  );
                                },
                              ),
                            );
                          } else {
                            final batches = state.batches
                                .map((m) => DiscoverUiMapper.toBatchData(m))
                                .toList();
                            if (batches.isEmpty) {
                              return _withRefresh(
                                const _EmptyState(
                                  message: 'No batches match your search',
                                ),
                              );
                            }
                            final columns =
                                ResponsiveLayout.cardGridColumns(context);
                            if (columns > 1) {
                              return _withRefresh(
                                GridView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: EdgeInsets.only(
                                    top: AppSize.h(context, 6),
                                    bottom: AppSize.h(context, 24),
                                  ),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    mainAxisExtent:
                                        columns >= 3 ? 260 : 280,
                                  ),
                                  itemCount: batches.length,
                                  itemBuilder: (context, index) {
                                    return Align(
                                      alignment: Alignment.topCenter,
                                      child: CommonBatchCard(
                                        data: batches[index],
                                        isSubscribed: _activePlanIds.contains(
                                              state.batches[index].planId,
                                            ) ||
                                            state.batches[index].tiers.any(
                                              (tier) => _activeBatchIds
                                                  .contains(tier.id),
                                            ),
                                        onSubscribe: () => context.push(
                                          AppRoutingName.subscriptions,
                                          extra: SubscriptionPageArgs(
                                            planId:
                                                state.batches[index].planId,
                                            analystId: state
                                                .batches[index].analystId,
                                          ),
                                        ),
                                        onTap: () => context.push(
                                          AppRoutingName.batchDetails,
                                          extra: state.batches[index].planId,
                                        ),
                                        onAnalystTap: () => context.push(
                                          AppRoutingName.advisorProfile,
                                          extra:
                                              state.batches[index].analystId,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }
                            return _withRefresh(
                              ListView.separated(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.only(
                                  top: AppSize.h(context, 6),
                                  bottom: AppSize.h(context, 88),
                                ),
                                itemCount: batches.length,
                                separatorBuilder: (context, index) =>
                                    SizedBox(height: AppSize.h(context, 20)),
                                itemBuilder: (context, index) {
                                  return CommonBatchCard(
                                    data: batches[index],
                                    isSubscribed: _activePlanIds.contains(
                                      state.batches[index].planId,
                                    ) ||
                                        state.batches[index].tiers.any(
                                          (tier) => _activeBatchIds
                                              .contains(tier.id),
                                        ),
                                    onSubscribe: () => context.push(
                                      AppRoutingName.subscriptions,
                                      extra: SubscriptionPageArgs(
                                        planId: state.batches[index].planId,
                                        analystId:
                                            state.batches[index].analystId,
                                      ),
                                    ),
                                    onTap: () => context.push(
                                      AppRoutingName.batchDetails,
                                      extra: state.batches[index].planId,
                                    ),
                                    onAnalystTap: () => context.push(
                                      AppRoutingName.advisorProfile,
                                      extra: state.batches[index].analystId,
                                    ),
                                  );
                                },
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppSize.h(context, 40)),
          child: Center(
            child: Text(
              message,
              style: TextStyleConstants.bodyMedium.copyWith(
                color: ColorConstants.mute,
                fontSize: AppSize.sp(context, 13),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
