import 'package:flutter/material.dart';

import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/utils/app_size.dart';

enum DiscoverBrowseTab { analysts, batches }

class DiscoverSubTabs extends StatelessWidget {
  const DiscoverSubTabs({
    required this.active,
    required this.onChanged,
    super.key,
  });

  final DiscoverBrowseTab active;
  final ValueChanged<DiscoverBrowseTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _TabItem(
            label: 'Browse Analysts',
            selected: active == DiscoverBrowseTab.analysts,
            onTap: () => onChanged(DiscoverBrowseTab.analysts),
          ),
        ),
        SizedBox(width: AppSize.w(context, 8)),
        Expanded(
          child: _TabItem(
            label: 'Browse Batches',
            selected: active == DiscoverBrowseTab.batches,
            onTap: () => onChanged(DiscoverBrowseTab.batches),
          ),
        ),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? ColorConstants.white
          : ColorConstants.white.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
        side: BorderSide(
          color: selected
              ? ColorConstants.navy.withValues(alpha: 0.35)
              : ColorConstants.line,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
        child: Padding(
          padding: AppSize.symmetric(context, horizontal: 10, vertical: 11),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyleConstants.bodyMedium.copyWith(
              fontSize: AppSize.sp(context, 12.5),
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? ColorConstants.ink : ColorConstants.mute,
            ),
          ),
        ),
      ),
    );
  }
}
