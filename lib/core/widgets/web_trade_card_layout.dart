import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Shared web-only layout for trade card feeds (max 2 per row).
///
/// Uses row pairs instead of a fixed-height [SliverGrid] so cards hug their
/// content height (no tall empty white panels) and use the full content width.
abstract final class WebTradeCardLayout {
  static const double crossSpacing = 16;
  static const double mainSpacing = 16;
  static const int crossAxisCount = 2;
}

/// Builds a full-width, max-2-column trade card feed for web.
class WebTradeCardGridSliver extends StatelessWidget {
  const WebTradeCardGridSliver({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = EdgeInsets.zero,
  });

  final int itemCount;
  final NullableIndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    assert(kIsWeb, 'WebTradeCardGridSliver is only for web');

    final int rowCount = (itemCount + 1) ~/ WebTradeCardLayout.crossAxisCount;

    return SliverPadding(
      padding: padding,
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int rowIndex) {
            final int leftIndex = rowIndex * 2;
            final int rightIndex = leftIndex + 1;
            final Widget? left = itemBuilder(context, leftIndex);
            final Widget? right = rightIndex < itemCount
                ? itemBuilder(context, rightIndex)
                : null;

            return Padding(
              padding: EdgeInsets.only(
                bottom: rowIndex < rowCount - 1
                    ? WebTradeCardLayout.mainSpacing
                    : 0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: left ?? const SizedBox.shrink()),
                  SizedBox(width: WebTradeCardLayout.crossSpacing),
                  Expanded(child: right ?? const SizedBox.shrink()),
                ],
              ),
            );
          },
          childCount: rowCount,
          addRepaintBoundaries: false,
          addAutomaticKeepAlives: false,
        ),
      ),
    );
  }
}
