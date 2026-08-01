import '../../../../core/constants/color_constants.dart';
import '../../../../core/widgets/common_batch_card.dart';
import '../../../../core/widgets/risk_badge.dart';
import '../../data/models/discover_analyst_model.dart';
import '../../data/models/discover_batch_model.dart';
import '../widgets/discover_analyst_card.dart';

class DiscoverUiMapper {
  static DiscoverAnalystData toAnalystData(DiscoverAnalystModel model) {
    return DiscoverAnalystData(
      userId: model.userId,
      name: model.name,
      initials: _getInitials(model.name),
      sebi: model.sebiLicenseNumber,
      subtitle: _registrationTypeLabel(model.registrationType),
      profilePicUrl: model.profilePicUrl,
      winRate: '${(model.winRate * 100).round()}%',
      avgPnl: '${model.avgPnlPercent >= 0 ? '+' : ''}${model.avgPnlPercent}%',
      subscribers: _formatSubscribers(model.totalSubscribers),
      tags: model.segmentsCovered.take(3).toList(),
      avatarStart: ColorConstants.brandBlueLight,
      avatarEnd: ColorConstants.brandBlue,
    );
  }

  static CommonBatchData toBatchData(DiscoverBatchModel model) {
    RiskLevel risk = RiskLevel.medium;
    if (model.riskLevel == 'LOW') risk = RiskLevel.low;
    if (model.riskLevel == 'HIGH') risk = RiskLevel.high;

    return CommonBatchData(
      name: model.name,
      risk: risk,
      analyst: model.analystName,
      analystInit: _getInitials(model.analystName),
      sebi: model.analystSebiNumber ?? '',
      description: model.description ?? '',
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
