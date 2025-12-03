import 'package:flutter/material.dart';
import '../models/features_page.dart';
import '../models/register_model.dart';
import '../config/features.dart';
import '../services/theme_service.dart';

class CustomDrawer extends StatelessWidget {
  final String username;
  final Function(int) onItemSelected;
  final VoidCallback onLogout;
  final VoidCallback? onLogin; // NUEVO
  final int currentIndex;
  final ApiUser? user;
  final ThemeService themeService;
  final bool isLoggedIn; // NUEVO

  const CustomDrawer({
    super.key,
    required this.username,
    required this.onItemSelected,
    required this.onLogout,
    this.onLogin, // NUEVO
    required this.currentIndex,
    required this.themeService,
    this.user,
    this.isLoggedIn = false, // NUEVO - Por defecto false
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(context, theme),
          _buildMenuItems(context, theme),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return DrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor,
            theme.primaryColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: theme.colorScheme.surface,
            child: Icon(
              isLoggedIn ? Icons.person : Icons.person_outline,
              size: 40,
              color: theme.iconTheme.color,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            username,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // NUEVO: Mostrar email o botón de login
          if (isLoggedIn && user?.email != null)
            Text(
              user!.email,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
              ),
              overflow: TextOverflow.ellipsis,
            )
          else if (!isLoggedIn)
            InkWell(
              onTap: () {
                Navigator.pop(context); // Cerrar drawer
                onLogin?.call();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.login,
                      size: 16,
                      color: theme.colorScheme.onPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Iniciar sesión',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context, ThemeData theme) {
    // Generar features dinámicamente
    List<FeaturePage> features = [];
    
    // MODIFICADO: Pasar user (puede ser null)
    if (user != null) {
      features = buildFeatures(user!, themeService: themeService);
    } else {
      // Features básicas para invitados (sin carrito, perfil, etc)
      features = buildFeatures(
        null, // NUEVO: Soportar null
        themeService: themeService,
      );
    }

    return Column(
      children: [
        // Features principales
        ...features.asMap().entries.map((entry) {
          final index = entry.key;
          final feature = entry.value;
          final requiresLogin = _requiresLogin(index);
          
          return _buildListTile(
            theme,
            feature.icon,
            feature.title,
            index,
            currentIndex == index,
            requiresLogin: requiresLogin,
            isLocked: requiresLogin && !isLoggedIn,
          );
        }),

        const Divider(),

        // Elementos especiales (siempre visibles)
        _buildListTile(
          theme,
          Icons.notifications,
          'Notificaciones',
          -1,
          false,
        ),
        _buildListTile(theme, Icons.help, 'Ayuda', -2, false),
        _buildListTile(theme, Icons.info, 'Acerca de', -3, false),
        
        const Divider(),
        
        // NUEVO: Botón de login o logout según estado
        if (isLoggedIn)
          _buildLogoutTile(context, theme)
        else
          _buildLoginTile(context, theme),
      ],
    );
  }

  // NUEVO: Determinar qué páginas requieren login
  bool _requiresLogin(int index) {
    // Índice 2 = Carrito
    // Índice 3 = Mi Perfil
    // Puedes agregar más según tu app
    return index == 2 || index == 3;
  }

  Widget _buildListTile(
    ThemeData theme,
    IconData icon,
    String title,
    int index,
    bool isSelected, {
    bool requiresLogin = false,
    bool isLocked = false,
  }) {
    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? theme.colorScheme.primary : theme.iconTheme.color,
          ),
          if (isLocked) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.lock_outline,
              size: 16,
              color: theme.colorScheme.error.withValues(alpha: 0.7),
            ),
          ],
        ],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.textTheme.bodyMedium?.color,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.arrow_forward,
              color: theme.colorScheme.primary,
              size: 20,
            )
          : null,
      onTap: () => onItemSelected(index),
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
    );
  }

  // NUEVO: Tile para login
  Widget _buildLoginTile(BuildContext context, ThemeData theme) {
    return ListTile(
      leading: Icon(Icons.login, color: theme.colorScheme.primary),
      title: Text(
        'Iniciar Sesión',
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Cierra el drawer
        onLogin?.call();
      },
    );
  }

  Widget _buildLogoutTile(BuildContext context, ThemeData theme) {
    return ListTile(
      leading: Icon(Icons.logout, color: theme.colorScheme.error),
      title: Text(
        'Cerrar Sesión',
        style: TextStyle(color: theme.colorScheme.error),
      ),
      onTap: () {
        Navigator.pop(context); // Cierra el drawer
        onLogout();
      },
    );
  }
}