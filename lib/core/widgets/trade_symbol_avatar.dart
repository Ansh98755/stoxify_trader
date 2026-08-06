import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../constants/color_constants.dart';
import '../constants/text_style_constants.dart';
import '../di/injection.dart';
import '../services/trade_icon_service.dart';
import '../utils/app_size.dart';

/// Circular (or rounded-square) instrument logo for trades.
///
/// Prefers [logoUrl] when provided; otherwise resolves via
/// [TradeIconService] → `GET /market-data/search`. Falls back to initials.
class TradeSymbolAvatar extends StatefulWidget {
  const TradeSymbolAvatar({
    super.key,
    required this.symbol,
    this.companyName,
    this.logoUrl,
    this.size,
    this.borderRadius,
    this.circular = true,
  });

  final String symbol;
  final String? companyName;
  final String? logoUrl;
  final double? size;

  /// When non-null and [circular] is false, used as corner radius.
  final double? borderRadius;
  final bool circular;

  @override
  State<TradeSymbolAvatar> createState() => _TradeSymbolAvatarState();
}

class _TradeSymbolAvatarState extends State<TradeSymbolAvatar> {
  String? _iconUrl;
  bool _loading = false;
  Object? _resolveToken;

  @override
  void initState() {
    super.initState();
    _beginResolve();
  }

  @override
  void didUpdateWidget(covariant TradeSymbolAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol ||
        oldWidget.companyName != widget.companyName ||
        oldWidget.logoUrl != widget.logoUrl) {
      _beginResolve();
    }
  }

  void _beginResolve() {
    final known = widget.logoUrl?.trim();
    if (known != null && known.isNotEmpty) {
      setState(() {
        _iconUrl = known;
        _loading = false;
      });
      return;
    }

    final token = Object();
    _resolveToken = token;
    setState(() {
      _iconUrl = null;
      _loading = true;
    });

    getIt<TradeIconService>()
        .iconFor(
      symbol: widget.symbol,
      companyName: widget.companyName,
      knownLogoUrl: widget.logoUrl,
    )
        .then((url) {
      if (!mounted || !identical(_resolveToken, token)) return;
      setState(() {
        _iconUrl = url;
        _loading = false;
      });
    }).catchError((_) {
      if (!mounted || !identical(_resolveToken, token)) return;
      setState(() {
        _iconUrl = null;
        _loading = false;
      });
    });
  }

  String get _initials {
    final s = widget.symbol.trim();
    if (s.isEmpty) return 'TM';
    return s.substring(0, s.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.size ?? AppSize.r(context, 42);
    final Decoration decoration = BoxDecoration(
      shape: widget.circular ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: widget.circular
          ? null
          : BorderRadius.circular(
              widget.borderRadius ?? AppSize.r(context, 14),
            ),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          ColorConstants.avatarBlueStart,
          ColorConstants.avatarBlueEnd,
        ],
      ),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: ColorConstants.navy.withValues(alpha: 0.08),
          blurRadius: AppSize.r(context, 12),
          offset: Offset(0, AppSize.h(context, 4)),
        ),
      ],
    );

    final url = _iconUrl;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: decoration,
      alignment: Alignment.center,
      child: url != null
          ? Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              // Web: marketplace CDNs often omit CORS. Flutter web's default
              // fetch-based decode fails then; HTML <img> can still paint.
              // Mobile ignores this and keeps the normal native load path.
              webHtmlElementStrategy: kIsWeb
                  ? WebHtmlElementStrategy.fallback
                  : WebHtmlElementStrategy.never,
              errorBuilder: (_, _, _) => _Initials(
                initials: _initials,
                size: size,
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _Initials(initials: _initials, size: size);
              },
            )
          : _Initials(
              initials: _initials,
              size: size,
              subtle: _loading,
            ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({
    required this.initials,
    required this.size,
    this.subtle = false,
  });

  final String initials;
  final double size;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    return Text(
      initials,
      style: TextStyle(
        fontFamily: TextStyleConstants.fontFamilyDisplay,
        fontWeight: FontWeight.w600,
        fontSize: size * 0.33,
        color: ColorConstants.white.withValues(alpha: subtle ? 0.7 : 1),
      ),
    );
  }
}
