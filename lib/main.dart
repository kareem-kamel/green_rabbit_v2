import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:green_rabbit/core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/network/api_client.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/market/data/sources/market_remote_data_source.dart';
import 'features/market/data/repositories/market_repository_impl.dart';
import 'features/watchlist/data/sources/watchlist_remote_data_source.dart';
import 'features/watchlist/data/repositories/watchlist_repository_impl.dart';

final sl = GetIt.instance;

Future<void> _setupServiceLocator() async {
  sl.registerLazySingleton<FlutterSecureStorage>(() => const FlutterSecureStorage());
  sl.registerLazySingleton<Logger>(() => Logger());
  sl.registerLazySingleton<Dio>(() => Dio());
  sl.registerLazySingleton<ApiClient>(() => ApiClient(
        dio: sl(),
        storage: sl(),
        logger: sl(),
      ));

  // Data Sources
  sl.registerLazySingleton<MarketRemoteDataSource>(() => MarketRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<WatchlistRemoteDataSource>(() => WatchlistRemoteDataSourceImpl(sl()));

  // Repositories
  sl.registerLazySingleton<MarketRepository>(() => MarketRepositoryImpl(sl()));
  sl.registerLazySingleton<WatchlistRepository>(() => WatchlistRepositoryImpl(sl()));
}

// Provider to manage ThemeMode (Light/Dark/System)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _setupServiceLocator();
  
  runApp(
    // Riverpod context
    const ProviderScope(
      child: GreenRabbitApp(),
    ),
  );
}

class GreenRabbitApp extends ConsumerWidget {
  const GreenRabbitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    return MultiBlocProvider(
      providers: [
        // Auth Cubit initialization
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit()..checkAuth(),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        
        // Theme Configuration
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        
        // Routing (Simplified for Foundation Phase)
        home: const SplashPage(),
      ),
    );
  }
}
