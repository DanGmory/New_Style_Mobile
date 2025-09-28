import 'package:flutter/material.dart';
import '../models/features_page.dart';
import '../models/register_model.dart';
import '../config/features.dart';

class CustomDrawer extends StatelessWidget {
  final String username;
  final Function(int) onItemSelected;
  final VoidCallback onLogout;
  final int currentIndex;
  final ApiUser? user;

  const CustomDrawer({
    super.key,
    required this.username,
    required this.onItemSelected,
    required this.onLogout,
    required this.currentIndex,
    this.user,
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
            child: Icon(Icons.person, size: 40, color: theme.iconTheme.color),
          ),
          const SizedBox(height: 15),
          Text(
            username,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          Text(
            "",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context, ThemeData theme) {
    // Generar features dinámicamente si el usuario está disponible
    List<FeaturePage> features = [];
    if (user != null) {
      features = buildFeatures(user!);
    }

    return Column(
      children: [
        // Features principales
        ...features.asMap().entries.map((entry) {
          final index = entry.key;
          final feature = entry.value;
          return _buildListTile(
            theme,
            feature.icon,
            feature.title,
            index,
            currentIndex == index,
          );
        }),

        const Divider(),

        // Elementos especiales
        _buildListTile(theme, Icons.notifications, 'Notificaciones', -1, false),
        _buildListTile(theme, Icons.help, 'Ayuda', -2, false),
        _buildListTile(theme, Icons.info, 'Acerca de', -3, false),
        const Divider(),
        _buildLogoutTile(context, theme),
      ],
    );
  }

  Widget _buildListTile(
    ThemeData theme,
    IconData icon,
    String title,
    int index,
    bool isSelected,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? theme.colorScheme.primary : theme.iconTheme.color,
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
