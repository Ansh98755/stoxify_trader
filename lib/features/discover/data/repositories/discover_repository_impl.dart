import '../../domain/repositories/discover_repository.dart';
import '../datasources/discover_remote_data_source.dart';
import '../models/discover_analyst_model.dart';
import '../models/discover_batch_model.dart';
import '../models/discover_facets_model.dart';

class DiscoverRepositoryImpl implements DiscoverRepository {
  DiscoverRepositoryImpl(this._remoteDataSource);

  final DiscoverRemoteDataSource _remoteDataSource;

  @override
  Future<DiscoverAnalystFacets> fetchAnalystFacets() {
    return _remoteDataSource.fetchAnalystFacets();
  }

  @override
  Future<DiscoverPlanFacets> fetchPlanFacets() {
    return _remoteDataSource.fetchPlanFacets();
  }

  @override
  Future<DiscoverAnalystModel> fetchAnalystProfile(String analystId) {
    return _remoteDataSource.fetchAnalystProfile(analystId);
  }

  @override
  Future<List<DiscoverBatchModel>> fetchAnalystBatches(String analystId) {
    return _remoteDataSource.fetchAnalystBatches(analystId);
  }

  @override
  Future<DiscoverBatchModel> fetchPlan(String planId) {
    return _remoteDataSource.fetchPlan(planId);
  }

  @override
  Future<List<DiscoverAnalystModel>> fetchAnalysts({
    required int page,
    String? search,
    String? segment,
    String? horizon,
    String? sort,
  }) {
    return _remoteDataSource.fetchAnalysts(
      page: page,
      search: search,
      segment: segment,
      horizon: horizon,
      sort: sort,
    );
  }

  @override
  Future<List<DiscoverBatchModel>> fetchBatches({
    required int page,
    String? search,
    String? segment,
    String? horizon,
    String? riskLevel,
    String? sort,
  }) {
    return _remoteDataSource.fetchBatches(
      page: page,
      search: search,
      segment: segment,
      horizon: horizon,
      riskLevel: riskLevel,
      sort: sort,
    );
  }
}
