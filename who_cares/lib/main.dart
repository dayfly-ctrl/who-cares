import 'package:flutter/material.dart';
import 'pages/dashboard_page.dart';

void main() => runApp(const WhoCares());

class WhoCares extends StatelessWidget {
  const WhoCares({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'who cares?',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF7300),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}
