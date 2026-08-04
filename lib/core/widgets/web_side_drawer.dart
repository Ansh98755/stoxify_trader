import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes/app_routing_name.dart';
import '../constants/color_constants.dart';
import '../constants/text_style_constants.dart';
import '../utils/main_tab_navigation.dart';
import '../utils/responsive_layout.dart';

/// Left-side navigation rail shown only on web.
/// Replaces [BottomNavbar] on wide screens.
///
/// Pass [currentIndex] matching the same convention as [BottomNavbar]:
///   0 = Home, 1 = Discover, 2 = Trades, 3 = Profile
class WebSideDrawer extends StatelessWidget {
  const WebSideDrawer({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  final int currentIndex;
  final Widget child;

  static const double _drawerWidth = 220.0;

  static const List<_NavItem> _items = [
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
    if (!isDesktopWeb(context)) return child;

    return Material(
      color: ColorConstants.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DrawerPanel(
            currentIndex: currentIndex,
            items: _items,
            drawerWidth: _drawerWidth,
          ),
          Container(
            width: 1,
            color: ColorConstants.line,
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _DrawerPanel extends StatelessWidget {
  const _DrawerPanel({
    required this.currentIndex,
    required this.items,
    required this.drawerWidth,
  });

  final int currentIndex;
  final List<_NavItem> items;
  final double drawerWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: drawerWidth,
      child: ColoredBox(
        color: ColorConstants.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Logo area ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ColorConstants.brandBlue,
                          ColorConstants.gradientBlueEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.candlestick_chart_rounded,
                      color: ColorConstants.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'StoXify',
                    style: TextStyleConstants.screenTitle.copyWith(
                      color: ColorConstants.navy,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1, color: ColorConstants.line),
            ),
            const SizedBox(height: 12),
            // ── Nav items ────────────────────────────────────────────────
            ...List.generate(items.length, (i) {
              final item = items[i];
              final selected = currentIndex == i;
              return _DrawerNavItem(
                item: item,
                selected: selected,
                onTap: () {
                  if (!selected) navigateMainTab(context, i);
                },
              );
            }),
            const Spacer(),
            // ── Bottom section: Settings shortcut ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
              child: _DrawerNavItem(
                item: const _NavItem(
                  label: 'Settings',
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings_rounded,
                ),
                selected: false,
                onTap: () => context.push(AppRoutingName.settings),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerNavItem extends StatelessWidget {
  const _DrawerNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            splashColor: ColorConstants.brandBlue.withValues(alpha: 0.08),
            highlightColor: ColorConstants.brandBlue.withValues(alpha: 0.04),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? ColorConstants.brandBlue.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    selected ? item.selectedIcon : item.icon,
                    size: 20,
                    color: selected
                        ? ColorConstants.brandBlue
                        : ColorConstants.mute,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item.label,
                    style: TextStyleConstants.bodyMedium.copyWith(
                      color: selected
                          ? ColorConstants.brandBlue
                          : ColorConstants.ink,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  if (selected) ...[
                    const Spacer(),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: ColorConstants.brandBlue,
                        shape: BoxShape.circle,
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
