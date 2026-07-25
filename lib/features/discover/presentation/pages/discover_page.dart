import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/utils/main_tab_navigation.dart';
import '../../../../core/widgets/app_filter_dialog.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../../core/widgets/bottom_navbar.dart';
import '../../../../core/widgets/common_batch_card.dart';
import '../../../home/presentation/widgets/home_search_row.dart';
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
  DiscoverBrowseTab _browseTab = DiscoverBrowseTab.analysts;
  final TextEditingController _searchController = TextEditingController();
  
  AppFilterResult _filters = const AppFilterResult(
    segment: 'All',
    sort: 'Win rate',
  );

  static const List<String> _analystSegments = <String>[
    'All',
    'Equity',
    'F&O',
    'Intraday',
    'Swing',
  ];

  static const List<String> _batchSegments = <String>[
    'All',
    'Equity',
    'F&O',
    'Low risk',
    'Medium risk',
  ];

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

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.instance<DiscoverBloc>();
    _fetchData();
  }

  void _fetchData() {
    if (_browseTab == DiscoverBrowseTab.analysts) {
      _bloc.add(DiscoverLoadRequested(
        search: _searchController.text,
        segment: _filters.segment,
        sort: _filters.sort,
      ));
    } else {
      _bloc.add(DiscoverBatchesLoadRequested(
        search: _searchController.text,
        segment: _filters.segment,
        sort: _filters.sort,
      ));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  List<String> get _segments =>
      _browseTab == DiscoverBrowseTab.analysts
          ? _analystSegments
          : _batchSegments;

  List<String> get _sortOptions =>
      _browseTab == DiscoverBrowseTab.analysts
          ? _analystSortOptions
          : _batchSortOptions;

  Future<void> _openFilters() async {
    final result = await showAppFilterDialog(
      context: context,
      initial: _filters,
      segments: _segments,
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
        body: Stack(
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
                      hintText: 'Search analysts or batches',
                      onChanged: (String value) {
                        _fetchData();
                      },
                      onFilterTap: _openFilters,
                      hasActiveFilters: !_filters.isDefault ||
                          _filters.sort != _sortOptions.first,
                    ),
                    SizedBox(height: AppSize.h(context, 20)),
                    Expanded(
                      child: BlocBuilder<DiscoverBloc, DiscoverState>(
                        builder: (context, state) {
                          if (state.status == DiscoverStatus.loading) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (state.status == DiscoverStatus.failure) {
                            return _EmptyState(message: 'Error: ${state.error}');
                          }

                          if (_browseTab == DiscoverBrowseTab.analysts) {
                            final analysts = state.analysts.map((m) => DiscoverUiMapper.toAnalystData(m)).toList();
                            if (analysts.isEmpty) {
                              return const _EmptyState(message: 'No analysts match your search');
                            }
                            return ListView.separated(
                              padding: EdgeInsets.only(bottom: AppSize.h(context, 88)),
                              itemCount: analysts.length,
                              separatorBuilder: (context, index) => SizedBox(height: AppSize.h(context, 20)),
                              itemBuilder: (context, index) {
                                return DiscoverAnalystCard(
                                  data: analysts[index],
                                  onTap: () => context.push(AppRoutingName.advisorProfile),
                                );
                              },
                            );
                          } else {
                            final batches = state.batches.map((m) => DiscoverUiMapper.toBatchData(m)).toList();
                            if (batches.isEmpty) {
                              return const _EmptyState(message: 'No batches match your search');
                            }
                            return ListView.separated(
                              padding: EdgeInsets.only(bottom: AppSize.h(context, 88)),
                              itemCount: batches.length,
                              separatorBuilder: (context, index) => SizedBox(height: AppSize.h(context, 20)),
                              itemBuilder: (context, index) {
                                return CommonBatchCard(
                                  data: batches[index],
                                  onSubscribe: () => context.push(AppRoutingName.subscriptions),
                                  onTap: () => context.push(AppRoutingName.advisorProfile),
                                );
                              },
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}
