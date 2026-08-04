import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SliverConstraints;

/// Shared web-only sizing for trade card feeds.
///
/// Caps total feed width so that with [crossAxisCount] = 2 each card
/// stays near mobile proportions instead of stretching across the page.
abstract final class WebTradeCardLayout {
  static const double maxFeedWidth = 1080;
  static const double crossSpacing = 16;
  static const double mainSpacing = 16;
  static const int crossAxisCount = 2;

  /// Approximate natural height of a trade card cell on web.
  static const double cardMainAxisExtent = 460;

  static const SliverGridDelegate gridDelegate =
      SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: crossAxisCount,
    mainAxisSpacing: mainSpacing,
    crossAxisSpacing: crossSpacing,
    mainAxisExtent: cardMainAxisExtent,
  );

  /// Horizontal inset so a [maxFeedWidth]-wide feed stays centered on wide screens.
  static EdgeInsets horizontalInset(double crossAxisExtent) {
    final double free = crossAxisExtent - maxFeedWidth;
    final double side = free > 0 ? free / 2 : 0;
    return EdgeInsets.symmetric(horizontal: side);
  }

  /// Pins the card to the top of its grid cell so it never stretches vertically.
  static Widget alignCard(Widget card) {
    return Align(
      alignment: Alignment.topCenter,
      child: card,
    );
  }
}

/// Builds a centered, max-width [SliverGrid] for web trade cards.
class WebTradeCardGridSliver extends StatelessWidget {
  const WebTradeCardGridSliver({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = EdgeInsets.zero,
    this.gridDelegate = WebTradeCardLayout.gridDelegate,
  });

  final int itemCount;
  final NullableIndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry padding;
  final SliverGridDelegate gridDelegate;

  @override
  Widget build(BuildContext context) {
    assert(kIsWeb, 'WebTradeCardGridSliver is only for web');

    return SliverLayoutBuilder(
      builder: (BuildContext context, SliverConstraints constraints) {
        final EdgeInsets inset =
            WebTradeCardLayout.horizontalInset(constraints.crossAxisExtent);
        return SliverPadding(
          padding: padding.add(inset),
          sliver: SliverGrid(
            gridDelegate: gridDelegate,
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final Widget? child = itemBuilder(context, index);
                if (child == null) return null;
                return WebTradeCardLayout.alignCard(child);
              },
              childCount: itemCount,
              addRepaintBoundaries: false,
              addAutomaticKeepAlives: false,
            ),
          ),
        );
      },
    );
  }
}
