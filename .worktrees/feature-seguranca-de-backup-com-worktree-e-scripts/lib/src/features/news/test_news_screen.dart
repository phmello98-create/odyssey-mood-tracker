import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/news/presentation/news_screen.dart';

void main() {
  runApp(const ProviderScope(child: TestNewsApp()));
}

class TestNewsApp extends StatelessWidget {
  const TestNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test News Screen',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const NewsScreen(),
    );
  }
}
