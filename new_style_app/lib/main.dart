import 'package:flutter/material.dart';
import 'pages/splash/splash.dart';
import 'theme/theme_app.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo App',
      theme: CustomTheme.lightTheme,
      darkTheme: CustomTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}