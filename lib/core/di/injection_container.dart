import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import '../../features/market/data/repositories/market_repository_impl.dart';
import '../../features/market/data/sources/market_remote_data_source.dart';
import '../../features/watchlist/data/repositories/watchlist_repository_impl.dart';
import '../../features/watchlist/data/sources/watchlist_remote_data_source.dart';
import '../../features/auth/data/repository/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/subscriptions/data/repository/subscription_repository.dart';
import '../../features/subscriptions/presentation/cubit/subscription_cubit.dart';
import '../network/api_client.dart';
import '../../features/auth/data/api/auth_api.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core
  sl.registerLazySingleton(() => Logger());
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => ApiClient(
        dio: sl(),
        storage: sl(),
        logger: sl(),
      ));

  // Data Sources
  sl.registerLazySingleton<MarketRemoteDataSource>(
    () => MarketRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<WatchlistRemoteDataSource>(
    () => WatchlistRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<MarketRepository>(
    () => MarketRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<WatchlistRepository>(
    () => WatchlistRepositoryImpl(sl()),
  );

  // Auth
  sl.registerLazySingleton(() => AuthApi());
  sl.registerLazySingleton(() => AuthRepository(api: sl()));
  sl.registerFactory(() => AuthCubit(repository: sl()));

  // Subscriptions
  sl.registerLazySingleton(() => SubscriptionRepository());
  sl.registerFactory(() => SubscriptionCubit(repository: sl()));
}
