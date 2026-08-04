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
import '../../../../core/utils/main_tab_navigation.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_filter_dialog.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../../core/widgets/bottom_navbar.dart';
import '../../../../core/widgets/common_batch_card.dart';
import '../../../../core/widgets/web_side_drawer.dart';
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
    final String value = option.value == 'FNO'
        ? 'F&O'
        : option.value
              .toLowerCase()
              .split('_')
              .map(
                (part) => part.isEmpty
                    ? part
                    : '${part[0].toUpperCase()}${part.substring(1)}',
              )
              .join(' ');
    return '$value (${option.count})';
  }

  String? _selectedFacetValue(
    String selected,
    List<DiscoverFacetOption>? options,
  ) {
    if (selected == 'All' || options == null) return null;
    for (final option in options) {
      if (_facetLabel(option) == selected) return option.value;
    }
    return null;
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
          segment: _selectedFacetValue(_filters.segment, facets?.segments),
          horizon: _selectedFacetValue(_filters.horizon, facets?.horizons),
          sort: _filters.sort,
          isRefresh: isRefresh,
        ),
      );
    } else {
      final facets = _bloc.state.planFacets;
      _bloc.add(
        DiscoverBatchesLoadRequested(
          search: _searchController.text,
          segment: _selectedFacetValue(_filters.segment, facets?.segments),
          horizon: _selectedFacetValue(_filters.horizon, facets?.horizons),
          riskLevel: _selectedFacetValue(
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
    final result = await showAppFilterDialog(
      context: context,
      initial: _filters,
      segments: _segments,
      horizons: _horizons,
      riskLevels: _riskLevels,
      sortOptions: _sortOptions,
    );
    if (result == null || !mounted) return;
    setState(() => _filters = result);
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
                  : AppSize.insets(context, left: 16, right: 16, top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  DiscoverSubTabs(
                    active: _browseTab,
                    onChanged: _onBrowseTabChanged,
                  ),
                  SizedBox(height: isWeb ? 14 : AppSize.h(context, 18)),
                  HomeSearchRow(
                    controller: _searchController,
                    hintText: 'Search analysts or batches',
                    onChanged: (String value) {
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
                  SizedBox(height: isWeb ? 12 : AppSize.h(context, 12)),
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
                          return _withRefresh(
                            isWeb
                                ? _WebTwoColList(
                                    itemCount: analysts.length,
                                    itemBuilder: (context, index) {
                                      return DiscoverAnalystCard(
                                        data: analysts[index],
                                        onTap: () => context.push(
                                          AppRoutingName.advisorProfile,
                                          extra: state.analysts[index],
                                        ),
                                      );
                                    },
                                  )
                                : ListView.separated(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: EdgeInsets.only(
                                      top: AppSize.h(context, 6),
                                      bottom: AppSize.h(context, 88),
                                    ),
                                    itemCount: analysts.length,
                                    separatorBuilder: (context, index) =>
                                        SizedBox(
                                            height: AppSize.h(context, 20)),
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
                          return _withRefresh(
                            isWeb
                                ? _WebTwoColList(
                                    itemCount: batches.length,
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
                                      );
                                    },
                                  )
                                : ListView.separated(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: EdgeInsets.only(
                                      top: AppSize.h(context, 6),
                                      bottom: AppSize.h(context, 88),
                                    ),
                                    itemCount: batches.length,
                                    separatorBuilder: (context, index) =>
                                        SizedBox(
                                            height: AppSize.h(context, 20)),
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
          if (!isWeb)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNavbar(
                currentIndex: 1,
                onItemSelected: (int index) {
                  if (index == 1) return;
                  navigateMainTab(context, index);
                },
              ),
            ),
        ],
      ),
    );

    return BlocProvider.value(
      value: _bloc,
      child: isWeb
          ? WebSideDrawer(currentIndex: 1, child: scaffold)
          : scaffold,
    );
  }
}

/// Web-only 2-column list (analysts / batches) — full width, content height.
class _WebTwoColList extends StatelessWidget {
  const _WebTwoColList({
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    final int rowCount = (itemCount + 1) ~/ 2;
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 24),
      itemCount: rowCount,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, rowIndex) {
        final int leftIndex = rowIndex * 2;
        final int rightIndex = leftIndex + 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: itemBuilder(context, leftIndex)),
            const SizedBox(width: 16),
            Expanded(
              child: rightIndex < itemCount
                  ? itemBuilder(context, rightIndex)
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
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
