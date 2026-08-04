import '../entities/home_subscription.dart';
import '../entities/home_trade.dart';
import '../entities/payment_transaction.dart';

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
  Future<List<PaymentTransaction>> fetchPaymentTransactions();

  Future<bool> saveTrade(String tradeId);

  Future<bool> unsaveTrade(String tradeId);

  Future<List<HomeTrade>> fetchSavedTrades();

  Future<Set<String>> fetchSavedTradeIds();

  /// Invalidates subscription cache — call after purchase / cancellation.
  void invalidateSubscriptions();

  /// Invalidates saved-trade-IDs cache — call on pull-to-refresh.
  void invalidateSavedIds();

  /// Clears all cached data. Called on logout.
  void clearAll();
}
