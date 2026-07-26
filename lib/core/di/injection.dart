import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/login_bloc.dart';
import '../../features/home/data/datasources/home_remote_data_source.dart';
import '../../features/home/data/datasources/market_data_remote_data_source.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/discover/data/datasources/discover_remote_data_source.dart';
import '../../features/discover/data/repositories/discover_repository_impl.dart';
import '../../features/discover/domain/repositories/discover_repository.dart';
import '../../features/discover/presentation/bloc/discover_bloc.dart';
import '../network/api_client.dart';
import '../network/device_id.dart';
import '../network/request_signer.dart';
import '../network/websocket_service.dart';
import '../services/live_prices_service.dart';
import '../storage/secure_storage.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies({
  void Function()? onSessionExpired,
}) async {
  if (getIt.isRegistered<SecureStorage>()) return;

  final storage = SecureStorage();
  final deviceIds = DeviceIdProvider(storage);
  final signer = await EcdsaRequestSigner.loadDev();
  final dio = buildDio(

    signer: signer,
    deviceIds: deviceIds,
    storage: storage,
    onSessionExpired: onSessionExpired,
  );

  getIt
    ..registerSingleton<SecureStorage>(storage)
    ..registerSingleton<DeviceIdProvider>(deviceIds)
    ..registerSingleton<RequestSigner>(signer)
    ..registerSingleton<Dio>(dio)
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(dio: getIt<Dio>(), storage: getIt<SecureStorage>()),
    )
    ..registerLazySingleton<HomeRemoteDataSource>(
      () => HomeRemoteDataSource(getIt<Dio>()),
    )
    ..registerLazySingleton<HomeRepository>(
      () => HomeRepositoryImpl(getIt<HomeRemoteDataSource>()),
    )
    ..registerLazySingleton<MarketDataRemoteDataSource>(
      () => MarketDataRemoteDataSource(getIt<Dio>()),
    )
    ..registerLazySingleton<WebSocketService>(
      () => WebSocketService(
        authRepository: getIt<AuthRepository>(),
        storage: getIt<SecureStorage>(),
      ),
    )
    ..registerLazySingleton<LivePricesService>(
      () => LivePricesService(
        webSocket: getIt<WebSocketService>(),
        marketData: getIt<MarketDataRemoteDataSource>(),
      ),
    )
    ..registerFactory<LoginBloc>(
      () => LoginBloc(authRepository: getIt<AuthRepository>()),
    )
    ..registerFactory<HomeBloc>(
      () => HomeBloc(
        repository: getIt<HomeRepository>(),
        authRepository: getIt<AuthRepository>(),
        livePrices: getIt<LivePricesService>(),
        webSocket: getIt<WebSocketService>(),
      ),
    )
    ..registerLazySingleton<DiscoverRemoteDataSource>(
      () => DiscoverRemoteDataSource(getIt<Dio>()),
    )
    ..registerLazySingleton<DiscoverRepository>(
      () => DiscoverRepositoryImpl(getIt<DiscoverRemoteDataSource>()),
    )
    ..registerFactory<DiscoverBloc>(
      () => DiscoverBloc(repository: getIt<DiscoverRepository>()),
    );
}
