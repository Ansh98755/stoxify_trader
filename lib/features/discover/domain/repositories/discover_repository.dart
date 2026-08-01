import '../../data/models/discover_analyst_model.dart';
import '../../data/models/discover_batch_model.dart';
import '../../data/models/discover_facets_model.dart';

abstract class DiscoverRepository {
  Future<DiscoverAnalystFacets> fetchAnalystFacets();
  Future<DiscoverPlanFacets> fetchPlanFacets();
  Future<DiscoverAnalystModel> fetchAnalystProfile(String analystId);
  Future<List<DiscoverBatchModel>> fetchAnalystBatches(String analystId);
  Future<DiscoverBatchModel> fetchPlan(String planId);

  Future<List<DiscoverAnalystModel>> fetchAnalysts({
    required int page,
    String? search,
    String? segment,
    String? horizon,
    String? sort,
  });

  Future<List<DiscoverBatchModel>> fetchBatches({
    required int page,
    String? search,
    String? segment,
    String? horizon,
    String? riskLevel,
    String? sort,
  });
}
