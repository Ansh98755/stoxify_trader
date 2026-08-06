import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../constants/color_constants.dart';
import '../constants/text_style_constants.dart';
import '../utils/main_tab_navigation.dart';
import '../utils/responsive_layout.dart';
import 'bottom_navbar.dart';

/// Shared expansion state for the web left rail (all main tabs).
class WebSideNavController {
  WebSideNavController._();

  static final ValueNotifier<bool> expanded = ValueNotifier<bool>(true);

  static void toggle() => expanded.value = !expanded.value;
}

/// Collapsible left navigation used only on wide web layouts.
class WebSideNav extends StatelessWidget {
  const WebSideNav({
    super.key,
    required this.currentIndex,
  });

  final int currentIndex;

  static const double _expandedWidth = 220;
  static const double _collapsedWidth = 72;

  static const List<_NavItem> _items = <_NavItem>[
    _NavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _NavItem(
      label: 'Discover',
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore_rounded,
    ),
    _NavItem(
      label: 'Trades',
      icon: Icons.show_chart_rounded,
      selectedIcon: Icons.show_chart_rounded,
    ),
    _NavItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: WebSideNavController.expanded,
      builder: (context, expanded, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: expanded ? _expandedWidth : _collapsedWidth,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(
            color: ColorConstants.white,
            border: Border(
              right: BorderSide(color: ColorConstants.line),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Gate labels on actual width so text isn't crushed mid-animation.
              final showLabels = constraints.maxWidth >= 160;
              return SafeArea(
                right: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        showLabels ? 16 : 8,
                        16,
                        showLabels ? 8 : 8,
                        12,
                      ),
                      child: showLabels
                          ? Row(
                              children: <Widget>[
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: RichText(
                                      maxLines: 1,
                                      overflow: TextOverflow.clip,
                                      text: TextSpan(
                                        style: TextStyleConstants
                                            .cardTitleLarge
                                            .copyWith(
                                          color: ColorConstants.navy,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        children: const <InlineSpan>[
                                          TextSpan(text: 'Sto'),
                                          TextSpan(
                                            text: 'X',
                                            style: TextStyle(
                                              color: ColorConstants
                                                  .brandBlueLight,
                                            ),
                                          ),
                                          TextSpan(text: 'ify'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Collapse menu',
                                  onPressed: WebSideNavController.toggle,
                                  icon: const Icon(
                                    Icons.menu_open_rounded,
                                    color: ColorConstants.ink,
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: IconButton(
                                tooltip: 'Expand menu',
                                onPressed: WebSideNavController.toggle,
                                icon: const Icon(
                                  Icons.menu_rounded,
                                  color: ColorConstants.ink,
                                ),
                              ),
                            ),
                    ),
                    const Divider(height: 1, color: ColorConstants.line),
                    const SizedBox(height: 8),
                    for (var i = 0; i < _items.length; i++)
                      _SideNavTile(
                        item: _items[i],
                        selected: currentIndex == i,
                        expanded: showLabels,
                        onTap: () {
                          if (i == currentIndex) return;
                          navigateMainTab(context, i);
                        },
                      ),
                    const Spacer(),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SideNavTile extends StatelessWidget {
  const _SideNavTile({
    required this.item,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? ColorConstants.brandBlue : ColorConstants.mute;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Material(
        color: selected
            ? ColorConstants.liveBg
            : ColorConstants.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Tooltip(
            message: item.label,
            preferBelow: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: expanded ? 12 : 0,
                vertical: 12,
              ),
              child: Row(
                mainAxisAlignment: expanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    selected ? item.selectedIcon : item.icon,
                    size: 22,
                    color: color,
                  ),
                  if (expanded) ...<Widget>[
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyleConstants.bodyMedium.copyWith(
                          color: color,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Wraps a main-tab page: bottom nav on mobile/app web; left rail on wide web.
class MainTabShell extends StatelessWidget {
  const MainTabShell({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  final int currentIndex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!ResponsiveLayout.useWebDesktopShell(context)) {
      return Stack(
        children: <Widget>[
          child,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavbar(
              currentIndex: currentIndex,
              onItemSelected: (int index) {
                if (index == currentIndex) return;
                navigateMainTab(context, index);
              },
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        WebSideNav(currentIndex: currentIndex),
        Expanded(child: child),
      ],
    );
  }
}

// Keep kIsWeb reference available for call sites that branch on web alone.
bool get mainTabShellIsWeb => kIsWeb;
