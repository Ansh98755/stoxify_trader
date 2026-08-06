import '../../../../core/constants/color_constants.dart';
import '../../../../core/widgets/common_batch_card.dart';
import '../../../../core/widgets/risk_badge.dart';
import '../../data/models/discover_analyst_model.dart';
import '../../data/models/discover_batch_model.dart';
import '../widgets/discover_analyst_card.dart';

class DiscoverUiMapper {
  /// Backend `win_rate` is already a percent (e.g. 39.7 → "39.7%"). Do not ×100.
  static String formatWinRateLabel(double winRate) {
    if (winRate == winRate.roundToDouble()) {
      return '${winRate.toInt()}%';
    }
    final trimmed = winRate
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    return '$trimmed%';
  }

  static DiscoverAnalystData toAnalystData(DiscoverAnalystModel model) {
    return DiscoverAnalystData(
      userId: model.userId,
      name: model.name,
      initials: _getInitials(model.name),
      sebi: model.sebiLicenseNumber,
      subtitle: _registrationTypeLabel(model.registrationType),
      profilePicUrl: model.profilePicUrl,
      winRate: formatWinRateLabel(model.winRate),
      avgPnl: formatAvgPnlLabel(model.avgPnlPercent),
      experienceYears: '${model.experienceYears}',
      tags: model.segmentsCovered.take(3).toList(),
      avatarStart: ColorConstants.brandBlueLight,
      avatarEnd: ColorConstants.brandBlue,
    );
  }

  /// Keeps Avg P&L readable on narrow metric columns (e.g. `+0.69%`).
  static String formatAvgPnlLabel(double avgPnlPercent) {
    final sign = avgPnlPercent >= 0 ? '+' : '';
    final value = avgPnlPercent.toStringAsFixed(2);
    return '$sign$value%';
  }

  static CommonBatchData toBatchData(DiscoverBatchModel model) {
    RiskLevel risk = RiskLevel.medium;
    if (model.riskLevel == 'LOW') risk = RiskLevel.low;
    if (model.riskLevel == 'HIGH') risk = RiskLevel.high;

    final about = model.description?.trim();
    return CommonBatchData(
      name: model.name,
      risk: risk,
      analyst: model.analystName,
      analystInit: _getInitials(model.analystName),
      sebi: model.analystSebiNumber ?? '',
      // Match batch details: show plan name when about text is missing.
      description: (about != null && about.isNotEmpty) ? about : model.name,
      tags: <String>[...model.segments, ...model.horizons].take(4).toList(),
      price: '₹${model.startingPrice.round()}',
      subscriberCount: model.subscriberCount == null
          ? null
          : _formatSubscribers(model.subscriberCount!),
      priceSuffix: billingSuffix(model.cheapestTier?.billingCycle),
      avatarStart: ColorConstants.brandBlueLight,
      avatarEnd: ColorConstants.brandBlue,
    );
  }

  static String _getInitials(String name) {
    if (name.trim().isEmpty) return 'A';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  static String _registrationTypeLabel(String? value) {
    if (value == null || value.isEmpty) return '';
    return value
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  static String _formatSubscribers(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  static String billingSuffix(String? billingCycle) {
    return switch (billingCycle?.toUpperCase()) {
      'DAY' => '/day',
      'WEEK' => '/week',
      'MONTH' => '/month',
      'QUARTER' => '/quarter',
      'YEAR' => '/year',
      _ => '',
    };
  }
}
