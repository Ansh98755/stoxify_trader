import 'package:dio/dio.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/home_subscription.dart';
import '../../domain/entities/home_trade.dart';
import '../../domain/repositories/home_repository.dart';
import '../models/home_subscription_model.dart';
import '../models/home_trade_model.dart';
import '../models/payment_transaction_model.dart';
import '../../domain/entities/payment_transaction.dart';

class HomeRemoteDataSource {
  HomeRemoteDataSource(this._dio);

  final Dio _dio;

  Map<String, dynamic> _clean(Map<String, dynamic> map) {
    return map..removeWhere((_, value) => value == null || value == '');
  }

  Future<HomeFeedPage> fetchFeed({
    required int page,
    String? segment,
    String status = 'LIVE',
    String? analystId,
  }) async {
    try {
      final res = await _dio.get<dynamic>(
        '/trades/',
        queryParameters: _clean(<String, dynamic>{
          'page': page,
          'limit': HomeRepository.pageSize,
          'segment': segment,
          'status': status,
          'analyst_id': analystId,
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

      final Map<String, dynamic>? dataMap = res.data is Map ? (res.data as Map).cast<String, dynamic>() : null;
      List raw;
      if (res.data is List) {
        raw = res.data as List;
      } else if (dataMap != null) {
        raw = (dataMap['trades'] as List?) ??
            (dataMap['data'] is List ? dataMap['data'] as List : null) ??
            (dataMap['data'] is Map
                ? (dataMap['data'] as Map)['trades'] as List?
                : null) ??
            (dataMap['results'] as List?) ??
            const <dynamic>[];
      } else {
        raw = const <dynamic>[];
      }
      final trades = raw
          .whereType<Map>()
          .map((e) => HomeTradeModel.fromJson(e.cast<String, dynamic>()))
          .toList();

      final total = (dataMap?['total'] as num?)?.toInt() ?? raw.length;
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

  /// GET /trades/{tradeId} -> returns the complete trade, including actions.
  Future<HomeTrade> fetchTrade(String tradeId) async {
    try {
      final res = await _dio.get<dynamic>('/trades/$tradeId');
      if (res.statusCode == 401) throw const AuthFailure();
      if (res.statusCode != 200) {
        throw ServerFailure('Failed to load trade (${res.statusCode})');
      }

      final data = (res.data as Map).cast<String, dynamic>();
      final rawTrade = data['trade'] is Map
          ? (data['trade'] as Map).cast<String, dynamic>()
          : data;
      return HomeTradeModel.fromJson(rawTrade);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const NetworkFailure();
      }
      rethrow;
    }
  }

  /// GET /trades/saved/ids  → returns set of saved trade IDs.
  Future<Set<String>> fetchSavedTradeIds() async {
    try {
      final res = await _dio.get<dynamic>('/trades/saved/ids');
      if (res.statusCode == 401) throw const AuthFailure();
      if (res.statusCode == 403) return const <String>{};
      if (res.statusCode != 200) {
        throw ServerFailure(
            'Failed to load saved trade IDs (${res.statusCode})');
      }
      final data = res.data;
      if (data is! Map) {
        throw ServerFailure(
          'Failed to load saved trade IDs (unexpected response)',
        );
      }
      final raw = (data['trade_ids'] as List?) ?? const <dynamic>[];
      return raw.whereType<String>().toSet();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const NetworkFailure();
      }
      rethrow;
    }
  }

  /// GET /trades/saved  → returns list of saved trades.
  Future<List<HomeTrade>> fetchSavedTrades() async {
    try {
      final res = await _dio.get<dynamic>('/trades/saved');
      if (res.statusCode == 401) throw const AuthFailure();
      if (res.statusCode == 403) return const <HomeTrade>[];
      if (res.statusCode != 200) {
        throw ServerFailure('Failed to load saved trades (${res.statusCode})');
      }
      final data = res.data;
      if (data is! Map) {
        throw ServerFailure('Failed to load saved trades (unexpected response)');
      }
      final raw = (data['trades'] as List?) ?? const <dynamic>[];
      return raw
          .whereType<Map>()
          .map((e) => HomeTradeModel.fromJson(e.cast<String, dynamic>()))
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

  /// POST /trades/saved  → saves a trade, returns true on success.
  Future<bool> saveTrade(String tradeId) async {
    try {
      final res = await _dio.post<dynamic>(
        '/trades/saved',
        data: <String, dynamic>{'trade_id': tradeId},
      );
      if (res.statusCode == 401) throw const AuthFailure();
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw ServerFailure('Failed to save trade (${res.statusCode})');
      }
      final data = (res.data as Map?)?.cast<String, dynamic>() ?? {};
      return (data['saved'] as bool?) ?? true;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const NetworkFailure();
      }
      rethrow;
    }
  }

  /// DELETE /trades/saved/{tradeId}  → unsaves a trade, returns false on success.
  Future<bool> unsaveTrade(String tradeId) async {
    try {
      final res = await _dio.delete<dynamic>('/trades/saved/$tradeId');
      if (res.statusCode == 401) throw const AuthFailure();
      if (res.statusCode != 200 && res.statusCode != 204) {
        throw ServerFailure('Failed to unsave trade (${res.statusCode})');
      }
      final data = (res.data as Map?)?.cast<String, dynamic>() ?? {};
      return (data['saved'] as bool?) ?? false;
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

      final data = res.data;
      if (data is! Map) {
        throw ServerFailure(
          'Failed to load subscriptions (unexpected response)',
        );
      }
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

  Future<List<PaymentTransaction>> fetchPaymentTransactions() async {
    final res = await _dio.get<dynamic>(
      '/subscriptions/transactions',
      queryParameters: const <String, dynamic>{'page': 1, 'limit': 100},
    );
    if (res.statusCode != 200) {
      throw ServerFailure('Failed to load payment history (${res.statusCode})');
    }
    final data = (res.data as Map).cast<String, dynamic>();
    return ((data['transactions'] as List?) ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => PaymentTransactionModel.fromJson(
              item.cast<String, dynamic>(),
            ))
        .toList();
  }
}
