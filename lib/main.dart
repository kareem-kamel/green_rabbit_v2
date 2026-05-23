import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:green_rabbit/core/theme/app_theme.dart';
import 'package:green_rabbit/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:green_rabbit/features/auth/presentation/cubit/auth_state.dart';
import 'package:green_rabbit/features/auth/presentation/screens/login_screen.dart';
import 'package:green_rabbit/features/subscriptions/presentation/cubit/subscription_cubit.dart';
import 'package:green_rabbit/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:green_rabbit/features/profile/presentation/cubit/settings_cubit.dart';
import 'package:green_rabbit/features/news/presentation/cubit/news_cubit.dart';
import 'package:green_rabbit/features/news/presentation/cubit/related_news_cubit.dart';
import 'package:green_rabbit/features/chatbot/presentation/cubit/chat_cubit.dart';
import 'package:green_rabbit/features/alerts/presentation/cubit/alert_cubit.dart';
import 'package:green_rabbit/features/calendar/presentation/cubit/calendar_cubit.dart';
import 'package:green_rabbit/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:green_rabbit/features/news/presentation/screens/deep_link_article_handler.dart';

import 'package:green_rabbit/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'core/network/api_client.dart';
import 'package:green_rabbit/shared/widgets/main_wrapper.dart';
import 'core/di/injection_container.dart' as di;

final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");
  await di.init();

  // Set up 401 Unauthorized handler to automatically logout and redirect to login screen
  di.sl<ApiClient>().onUnauthorized = () {
    final context = globalNavigatorKey.currentContext;
    if (context != null) {
      try {
        BlocProvider.of<AuthCubit>(context).logout();
      } catch (e) {
        debugPrint("Error performing automatic logout: $e");
      }
    }
  };

  runApp(const ProviderScope(child: GreenRabbitApp()));
}

class GreenRabbitApp extends StatelessWidget {
  const GreenRabbitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SubscriptionCubit>(
          create: (context) => di.sl<SubscriptionCubit>()..init(),
        ),
        BlocProvider<ProfileCubit>(create: (context) => di.sl<ProfileCubit>()),
        BlocProvider<SettingsCubit>(create: (context) => SettingsCubit()),
        BlocProvider<NewsCubit>(create: (context) => di.sl<NewsCubit>()),
        BlocProvider<RelatedNewsCubit>(
          create: (context) => di.sl<RelatedNewsCubit>(),
        ),
        BlocProvider<ChatCubit>(create: (context) => di.sl<ChatCubit>()),
        BlocProvider<AlertCubit>(create: (context) => di.sl<AlertCubit>()),
        BlocProvider<CalendarCubit>(create: (context) => di.sl<CalendarCubit>()),
        BlocProvider<NotificationCubit>(create: (context) => di.sl<NotificationCubit>()),
        BlocProvider<AuthCubit>(create: (context) => di.sl<AuthCubit>()..checkAuth()),
      ],

      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          return MaterialApp(
            navigatorKey: globalNavigatorKey,
            title: 'Green Rabbit News',
            debugShowCheckedModeBanner: false,
            themeMode: settingsState.lightModeEnabled
                ? ThemeMode.light
                : ThemeMode.dark,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            builder: (context, child) {
              return child ?? const SizedBox.shrink();
            },

            // 👇 Use a BlocBuilder here to decide the home page
            home: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                if (state is AuthChecking) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state is AuthFirstTime) {
                  return const OnboardingScreen(); // ONLY for first install
                }

                if (state is AuthSuccess) {
                  return const MainWrapper(); // Directly to Dashboard
                }

                // Default case: show Login (not onboarding)
                // We show this for AuthInitial, AuthFailure, and AuthLoading.
                return const LoginScreen(isFromSignup: false);
              },
            ),
            onGenerateRoute: (settings) {
              if (settings.name != null &&
                  settings.name!.startsWith('/article')) {
                final uri = Uri.parse(settings.name!);
                final id = uri.queryParameters['id'];

                if (id != null) {
                  return MaterialPageRoute(
                    builder: (context) => DeepLinkArticleHandler(articleId: id),
                  );
                }
              }

              return null;
            },
          );
        },
      ),
    );
  }
}
