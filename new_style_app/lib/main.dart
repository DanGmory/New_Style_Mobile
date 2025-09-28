import 'package:flutter/material.dart';
import 'pages/splash/splash.dart';
import 'theme/theme_app.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar el servicio de tema
  final themeService = ThemeService();
  await themeService.initialize();

  runApp(MyApp(themeService: themeService));
}

class MyApp extends StatefulWidget {
  final ThemeService themeService;

  const MyApp({super.key, required this.themeService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Escuchar cambios en el tema
    widget.themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    widget.themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'New Style App',
      theme: CustomTheme.lightTheme,
      darkTheme: CustomTheme.darkTheme,
      themeMode: widget.themeService.themeMode,
      home: SplashScreen(themeService: widget.themeService),
      debugShowCheckedModeBanner: false,
    );
  }
}
