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
import '../../features/news/data/repositories/news_repository.dart';
import '../../features/news/presentation/cubit/news_cubit.dart';
import '../../features/news/presentation/cubit/related_news_cubit.dart';
import '../../features/news/presentation/cubit/news_summary_cubit.dart';
import '../network/api_client.dart';
import '../../features/profile/data/sources/profile_remote_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../features/profile/presentation/cubit/settings_cubit.dart';
import '../../features/auth/data/api/auth_api.dart';
import '../../features/chatbot/data/repository/chatbot_repository.dart';
import '../../features/chatbot/data/services/ai_service.dart';
import '../../features/chatbot/presentation/cubit/chat_cubit.dart';
import '../../features/alerts/data/repository/alert_repository.dart';
import '../../features/alerts/presentation/cubit/alert_cubit.dart';
import '../../features/calendar/data/sources/calendar_remote_data_source.dart';
import '../../features/calendar/data/repositories/calendar_repository_impl.dart';
import '../../features/calendar/presentation/cubit/calendar_cubit.dart';
import '../../features/notifications/data/repositories/notification_repository.dart';
import '../../features/notifications/presentation/cubit/notification_cubit.dart';

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
  sl.registerLazySingleton(() => SubscriptionRepository());
  sl.registerFactory<SubscriptionCubit>(
    () => SubscriptionCubit(repository: sl<SubscriptionRepository>()),
  );

  // Profile
  sl.registerFactory<ProfileCubit>(
    () => ProfileCubit(repository: sl<ProfileRepository>()),
  );
  sl.registerFactory<SettingsCubit>(() => SettingsCubit());

  // News
  // NewsRepository is already registered above as a lazy singleton
  sl.registerFactory(() => NewsCubit(repository: sl()));
  sl.registerFactory(() => RelatedNewsCubit(repository: sl()));
  sl.registerFactory(() => NewsSummaryCubit(sl()));

  // AI & Chatbot
  sl.registerLazySingleton(() => AIService(sl<ApiClient>()));
  sl.registerLazySingleton(() => ChatbotRepository(sl()));
  sl.registerFactory(() => ChatCubit(repository: sl()));

  // Alerts
  sl.registerLazySingleton(() => AlertRepository(sl<ApiClient>()));
  sl.registerFactory(() => AlertCubit(repository: sl()));

  // Notifications
  sl.registerLazySingleton(() => NotificationRepository(sl<ApiClient>()));
  sl.registerFactory(() => NotificationCubit(repository: sl()));

  // Calendar
  sl.registerLazySingleton<CalendarRemoteDataSource>(
    () => CalendarRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<CalendarRepository>(
    () => CalendarRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerFactory(() => CalendarCubit(repository: sl()));
}
