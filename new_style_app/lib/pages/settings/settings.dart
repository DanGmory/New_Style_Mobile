import 'package:flutter/material.dart';
import '../../services/theme_service.dart';

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con título
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.settings_outlined,
                    size: 48,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Configuración',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Personaliza tu experiencia',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Sección de Tema
            _buildSectionCard(
              context,
              'Apariencia',
              Icons.palette_outlined,
              [
                _buildThemeSwitchTile(context),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Sección de Notificaciones
            _buildSectionCard(
              context,
              'Notificaciones',
              Icons.notifications_outlined,
              [
                _buildDevelopmentTile(
                  context,
                  'Notificaciones Push',
                  'Recibe alertas de nuevos productos y ofertas',
                  Icons.notifications_active_outlined,
                ),
                _buildDevelopmentTile(
                  context,
                  'Notificaciones por Email',
                  'Recibe noticias y promociones por correo',
                  Icons.email_outlined,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Sección de Cuenta
            _buildSectionCard(
              context,
              'Mi Cuenta',
              Icons.person_outline,
              [
                _buildDevelopmentTile(
                  context,
                  'Información Personal',
                  'Edita tu perfil y datos personales',
                  Icons.edit_outlined,
                ),
                _buildDevelopmentTile(
                  context,
                  'Cambiar Contraseña',
                  'Actualiza tu contraseña de acceso',
                  Icons.lock_outline,
                ),
                _buildDevelopmentTile(
                  context,
                  'Direcciones de Envío',
                  'Gestiona tus direcciones guardadas',
                  Icons.location_on_outlined,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Sección de Privacidad
            _buildSectionCard(
              context,
              'Privacidad y Seguridad',
              Icons.security_outlined,
              [
                _buildDevelopmentTile(
                  context,
                  'Política de Privacidad',
                  'Lee nuestra política de privacidad',
                  Icons.privacy_tip_outlined,
                ),
                _buildDevelopmentTile(
                  context,
                  'Términos y Condiciones',
                  'Consulta los términos de uso',
                  Icons.description_outlined,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Sección de Ayuda
            _buildSectionCard(
              context,
              'Ayuda y Soporte',
              Icons.help_outline,
              [
                _buildDevelopmentTile(
                  context,
                  'Centro de Ayuda',
                  'Encuentra respuestas a preguntas frecuentes',
                  Icons.help_center_outlined,
                ),
                _buildDevelopmentTile(
                  context,
                  'Contactar Soporte',
                  'Ponte en contacto con nuestro equipo',
                  Icons.support_agent_outlined,
                ),
                _buildDevelopmentTile(
                  context,
                  'Reportar Problema',
                  'Informa sobre errores o problemas',
                  Icons.bug_report_outlined,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Información de la App
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'New Style App',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Versión 1.0.0',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '© 2025 New Style Mobile',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionCard(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la sección
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: theme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Contenido de la sección
          ...children,
        ],
      ),
    );
  }
  
  Widget _buildThemeSwitchTile(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Icon(
        widget.themeService.isDarkMode 
            ? Icons.dark_mode_outlined 
            : Icons.light_mode_outlined,
        color: theme.primaryColor,
      ),
      title: Text(
        'Modo Oscuro',
        style: theme.textTheme.bodyLarge,
      ),
      subtitle: Text(
        widget.themeService.isDarkMode 
            ? 'Tema oscuro activado' 
            : 'Tema claro activado',
        style: theme.textTheme.bodyMedium,
      ),
      trailing: Switch(
        value: widget.themeService.isDarkMode,
        onChanged: (value) async {
          await widget.themeService.toggleTheme();
          setState(() {});
        },
        activeTrackColor: theme.primaryColor,
        activeThumbColor: Colors.white,
      ),
    );
  }
  
  Widget _buildDevelopmentTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Icon(
        icon,
        color: theme.primaryColor,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge,
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodyMedium,
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Próximamente',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      onTap: () {
        _showDevelopmentDialog(context, title);
      },
    );
  }
  
  void _showDevelopmentDialog(BuildContext context, String featureName) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogTheme.backgroundColor ?? theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.construction_outlined,
              color: theme.primaryColor,
            ),
            const SizedBox(width: 12),
            Text(
              'En Desarrollo',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'La función "$featureName" está actualmente en desarrollo.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Estará disponible próximamente',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Entendido',
              style: TextStyle(color: theme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
