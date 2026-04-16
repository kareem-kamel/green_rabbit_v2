import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:green_rabbit/core/theme/app_theme.dart';
import 'package:green_rabbit/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:green_rabbit/features/subscriptions/presentation/cubit/subscription_cubit.dart';
import 'package:green_rabbit/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:green_rabbit/features/profile/presentation/cubit/settings_cubit.dart';

import 'package:green_rabbit/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'core/di/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await di.init();
  runApp(
    const ProviderScope(
      child: GreenRabbitApp(),
    ),
  );
}

class GreenRabbitApp extends StatelessWidget {
  const GreenRabbitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => di.sl<AuthCubit>(),
        ),
        BlocProvider<SubscriptionCubit>(
          create: (context) => di.sl<SubscriptionCubit>()..init(),
        ),
        BlocProvider<ProfileCubit>(
          create: (context) => di.sl<ProfileCubit>()..getProfile(),
        ),
        BlocProvider<SettingsCubit>(
          create: (context) => SettingsCubit(),
        ),
      ],


      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'Green Rabbit News',
            debugShowCheckedModeBanner: false,
            themeMode: state.lightModeEnabled ? ThemeMode.light : ThemeMode.dark,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const OnboardingScreen(),
          );
        },
      ),
    );

  }
}
