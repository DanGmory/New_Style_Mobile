import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/profile_model.dart';
import '../services/logger_service.dart';

class ProfileService {
  final Dio _dio = Dio();
  
  // Cache para mejorar rendimiento
  static String? _cachedBaseUrl;
  static DateTime? _lastDetectionTime;
  static const Duration _cacheValidTime = Duration(minutes: 5);

  ProfileService() {
    _setupDio();
  }

  void _setupDio() {
    _dio.options.connectTimeout = Duration(milliseconds: 3000);
    _dio.options.receiveTimeout = Duration(milliseconds: 5000);
    _dio.options.sendTimeout = Duration(milliseconds: 5000);
  }

  Future<String> _getActiveUrl() async {
    // Verificar cache
    if (_cachedBaseUrl != null && 
        _lastDetectionTime != null && 
        DateTime.now().difference(_lastDetectionTime!) < _cacheValidTime) {
      return _cachedBaseUrl!;
    }

    // Intentar detectar red inteligentemente
    final List<String> testUrls = [
      'http://192.168.1.8:3000',
      'http://localhost:3000',
      'http://127.0.0.1:3000',
    ];

    for (String url in testUrls) {
      try {
        final response = await _dio.get(
          '$url/api_v1/products',
          options: Options(
            sendTimeout: Duration(milliseconds: 2000),
            receiveTimeout: Duration(milliseconds: 2000),
          ),
        );
        
        if (response.statusCode == 200) {
          _cachedBaseUrl = url;
          _lastDetectionTime = DateTime.now();
          LoggerService.info('🌐 Perfil conectado a: $url');
          return url;
        }
      } catch (e) {
        continue;
      }
    }

    // Fallback por defecto
    _cachedBaseUrl = ApiConfig.baseUrl;
    _lastDetectionTime = DateTime.now();
    return _cachedBaseUrl!;
  }

  Future<int> _resolveUserId() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Intentar obtener ID desde cache
    final cachedUserId = prefs.getString('currentUserId');
    LoggerService.info('🔍 Buscando ID de usuario: ${cachedUserId ?? "no encontrado"}');
    
    if (cachedUserId != null && cachedUserId.isNotEmpty) {
      final parsedId = int.tryParse(cachedUserId);
      if (parsedId != null && parsedId > 0) {
        LoggerService.info('✅ ID válido encontrado en cache: $cachedUserId');
        return parsedId;
      } else {
        LoggerService.error('❌ ID en cache no es válido: $cachedUserId');
      }
    }

    // Si no hay ID, buscar por email
    final userEmail = prefs.getString('currentUserEmail');
    LoggerService.info('📧 Buscando por email: ${userEmail ?? "no encontrado"}');
    
    if (userEmail == null || userEmail.isEmpty) {
      // Esperar un poco por si acaso la sesión se está guardando
      await Future.delayed(Duration(milliseconds: 500));
      
      // Intentar nuevamente
      final retryEmail = prefs.getString('currentUserEmail');
      if (retryEmail == null || retryEmail.isEmpty) {
        LoggerService.error('❌ No hay información de usuario en sesión después del reintento');
        throw Exception('No hay información de usuario en sesión');
      }
      LoggerService.info('✅ Email encontrado en reintento: $retryEmail');
    }

    final baseUrl = await _getActiveUrl();
    final response = await _dio.get('$baseUrl/api_v1/users');
    
    final finalEmail = userEmail ?? prefs.getString('currentUserEmail') ?? '';
    LoggerService.info('🔍 Usando email para búsqueda: $finalEmail');
    
    if (response.statusCode == 200) {
      final List<dynamic> users = response.data;
      final user = users.firstWhere(
        (u) => (u['User_mail'] ?? '').toLowerCase() == finalEmail.toLowerCase(),
        orElse: () => null,
      );
      
      if (user == null) {
        throw Exception('Usuario no encontrado por correo');
      }
      
      final userId = user['User_id'].toString();
      await prefs.setString('currentUserId', userId);
      return int.parse(userId);
    }
    
