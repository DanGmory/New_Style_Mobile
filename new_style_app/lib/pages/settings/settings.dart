import 'package:flutter/material.dart';
import '../../widgets/appbar.dart';
import '../../services/theme_service.dart';
import '../auth/change_password.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeService themeService;

  const SettingsScreen({super.key, required this.themeService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Configuraciones',
        showBackButton: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apariencia',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Tarjeta de configuración de tema
            Card(
              elevation: 2,
              child: ListTile(
                leading: Icon(
                  widget.themeService.isDarkMode
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  'Tema de la aplicación',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  widget.themeService.isDarkMode ? 'Tema oscuro' : 'Tema claro',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                trailing: Switch(
                  value: widget.themeService.isDarkMode,
                  onChanged: (value) {
                    widget.themeService.toggleTheme();
                    setState(() {});
                  },
                  activeTrackColor: theme.colorScheme.primary,
                ),
              ),
            ),

            const SizedBox(height: 32),

            Text(
              'Seguridad',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Tarjeta de cambio de contraseña
            Card(
              elevation: 2,
              child: ListTile(
                leading: Icon(
                  Icons.lock_outline,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  'Cambiar contraseña',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Actualiza tu contraseña de acceso',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 16,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            Text(
              'Información',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Tarjeta de información de la app
            Card(
              elevation: 2,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      'Acerca de la aplicación',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'New Style App v1.0.0',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.help_outline,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      'Ayuda y soporte',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Contacta con nuestro equipo',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      size: 16,
                    ),
                    onTap: () {
                      _showSupportDialog(context);
                    },
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Footer con información adicional
            Center(
              child: Text(
                'New Style App © 2025',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ayuda y Soporte'),
          content: const Text(
            'Para obtener ayuda, puedes contactarnos a través de:\n\n'
            '• Email: soporte@newstyle.app\n'
            '• Teléfono: +1 234 567 8900\n'
            '• WhatsApp: +1 234 567 8900',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}
