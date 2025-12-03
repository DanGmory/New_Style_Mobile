import 'package:flutter/material.dart';
import '/pages/home/inicio.dart';
import '/pages/products/products.dart';
import '/pages/cart/cart.dart';
import '/pages/user/user.dart';
import '/pages/settings/settings.dart';
import '/services/theme_service.dart';
import '/models/register_model.dart';
import '/models/features_page.dart';

// MODIFICADO: Ahora acepta ApiUser nullable
List<FeaturePage> buildFeatures(
  ApiUser? user, {
  VoidCallback? onNavigateToProducts,
  required ThemeService themeService,
}) {
  // Si NO hay usuario (invitado), retornar solo las features públicas
  if (user == null) {
    return [
      FeaturePage(
        title: 'Inicio',
        icon: Icons.home,
        page: InicioScreen(
          onNavigateToProducts: onNavigateToProducts,
          user: null, // Pasar null explícitamente
        ),
      ),
      const FeaturePage(
        title: 'Productos',
        icon: Icons.shopping_bag,
        page: ProductScreen(),
      ),
      // NOTA: Carrito, Perfil y otras páginas protegidas NO se incluyen
      // Esto evita que aparezcan en el BottomNavigationBar para invitados
      
      // Configuración es accesible para todos
      FeaturePage(
        title: 'Configuración',
        icon: Icons.settings,
        page: SettingsScreen(themeService: themeService),
      ),
    ];
  }

  // Si HAY usuario, retornar todas las features
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
    FeaturePage(
      title: 'Mi Perfil',
      icon: Icons.person,
      page: UserScreen(user: user),
    ),
    FeaturePage(
      title: 'Configuración',
      icon: Icons.settings,
      page: SettingsScreen(themeService: themeService),
    ),
  ];
}

// NUEVO: Helper para obtener el índice del carrito según el estado
int getCartPageIndex(bool isLoggedIn) {
  return isLoggedIn ? 2 : -1; // -1 significa "no disponible"
}

// NUEVO: Helper para obtener el índice del perfil
int getProfilePageIndex(bool isLoggedIn) {
  return isLoggedIn ? 3 : -1;
}

// NUEVO: Helper para verificar si una página requiere login
bool pageRequiresLogin(int pageIndex, bool isLoggedIn) {
  if (!isLoggedIn) {
    // Para invitados, solo página 0 (inicio) y 1 (productos) son accesibles
    return pageIndex > 1;
  }
  return false;
}