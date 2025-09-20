import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  final String username;
  final Function(int) onItemSelected;
  final VoidCallback onLogout;
  final int currentIndex;

  const CustomDrawer({
    super.key,
    required this.username,
    required this.onItemSelected,
    required this.onLogout,
    required this.currentIndex,
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
            theme.primaryColor.withOpacity(0.8),
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
              Icons.person,
              size: 40,
              color: theme.iconTheme.color,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            username,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          Text(
            'usuario@demo.com',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        _buildListTile(
          theme,
          Icons.home,
          'Inicio',
          0,
          currentIndex == 0,
        ),
        _buildListTile(
          theme,
          Icons.person,
          'Mi Perfil',
          1,
          currentIndex == 1,
        ),
        _buildListTile(
          theme,
          Icons.settings,
          'Configuración',
          2,
          currentIndex == 2,
        ),
        const Divider(),
        _buildListTile(
          theme,
          Icons.notifications,
          'Notificaciones',
          3,
          false,
        ),
        _buildListTile(
          theme,
          Icons.help,
          'Ayuda',
          4,
          false,
        ),
        _buildListTile(
          theme,
          Icons.info,
          'Acerca de',
          5,
          false,
        ),
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
      selectedTileColor: theme.colorScheme.primary.withOpacity(0.1),
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