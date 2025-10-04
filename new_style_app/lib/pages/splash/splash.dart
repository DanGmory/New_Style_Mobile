import 'dart:async';
import 'package:flutter/material.dart';
import '../auth/login.dart';
import '../../services/theme_service.dart';

class SplashScreen extends StatefulWidget {
  final ThemeService themeService;

  const SplashScreen({super.key, required this.themeService});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();

    _navigationTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        // ✅ Evita error si el widget ya fue desmontado
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                LoginScreen(themeService: widget.themeService),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _navigationTimer?.cancel(); // ✅ Cancelar el timer al hacer dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // 👉 obtenemos el tema actual

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // usa el fondo del tema
      extendBodyBehindAppBar: true,
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/img/icons/logo.png', height: 100),
              const SizedBox(height: 20),
              Text(
                'New Style App',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              CircularProgressIndicator(
                color: theme.colorScheme.primary, // color dinámico del tema
              ),
            ],
          ),
        ),
      ),
    );
  }
}
