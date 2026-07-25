import '../../../../core/constants/color_constants.dart';
import '../../../../core/widgets/common_batch_card.dart';
import '../../../../core/widgets/risk_badge.dart';
import '../../data/models/discover_analyst_model.dart';
import '../../data/models/discover_batch_model.dart';
import '../widgets/discover_analyst_card.dart';

class DiscoverUiMapper {
  static DiscoverAnalystData toAnalystData(DiscoverAnalystModel model) {
    return DiscoverAnalystData(
      name: model.name,
      initials: _getInitials(model.name),
      sebi: model.sebiLicenseNumber ?? 'SEBI-registered',
      subtitle: model.specialization.isNotEmpty
          ? model.specialization.first
          : 'SEBI-registered analyst',
      winRate: '${(model.winRate * 100).round()}%',
      avgPnl: '${model.avgPnlPercent >= 0 ? '+' : ''}${model.avgPnlPercent}%',
      subscribers: _formatSubscribers(model.totalSubscribers),
      tags: [...model.segmentsCovered, ...model.specialization].take(3).toList(),
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
      tags: model.segments.take(3).toList(),
      price: '₹${model.startingPrice.round()}',
      subscriberCount: _formatSubscribers(model.subscriberCount ?? 0),
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

  static String _formatSubscribers(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
