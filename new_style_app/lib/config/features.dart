import 'package:flutter/material.dart';
import '../pages/home/inicio.dart';
import '../pages/products/products.dart';
import '../pages/cart/cart.dart';
import '../pages/user/user.dart';
import '../pages/auth/change_password.dart';
import '../models/register_model.dart';
import '../models/features_page.dart';

List<FeaturePage> buildFeatures(
  ApiUser user, {
  VoidCallback? onNavigateToProducts,
}) {
  return [
    FeaturePage(
      title: 'Inicio',
      icon: Icons.home,
      page: InicioScreen(onNavigateToProducts: onNavigateToProducts),
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
    const FeaturePage(
      title: 'Configuración',
      icon: Icons.settings,
      page: ChangePasswordScreen(),
    ),
  ];
}
