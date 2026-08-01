import '../../domain/entities/home_subscription.dart';
import '../../domain/entities/home_trade.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._remote);

  final HomeRemoteDataSource _remote;

  @override
  Future<HomeFeedPage> fetchFeed({
    required int page,
    String? segment,
    String status = 'LIVE',
    String? analystId,
  }) {
    return _remote.fetchFeed(
      page: page,
      segment: segment,
      status: status,
      analystId: analystId,
    );
  }

  @override
  Future<HomeTrade> fetchTrade(String tradeId) {
    return _remote.fetchTrade(tradeId);
  }

  @override
  Future<List<HomeSubscription>> fetchSubscriptions() {
    return _remote.fetchSubscriptions();
  }

  @override
  Future<bool> saveTrade(String tradeId) {
    return _remote.saveTrade(tradeId);
  }

  @override
  Future<bool> unsaveTrade(String tradeId) {
    return _remote.unsaveTrade(tradeId);
  }

  @override
  Future<List<HomeTrade>> fetchSavedTrades() {
    return _remote.fetchSavedTrades();
  }

  @override
  Future<Set<String>> fetchSavedTradeIds() {
    return _remote.fetchSavedTradeIds();
  }
}
