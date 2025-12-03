import 'package:flutter/material.dart';
import '../pages/home/inicio.dart';
import '../pages/products/products.dart';
import '../pages/cart/cart.dart';
import '../pages/user/user.dart';
import '../pages/auth/login.dart';
import '../pages/settings/settings.dart';
import '../services/theme_service.dart';
import '../models/register_model.dart';
import '../models/features_page.dart';

List<FeaturePage> buildFeatures(
  ApiUser? user, {
  VoidCallback? onNavigateToProducts,
  required ThemeService themeService,
}) {
  return [
    FeaturePage(
      title: 'Inicio',
      icon: Icons.home,
      page: InicioScreen(
        onNavigateToProducts: onNavigateToProducts,
        user: user,
      ),
    ),
    const FeaturePage(
      title: 'Productos',
      icon: Icons.shopping_bag,
      page: ProductScreen(),
    ),
    const FeaturePage(
      title: 'Carrito',
      icon: Icons.shopping_cart,
      page: CartScreen(),
    ),
    if (user != null)
      FeaturePage(
        title: 'Mi Perfil',
        icon: Icons.person,
        page: UserScreen(user: user),
      )
    else
      FeaturePage(
        title: 'Mi Perfil',
        icon: Icons.person,
        page: LoginScreen(themeService: themeService),
      ),
    FeaturePage(
      title: 'Configuración',
      icon: Icons.settings,
      page: SettingsScreen(themeService: themeService),
    ),
  ];
}
