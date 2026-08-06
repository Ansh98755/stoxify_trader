import 'package:flutter/material.dart';

import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/shimmer/shimmer_widgets.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/utils/responsive_layout.dart';

class HomeSubscriptionItem {
  const HomeSubscriptionItem({
    required this.id,
    required this.initials,
    required this.name,
    required this.activeUntil,
    this.batchName,
    this.analystName,
    this.avatarStart = const Color(0xFF60A5FA),
    this.avatarEnd = ColorConstants.brandBlue,
  });

  final String id;
  final String initials;
  /// Kept for backward-compat — equals batchName ?? analystName.
  final String name;
  final String activeUntil;
  /// Shown on the first line of the tile.
  final String? batchName;
  /// Shown on the second line of the tile (below batch name).
  final String? analystName;
  final Color avatarStart;
  final Color avatarEnd;
}

class HomeSubscriptionsStrip extends StatelessWidget {
  const HomeSubscriptionsStrip({
    super.key,
    required this.items,
    this.onManageTap,
    this.onSubscriptionTap,
    this.isLoading = false,
  });

  final List<HomeSubscriptionItem> items;
  final VoidCallback? onManageTap;
  final ValueChanged<HomeSubscriptionItem>? onSubscriptionTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Your subscriptions',
                style: TextStyleConstants.bodyMedium.copyWith(
                  color: ColorConstants.mute,
                  fontSize: AppSize.sp(context, 13),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            InkWell(
              onTap: onManageTap,
              borderRadius: BorderRadius.circular(AppSize.r(context, 6)),
              child: Padding(
                padding: AppSize.symmetric(
                  context,
                  horizontal: 8,
                  vertical: 4,
                ),
                child: Text(
                  'Manage',
                  style: TextStyleConstants.bodyMedium.copyWith(
                    color: ColorConstants.brandBlue,
                    fontSize: AppSize.sp(context, 12),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSize.h(context, 10)),
        SizedBox(
          height: AppSize.h(context, 62),
          child: isLoading
              ? const ShimmerSubscriptionStrip(count: 3)
              : items.isEmpty
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'No active subscriptions yet',
                        style: TextStyleConstants.caption.copyWith(
                          fontSize: AppSize.sp(context, 12),
                          color: ColorConstants.mute,
                        ),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          SizedBox(width: AppSize.w(context, 10)),
                      itemBuilder: (BuildContext context, int index) {
                        final item = items[index];
                        return _SubscriptionCard(
                          item: item,
                          onTap: onSubscriptionTap == null
                              ? null
                              : () => onSubscriptionTap!(item),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.item,
    this.onTap,
  });

  final HomeSubscriptionItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatarSize = AppSize.r(context, 36);

    return SizedBox(
      width: ResponsiveLayout.useWebDesktopShell(context)
          ? 200
          : AppSize.w(context, 148),
      child: Material(
        color: ColorConstants.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
          side: const BorderSide(color: ColorConstants.line),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
          child: Padding(
            padding: AppSize.insets(
              context,
              left: 10,
              top: 10,
              right: 10,
              bottom: 10,
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[item.avatarStart, item.avatarEnd],
                    ),
                  ),
                  child: Text(
                    item.initials,
                    style: TextStyleConstants.caption.copyWith(
                      color: ColorConstants.white,
                      fontSize: AppSize.sp(context, 12),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: AppSize.w(context, 8)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        item.batchName ?? item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyleConstants.bodyMedium.copyWith(
                          color: ColorConstants.ink,
                          fontSize: AppSize.sp(context, 12),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppSize.h(context, 2)),
                      Text(
                        item.analystName?.isNotEmpty == true
                            ? item.analystName!
                            : item.activeUntil,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyleConstants.caption.copyWith(
                          fontSize: AppSize.sp(context, 10),
                          color: ColorConstants.mute,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
