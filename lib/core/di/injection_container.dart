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
import '../../features/profile/data/sources/profile_remote_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../features/news/data/repositories/news_repository.dart';
import '../../features/news/presentation/cubit/news_cubit.dart';
// import '../../features/auth/data/api/auth_api.dart'; // You don't need this anymore!

final sl = GetIt.instance;

Future<void> init() async {
  // Core
  sl.registerLazySingleton<Logger>(() => Logger());
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  sl.registerLazySingleton<Dio>(() => Dio());

  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(
      dio: sl<Dio>(),
      storage: sl<FlutterSecureStorage>(),
      logger: sl<Logger>(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<MarketRemoteDataSource>(
    () => MarketRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<WatchlistRemoteDataSource>(
    () => WatchlistRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<MarketRepository>(() => MarketRepositoryImpl(sl()));
  sl.registerLazySingleton<WatchlistRepository>(
    () => WatchlistRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<NewsRepository>(() => NewsRepository(sl()));

  // Auth
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      apiClient: sl<ApiClient>(),
      storage: sl<FlutterSecureStorage>(),
    ),
  );

  sl.registerFactory<AuthCubit>(
    () => AuthCubit(repository: sl<AuthRepository>()),
  );

  // Subscriptions
  sl.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepository(),
  );

  sl.registerFactory<SubscriptionCubit>(
    () => SubscriptionCubit(repository: sl<SubscriptionRepository>()),
  );

  sl.registerFactory<ProfileCubit>(
    () => ProfileCubit(repository: sl<ProfileRepository>()),
  );

  sl.registerFactory<NewsCubit>(
    () => NewsCubit(sl<NewsRepository>()),
  );
}
