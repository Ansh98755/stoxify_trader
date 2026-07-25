import '../../data/models/discover_analyst_model.dart';
import '../../data/models/discover_batch_model.dart';

abstract class DiscoverRepository {
  Future<List<DiscoverAnalystModel>> fetchAnalysts({
    required int page,
    String? search,
    String? segment,
    String? sort,
  });

  Future<List<DiscoverBatchModel>> fetchBatches({
    required int page,
    String? search,
    String? segment,
    String? sort,
  });
}
