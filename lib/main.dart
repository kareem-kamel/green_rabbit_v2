import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/news/data/repositories/news_repository.dart';
import 'features/news/presentation/cubit/news_cubit.dart';
import 'features/news/presentation/widgets/main_screen.dart';

void main() {
  final newsRepository = NewsRepository();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<NewsCubit>(
          // This ".." triggers the API call immediately
          create: (context) => NewsCubit(newsRepository)..fetchNewsFeed(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MainScreen(), 
    );
  }
}