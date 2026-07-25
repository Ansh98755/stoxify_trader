import 'package:dio/dio.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/home_subscription.dart';
import '../../domain/entities/home_trade.dart';
import '../../domain/repositories/home_repository.dart';
import '../models/home_subscription_model.dart';
import '../models/home_trade_model.dart';

class HomeRemoteDataSource {
  HomeRemoteDataSource(this._dio);

  final Dio _dio;

  Map<String, dynamic> _clean(Map<String, dynamic> map) {
    return map..removeWhere((_, value) => value == null || value == '');
  }

  Future<HomeFeedPage> fetchFeed({
    required int page,
    String? segment,
  }) async {
    try {
      final res = await _dio.get<dynamic>(
        '/trades/',
        queryParameters: _clean(<String, dynamic>{
          'page': page,
          'limit': HomeRepository.pageSize,
          'segment': segment,
        }),
      );

      if (res.statusCode == 403) {
        return HomeFeedPage(
          trades: const <HomeTrade>[],
          page: page,
          hasMore: false,
        );
      }
      if (res.statusCode == 401) {
        throw const AuthFailure();
      }
      if (res.statusCode != 200) {
        throw ServerFailure('Failed to load feed (${res.statusCode})');
      }

      final data = (res.data as Map).cast<String, dynamic>();
      final raw = (data['trades'] as List?) ?? const <dynamic>[];
      final trades = raw
          .whereType<Map>()
          .map((e) => HomeTradeModel.fromJson(e.cast<String, dynamic>()))
          .toList();

      final total = (data['total'] as num?)?.toInt() ?? raw.length;
      final loaded = (page - 1) * HomeRepository.pageSize + raw.length;

      return HomeFeedPage(
        trades: trades,
        page: page,
        hasMore: raw.isNotEmpty && loaded < total,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const NetworkFailure();
      }
      rethrow;
    }
  }

  Future<List<HomeSubscription>> fetchSubscriptions() async {
    try {
      final res = await _dio.get<dynamic>(
        '/subscriptions/',
        queryParameters: const <String, dynamic>{'limit': 100},
      );

      if (res.statusCode == 401) throw const AuthFailure();
      if (res.statusCode == 403) return const <HomeSubscription>[];
      if (res.statusCode != 200) {
        throw ServerFailure(
          'Failed to load subscriptions (${res.statusCode})',
        );
      }

      final data = (res.data as Map).cast<String, dynamic>();
      return ((data['subscriptions'] as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (e) => HomeSubscriptionModel.fromJson(e.cast<String, dynamic>()),
          )
          .toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const NetworkFailure();
      }
      rethrow;
    }
  }
}
