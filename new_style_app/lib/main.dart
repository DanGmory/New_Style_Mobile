import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'pages/splash/splash.dart';
import 'pages/home/home.dart';
import 'theme/theme_app.dart';
import 'services/theme_service.dart';
import 'models/register_model.dart';
import 'services/logger_service.dart';

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
      // Cambiado: Ahora usa AppInitializer en lugar de ir directo al Splash
      home: AppInitializer(themeService: widget.themeService),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Widget que inicializa la app y decide la pantalla inicial
class AppInitializer extends StatefulWidget {
  final ThemeService themeService;
  
  const AppInitializer({super.key, required this.themeService});
  
  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitializing = true;
  ApiUser? _storedUser;
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  Future<void> _initialize() async {
    try {
      // Mostrar splash por al menos 1.5 segundos (UX)
      await Future.wait([
        _checkStoredSession(),
        Future.delayed(const Duration(milliseconds: 1500)),
      ]);
      
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      LoggerService.error('Error inicializando app', e);
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }
  
  /// Verifica si hay una sesión guardada previamente
  Future<void> _checkStoredSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_session');
      
      if (userJson != null) {
        final userMap = json.decode(userJson) as Map<String, dynamic>;
        _storedUser = ApiUser.fromJson(userMap);
        
        LoggerService.info('Sesión encontrada: ${_storedUser!.name}');
      } else {
        LoggerService.info('No hay sesión guardada - Modo invitado');
      }
    } catch (e) {
      LoggerService.error('Error al cargar sesión guardada', e);
      _storedUser = null;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Mostrar splash mientras inicializa
    if (_isInitializing) {
      return SplashScreen(themeService: widget.themeService);
    }
    
    // Después de inicializar, ir SIEMPRE al Home
    // El usuario puede ser null (invitado) o tener sesión activa
    return HomeScreen(
      user: _storedUser, // Puede ser null para modo invitado
      themeService: widget.themeService,
    );
  }
}