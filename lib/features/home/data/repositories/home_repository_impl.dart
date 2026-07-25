import '../../domain/entities/home_subscription.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._remote);

  final HomeRemoteDataSource _remote;

  @override
  Future<HomeFeedPage> fetchFeed({
    required int page,
    String? segment,
  }) {
    return _remote.fetchFeed(page: page, segment: segment);
  }

  @override
  Future<List<HomeSubscription>> fetchSubscriptions() {
    return _remote.fetchSubscriptions();
  }
}
