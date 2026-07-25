import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/app_screen_background.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  static const List<_SearchHit> _hits = <_SearchHit>[
    _SearchHit(
      title: 'Arjun Mehta',
      subtitle: 'SEBI-registered · Equity & Swing',
      kind: 'Analyst',
      route: AppRoutingName.advisorProfile,
    ),
    _SearchHit(
      title: 'Neha Agarwal',
      subtitle: 'F&O intraday specialist',
      kind: 'Analyst',
      route: AppRoutingName.advisorProfile,
    ),
    _SearchHit(
      title: 'Tata Motors',
      subtitle: 'Active · Swing · Equity Swing Pro',
      kind: 'Trade',
      route: AppRoutingName.tradeDetails,
    ),
    _SearchHit(
      title: 'FNO Mastery 1',
      subtitle: 'Batch · From ₹99/month',
      kind: 'Batch',
      route: AppRoutingName.subscriptions,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final results = _hits
        .where(
          (_SearchHit h) =>
              q.isEmpty ||
              h.title.toLowerCase().contains(q) ||
              h.subtitle.toLowerCase().contains(q) ||
              h.kind.toLowerCase().contains(q),
        )
        .toList();

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
                    title: 'Search',
                    onBack: () => context.pop(),
                  ),
                  SizedBox(height: AppSize.h(context, 14)),
                  Material(
                    color: ColorConstants.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSize.r(context, 14)),
                      side: BorderSide(
                        color: ColorConstants.navy.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Padding(
                      padding: AppSize.symmetric(context, horizontal: 12),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.search_rounded,
                            color: ColorConstants.soft,
                            size: AppSize.r(context, 20),
                          ),
                          SizedBox(width: AppSize.w(context, 8)),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              onChanged: (String v) =>
                                  setState(() => _query = v),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                hintText: 'Search analysts, batches or trades',
                                hintStyle: TextStyleConstants.body.copyWith(
                                  color: ColorConstants.soft,
                                  fontSize: AppSize.sp(context, 13),
                                ),
                              ),
                              style: TextStyleConstants.body.copyWith(
                                color: ColorConstants.ink,
                                fontSize: AppSize.sp(context, 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: AppSize.h(context, 16)),
                  Expanded(
                    child: ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, _) =>
                          SizedBox(height: AppSize.h(context, 10)),
                      itemBuilder: (BuildContext context, int index) {
                        final hit = results[index];
                        return AppMenuListTile(
                          title: hit.title,
                          subtitle: '${hit.kind} · ${hit.subtitle}',
                          onTap: () => context.push(hit.route),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchHit {
  const _SearchHit({
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.route,
  });

  final String title;
  final String subtitle;
  final String kind;
  final String route;
}
