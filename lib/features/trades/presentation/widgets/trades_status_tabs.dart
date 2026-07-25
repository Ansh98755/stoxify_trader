import 'package:flutter/material.dart';

import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/utils/app_size.dart';

enum TradesStatusTab { active, closed }

class TradesStatusTabs extends StatelessWidget {
  const TradesStatusTabs({
    required this.active,
    required this.onChanged,
    super.key,
  });

  final TradesStatusTab active;
  final ValueChanged<TradesStatusTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _TabItem(
            label: 'Active',
            selected: active == TradesStatusTab.active,
            onTap: () => onChanged(TradesStatusTab.active),
          ),
        ),
        SizedBox(width: AppSize.w(context, 8)),
        Expanded(
          child: _TabItem(
            label: 'Closed',
            selected: active == TradesStatusTab.closed,
            onTap: () => onChanged(TradesStatusTab.closed),
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
              fontSize: AppSize.sp(context, 13),
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? ColorConstants.ink : ColorConstants.mute,
            ),
          ),
        ),
      ),
    );
  }
}
