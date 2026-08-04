import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants/color_constants.dart';
import '../constants/text_style_constants.dart';
import '../utils/app_size.dart';
import '../utils/responsive_layout.dart';

class BottomNavbar extends StatelessWidget {
  const BottomNavbar({
    required this.currentIndex,
    required this.onItemSelected,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  static const List<_BottomNavbarDestination> _destinations =
      <_BottomNavbarDestination>[
        _BottomNavbarDestination(
          label: 'Home',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
        ),
        _BottomNavbarDestination(
          label: 'Discover',
          icon: Icons.explore_outlined,
          selectedIcon: Icons.explore_rounded,
        ),
        _BottomNavbarDestination(
          label: 'Trades',
          icon: Icons.show_chart_rounded,
          selectedIcon: Icons.show_chart_rounded,
        ),
        _BottomNavbarDestination(
          label: 'Profile',
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    // Wide web uses the side drawer; phone web keeps bottom nav like the app.
    if (isDesktopWeb(context)) return const SizedBox.shrink();

    return SafeArea(
      minimum: AppSize.insets(context, left: 12, right: 12, bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSize.r(context, 16)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: ColorConstants.navyDark.withValues(alpha: 0.22),
              blurRadius: AppSize.r(context, 28),
              offset: Offset(0, AppSize.h(context, 10)),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSize.r(context, 16)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: AppSize.h(context, 64),
              padding: AppSize.symmetric(context, horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    ColorConstants.white.withValues(alpha: 0.55),
                    ColorConstants.white.withValues(alpha: 0.40),
                    ColorConstants.brandBlue.withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSize.r(context, 16)),
                border: Border.all(
                  color: ColorConstants.white.withValues(alpha: 0.55),
                  width: AppSize.r(context, 1),
                ),
              ),
              child: Row(
                children: List<Widget>.generate(_destinations.length, (index) {
                  final destination = _destinations[index];
                  return Expanded(
                    child: _BottomNavbarItem(
                      destination: destination,
                      isSelected: currentIndex == index,
                      onTap: () => onItemSelected(index),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavbarItem extends StatelessWidget {
  const _BottomNavbarItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final _BottomNavbarDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isSelected
        ? ColorConstants.brandBlue
        : ColorConstants.navy.withValues(alpha: 0.55);

    return Semantics(
      button: true,
      selected: isSelected,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
        splashColor: ColorConstants.brandBlue.withValues(alpha: 0.10),
        highlightColor: ColorConstants.brandBlue.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected
                ? ColorConstants.white.withValues(alpha: 0.45)
                : ColorConstants.transparent,
            borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
            border: isSelected
                ? Border.all(
                    color: ColorConstants.white.withValues(alpha: 0.60),
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AnimatedScale(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                scale: isSelected ? 1.05 : 1,
                child: Icon(
                  isSelected ? destination.selectedIcon : destination.icon,
                  size: AppSize.r(context, 22),
                  color: foregroundColor,
                ),
              ),
              SizedBox(height: AppSize.h(context, 3)),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyleConstants.caption.copyWith(
                  color: foregroundColor,
                  fontSize: AppSize.sp(context, 10),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavbarDestination {
  const _BottomNavbarDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