    throw Exception('No se pudo resolver el ID del usuario');
  }

  Future<List<DocumentTypeModel>> getDocumentTypes() async {
    try {
      final baseUrl = await _getActiveUrl();
      final response = await _dio.get('$baseUrl/api_v1/typeDocument');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => DocumentTypeModel.fromJson(json)).toList();
      }
      
      throw Exception('No se pudieron cargar tipos de documento');
    } catch (e) {
      LoggerService.error('❌ Error cargando tipos de documento: $e');
      return [];
    }
  }

  Future<ProfileModel?> getCurrentUserProfile() async {
    try {
      final baseUrl = await _getActiveUrl();
      final response = await _dio.get('$baseUrl/api_v1/profile');
      
      if (response.statusCode == 200) {
        final List<dynamic> profiles = response.data;
        
        // Intentar por ID de usuario
        final prefs = await SharedPreferences.getInstance();
        final currentUserId = prefs.getString('currentUserId');
        
        ProfileModel? found;
        if (currentUserId != null) {
          final profileJson = profiles.firstWhere(
            (p) => p['User_fk'].toString() == currentUserId,
            orElse: () => null,
          );
          if (profileJson != null) {
            found = ProfileModel.fromJson(profileJson);
          }
        }
        
        // Si no se encuentra por ID, buscar por email
        if (found == null) {
          final userEmail = prefs.getString('currentUserEmail');
          if (userEmail != null) {
            final profileJson = profiles.firstWhere(
              (p) => (p['User_mail'] ?? '').toLowerCase() == userEmail.toLowerCase(),
              orElse: () => null,
            );
            if (profileJson != null) {
              found = ProfileModel.fromJson(profileJson);
            }
          }
        }
        
        return found;
      }
      
      throw Exception('No se pudo cargar el perfil');
    } catch (e) {
      LoggerService.error('❌ Error cargando perfil: $e');
      return null;
    }
  }

  Future<ProfileModel> createProfile(ProfileModel profile) async {
    try {
      final baseUrl = await _getActiveUrl();
      final userId = await _resolveUserId();
      
      // Validar campos obligatorios según respuesta del servidor
      if (profile.profileName == null || profile.profileName!.trim().isEmpty) {
        throw Exception('El nombre es obligatorio');
      }
      if (profile.profileLastname == null || profile.profileLastname!.trim().isEmpty) {
        throw Exception('El apellido es obligatorio');
      }
      if (profile.profilePhone == null || profile.profilePhone!.trim().isEmpty) {
        throw Exception('El teléfono es obligatorio');
      }
      if (profile.profileNumberDocument == null || profile.profileNumberDocument!.trim().isEmpty) {
        throw Exception('El número de documento es obligatorio');
      }
      
      // Crear datos para el perfil con todos los campos obligatorios
      final profileData = {
        'Profile_name': profile.profileName!.trim(),
        'Profile_lastname': profile.profileLastname!.trim(),
        'Profile_phone': profile.profilePhone!.trim(),
        'Profile_number_document': profile.profileNumberDocument!.trim(),
        'User_fk': userId,
        'Type_document_fk': profile.typeDocumentFk ?? 2, // Usar ID válido del servidor
      };
      
      // Validar que tenemos un ID de usuario válido
      LoggerService.info('🔍 ID de usuario obtenido: $userId (tipo: ${userId.runtimeType})');
      if (userId <= 0) {
        LoggerService.error('❌ ID de usuario inválido: $userId');
        throw Exception('No se pudo obtener un ID de usuario válido (ID: $userId)');
      }
      
      LoggerService.info('✅ Creando perfil para usuario ID: $userId');
      
      final response = await _dio.post(
        '$baseUrl/api_v1/profile',
        data: profileData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        LoggerService.info('✅ Perfil creado exitosamente');
        return ProfileModel.fromJson(response.data);
      }
      
      throw Exception('No se pudo crear el perfil');
    } catch (e) {
      LoggerService.error('❌ Error creando perfil: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          final responseData = e.response?.data;
          if (responseData is Map && responseData.containsKey('missingFields')) {
            final missing = responseData['missingFields'].join(', ');
            throw Exception('Faltan campos obligatorios: $missing');
          }
          throw Exception('Datos inválidos: ${responseData?['error'] ?? 'Error desconocido'}');
        }
        if (e.response?.statusCode == 409) {
          throw Exception('Ya existe un perfil para este usuario');
        }
        if (e.response?.statusCode == 500) {
          final responseData = e.response?.data;
          if (responseData is Map && responseData.containsKey('sqlMessage')) {
            if (responseData['sqlMessage'].toString().contains('foreign key constraint fails')) {
              throw Exception('Error: Usuario no válido o tipo de documento inexistente');
            }
          }
          throw Exception('Error interno del servidor');
        }
        throw Exception('Error del servidor (${e.response?.statusCode})');
      }
      rethrow;
    }
  }

  Future<ProfileModel> updateProfile(ProfileModel profile) async {
    try {
      final baseUrl = await _getActiveUrl();
      
      if (profile.profileId == null) {
        throw Exception('ID de perfil requerido para actualizar');
      }
      
      final response = await _dio.put(
        '$baseUrl/api_v1/profile/${profile.profileId}',
        data: profile.toJson(),
      );
      
      if (response.statusCode == 200) {
        LoggerService.info('✅ Perfil actualizado exitosamente');
        return ProfileModel.fromJson(response.data);
      }
      
      throw Exception('No se pudo actualizar el perfil');
    } catch (e) {
      LoggerService.error('❌ Error actualizando perfil: $e');
      rethrow;
    }
  }

  Future<ImageUploadModel> uploadImage(String filePath, String fileName) async {
    try {
      final baseUrl = await _getActiveUrl();
      
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        'name': fileName,
      });
      
      final response = await _dio.post(
        '$baseUrl/api_v1/image',
        data: formData,
      );
      
      if (response.statusCode == 200) {
        LoggerService.info('✅ Imagen subida exitosamente');
        return ImageUploadModel.fromJson(response.data['file']);
      }
      
      throw Exception('Error subiendo imagen');
    } catch (e) {
      LoggerService.error('❌ Error subiendo imagen: $e');
      rethrow;
    }
  }

  Future<List<UserCodeModel>> getUserCodes() async {
    try {
      final baseUrl = await _getActiveUrl();
      final response = await _dio.get('$baseUrl/api_v1/codige');
      
      if (response.statusCode == 200) {
        final List<dynamic> codes = response.data;
        final prefs = await SharedPreferences.getInstance();
        final userEmail = prefs.getString('currentUserEmail');
        final currentUserId = prefs.getString('currentUserId');
        
        // Filtrar códigos por usuario
        List<dynamic> filteredCodes = codes;
        if (userEmail != null) {
          filteredCodes = codes.where((c) => 
            (c['user_mail'] ?? '').toLowerCase() == userEmail.toLowerCase()
          ).toList();
        } else if (currentUserId != null) {
          filteredCodes = codes.where((c) => 
            c['user_id'].toString() == currentUserId
          ).toList();
        }
        
        return filteredCodes.map((json) => UserCodeModel.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      LoggerService.error('❌ Error cargando códigos de usuario: $e');
      return [];
    }
  }
}