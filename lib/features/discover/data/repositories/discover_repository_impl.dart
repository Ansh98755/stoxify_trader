import '../../domain/repositories/discover_repository.dart';
import '../datasources/discover_remote_data_source.dart';
import '../models/discover_analyst_model.dart';
import '../models/discover_batch_model.dart';

class DiscoverRepositoryImpl implements DiscoverRepository {
  DiscoverRepositoryImpl(this._remoteDataSource);

  final DiscoverRemoteDataSource _remoteDataSource;

  @override
  Future<List<DiscoverAnalystModel>> fetchAnalysts({
    required int page,
    String? search,
    String? segment,
    String? sort,
  }) {
    return _remoteDataSource.fetchAnalysts(
      page: page,
      search: search,
      segment: segment,
      sort: sort,
    );
  }

  @override
  Future<List<DiscoverBatchModel>> fetchBatches({
    required int page,
    String? search,
    String? segment,
    String? sort,
  }) {
    return _remoteDataSource.fetchBatches(
      page: page,
      search: search,
      segment: segment,
      sort: sort,
    );
  }
}
