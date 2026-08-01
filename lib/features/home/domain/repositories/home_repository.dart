import '../entities/home_subscription.dart';
import '../entities/home_trade.dart';

class HomeFeedPage {
  const HomeFeedPage({
    required this.trades,
    required this.page,
    required this.hasMore,
  });

  final List<HomeTrade> trades;
  final int page;
  final bool hasMore;
}

abstract class HomeRepository {
  static const int pageSize = 20;

  Future<HomeFeedPage> fetchFeed({
    required int page,
    String? segment,
    String status = 'LIVE',
    String? analystId,
  });

  Future<HomeTrade> fetchTrade(String tradeId);

  Future<List<HomeSubscription>> fetchSubscriptions();

  Future<bool> saveTrade(String tradeId);

  Future<bool> unsaveTrade(String tradeId);

  Future<List<HomeTrade>> fetchSavedTrades();

  Future<Set<String>> fetchSavedTradeIds();
}
