import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/profile_model.dart';
import '../../services/profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  final ProfileService _profileService = ProfileService();
  
  // Controllers para el formulario
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _documentController = TextEditingController();
  
  // Estado de la aplicación
  ProfileModel? _currentProfile;
  List<DocumentTypeModel> _documentTypes = [];
  List<UserCodeModel> _userCodes = [];
  DocumentTypeModel? _selectedDocumentType;
  String? _currentImageUrl;
  bool _isLoading = true;
  bool _showCreateForm = false;
  
  // Animación
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _initializeProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _documentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeProfile() async {
    try {
      setState(() => _isLoading = true);
      
      // Cargar tipos de documento
      _documentTypes = await _profileService.getDocumentTypes();
      
      // Buscar perfil existente
      _currentProfile = await _profileService.getCurrentUserProfile();
      
      if (_currentProfile != null) {
        _showProfile(_currentProfile!);
        await _loadUserCodes();
      } else {
        _showCreateForm = true;
      }
      
      _animationController.forward();
    } catch (e) {
      _showErrorDialog('Error cargando perfil: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showProfile(ProfileModel profile) {
    setState(() {
      _showCreateForm = false;
      _currentProfile = profile;
      _currentImageUrl = profile.imageUrl;
    });
  }

  Future<void> _loadUserCodes() async {
    try {
      _userCodes = await _profileService.getUserCodes();
      setState(() {});
    } catch (e) {
      // Error silencioso para códigos
    }
  }

  Future<void> _createProfile() async {
    if (!_validateForm()) return;
    
    try {
      setState(() => _isLoading = true);
      
      final newProfile = ProfileModel(
        profileName: _nameController.text.trim(),
        profileLastname: _lastNameController.text.trim(),
        profilePhone: _phoneController.text.trim(),
        profileNumberDocument: _documentController.text.trim(),
        typeDocumentFk: _selectedDocumentType!.typeDocumentId,
        imageFk: null, // Sin imagen por ahora
      );
      
      final createdProfile = await _profileService.createProfile(newProfile);
      _showProfile(createdProfile);
      await _loadUserCodes();
      
      _showSuccessDialog('Perfil creado exitosamente');
    } catch (e) {
      _showErrorDialog('Error creando perfil: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateForm() {
    if (_nameController.text.trim().isEmpty) {
      _showErrorDialog('El nombre es requerido');
      return false;
    }
    if (_lastNameController.text.trim().isEmpty) {
      _showErrorDialog('El apellido es requerido');
      return false;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showErrorDialog('El teléfono es requerido');
      return false;
    }
    if (_documentController.text.trim().isEmpty) {
      _showErrorDialog('El número de documento es requerido');
      return false;
    }
    if (_selectedDocumentType == null) {
      _showErrorDialog('Seleccione un tipo de documento');
      return false;
    }
    return true;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showSuccessDialog('Código copiado al portapapeles');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Mi Perfil',
          style: theme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: theme.appBarTheme.elevation,
      ),
      body: _isLoading 
        ? Center(
            child: CircularProgressIndicator(
              color: theme.colorScheme.primary,
            ),
          )
        : FadeTransition(
            opacity: _fadeAnimation,
            child: _showCreateForm 
              ? _buildCreateForm(theme)
              : _buildProfileDisplay(theme),
          ),
    );
  }

  Widget _buildCreateForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: theme.cardTheme.elevation,
        shape: theme.cardTheme.shape,
        color: theme.cardTheme.color,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título
              Text(
                'Crear Perfil',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Avatar placeholder
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.surface,
                    border: Border.all(
                      color: theme.colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.person_add,
                    size: 50,
                    color: theme.iconTheme.color,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Formulario
              _buildTextField(
                controller: _nameController,
                label: 'Nombre',
                icon: Icons.person,
                theme: theme,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _lastNameController,
                label: 'Apellido',
                icon: Icons.person_outline,
                theme: theme,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _phoneController,
                label: 'Teléfono',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                theme: theme,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _documentController,
                label: 'Número de Documento',
                icon: Icons.badge,
                theme: theme,
              ),
              const SizedBox(height: 16),
              
              // Dropdown de tipo de documento
              _buildDocumentTypeDropdown(theme),
              const SizedBox(height: 32),
              
              // Botón de crear
              ElevatedButton(
                onPressed: _isLoading ? null : _createProfile,
                style: theme.elevatedButtonTheme.style,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _isLoading ? 'Creando...' : 'Crear Perfil',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDisplay(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Card de información del perfil
          Card(
            elevation: theme.cardTheme.elevation,
            shape: theme.cardTheme.shape,
            color: theme.cardTheme.color,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Imagen de perfil placeholder
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.surface,
                      border: Border.all(
                        color: theme.colorScheme.outline,
                        width: 2,
                      ),
                    ),
                    child: _currentImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: Image.network(
                            _currentImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.person,
                              size: 60,
                              color: theme.iconTheme.color,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 60,
                          color: theme.iconTheme.color,
                        ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Información del perfil
                  _buildProfileInfo(theme),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Códigos del usuario
          if (_userCodes.isNotEmpty) _buildUserCodes(theme),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(ThemeData theme) {
    return Column(
      children: [
        _buildInfoRow('Nombre', '${_currentProfile?.profileName ?? ""} ${_currentProfile?.profileLastname ?? ""}', Icons.person, theme),
        _buildInfoRow('Teléfono', _currentProfile?.profilePhone ?? 'No especificado', Icons.phone, theme),
        _buildInfoRow('Documento', _currentProfile?.profileNumberDocument ?? 'No especificado', Icons.badge, theme),
        _buildInfoRow('Tipo de Documento', _currentProfile?.typeDocumentName ?? 'No especificado', Icons.description, theme),
        _buildInfoRow('Email', _currentProfile?.userMail ?? 'No especificado', Icons.email, theme),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: theme.iconTheme.color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCodes(ThemeData theme) {
    return Card(
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      color: theme.cardTheme.color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.qr_code,
                  color: theme.iconTheme.color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Mis Códigos',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _userCodes.length,
              itemBuilder: (context, index) {
                final code = _userCodes[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.local_offer,
                    color: theme.iconTheme.color,
                  ),
                  title: Text(
                    code.codigeNumber,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    code.productName,
                    style: theme.textTheme.bodyMedium,
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.copy,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: () => _copyToClipboard(code.codigeNumber),
                    tooltip: 'Copiar código',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: theme.inputDecorationTheme.border,
        focusedBorder: theme.inputDecorationTheme.focusedBorder,
        filled: theme.inputDecorationTheme.filled,
        fillColor: theme.inputDecorationTheme.fillColor,
        labelStyle: theme.inputDecorationTheme.labelStyle,
      ),
    );
  }

  Widget _buildDocumentTypeDropdown(ThemeData theme) {
    return DropdownButtonFormField<DocumentTypeModel>(
      initialValue: _selectedDocumentType,
      decoration: InputDecoration(
        labelText: 'Tipo de Documento',
        prefixIcon: const Icon(Icons.description),
        border: theme.inputDecorationTheme.border,
        focusedBorder: theme.inputDecorationTheme.focusedBorder,
        filled: theme.inputDecorationTheme.filled,
        fillColor: theme.inputDecorationTheme.fillColor,
        labelStyle: theme.inputDecorationTheme.labelStyle,
      ),
      items: _documentTypes.map((docType) {
        return DropdownMenuItem<DocumentTypeModel>(
          value: docType,
          child: Text(docType.typeDocumentName),
        );
      }).toList(),
      onChanged: (DocumentTypeModel? value) {
        setState(() {
          _selectedDocumentType = value;
        });
      },
    );
  }
}