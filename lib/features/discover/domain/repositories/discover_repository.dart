import '../../data/models/discover_analyst_model.dart';
import '../../data/models/discover_batch_model.dart';
import '../../data/models/discover_facets_model.dart';

abstract class DiscoverRepository {
  Future<DiscoverAnalystModel> fetchAnalystProfile(String analystId);
  Future<List<DiscoverBatchModel>> fetchAnalystBatches(String analystId);
  Future<DiscoverBatchModel> fetchPlan(String planId);
  Future<List<AvailableCoupon>> fetchAvailableCoupons({
    required String planId,
    required String analystId,
  });
  Future<CouponVerification> verifyCoupon({
    required String code,
    required String planId,
  });
  Future<SubscriptionCheckout> createSubscription({
    required String planId,
    String? batchId,
    String? couponCode,
  });
  Future<void> verifySubscriptionPayment({
    required String subscriptionId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  });

  Future<List<DiscoverAnalystModel>> fetchAnalysts({
    required int page,
    String? search,
    String? segment,
    String? horizon,
    String? sort,
    bool forceRefresh = false,
  });

  Future<List<DiscoverBatchModel>> fetchBatches({
    required int page,
    String? search,
    String? segment,
    String? horizon,
    String? riskLevel,
    String? sort,
    bool forceRefresh = false,
  });

  Future<DiscoverAnalystFacets> fetchAnalystFacets({
    bool forceRefresh = false,
  });

  Future<DiscoverPlanFacets> fetchPlanFacets({
    bool forceRefresh = false,
  });

  /// Invalidates plan + analyst caches after a subscription purchase.
  void invalidatePlan(String planId, {String? analystId});

  /// Clears all cached data. Called on logout.
  void clearAll();
}
