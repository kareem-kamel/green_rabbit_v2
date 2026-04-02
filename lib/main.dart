import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_rabbit/core/theme/app_theme.dart';
import 'package:green_rabbit/features/auth/data/api/auth_api.dart';
import 'package:green_rabbit/features/auth/data/repository/auth_repository.dart';
import 'package:green_rabbit/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:green_rabbit/features/auth/presentation/screens/preferences_screen.dart';
import 'package:green_rabbit/features/auth/presentation/screens/register_screen.dart';
import 'package:green_rabbit/features/onboarding/presentation/screens/onboarding_screen.dart';

void main() {
  runApp(const GreenRabbitApp());
}

class GreenRabbitApp extends StatelessWidget {
  const GreenRabbitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthCubit(
        repository: AuthRepository(
          api: AuthApi(),
        ),
      ),
      child: MaterialApp(
        title: 'Green Rabbit News',
        debugShowCheckedModeBanner: false,
        theme: darkTheme,
        home: const RegisterScreen(),
      ),
    );
  }
}
