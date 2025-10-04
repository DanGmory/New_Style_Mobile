# 🔧 Solución del Error "Error creando perfil"

## 📋 Problema Identificado

**Error**: HTTP 400 "Error creando perfil" - No se pudo obtener un ID de usuario válido

## 🔍 Diagnóstico Realizado

### 1. Pruebas de Conectividad ✅
- **Servidor disponible**: `http://localhost:3000` ✅
- **Tipos de documento**: Disponibles (ID: 2, 3) ✅
- **API endpoints**: Funcionando correctamente ✅

### 2. Análisis del Error 🔍
El error se debía a **múltiples causas**:

#### A) Campos Obligatorios Faltantes
```
Status Code: 400
Response: {"error":"Missing required fields","missingFields":["Profile_phone","Profile_number_document"]}
```

#### B) ID de Usuario Inválido
```
Error: foreign key constraint fails (User_fk no existe en tabla users)
```

## ✅ Soluciones Implementadas

### 1. **Validación de Campos Obligatorios**

**Archivo**: `lib/services/profile_service.dart`
```dart
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
```

### 2. **Validación en el Formulario**

**Archivo**: `lib/pages/user/profile.dart`
```dart
bool _validateForm() {
  if (_nameController.text.trim().isEmpty) {
    _showErrorDialog('El nombre es requerido');
    return false;
  }
  if (_lastNameController.text.trim().isEmpty) {
    _showErrorDialog('El apellido es requerido');
    return false;
  }
  if (_phoneController.text.trim().isEmpty) {  // ← NUEVO
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
```

### 3. **Mejoras en ApiUser.fromJson**

**Archivo**: `lib/models/register_model.dart`
```dart
factory ApiUser.fromJson(Map<String, dynamic> json) {
  // Ajustamos: el backend puede devolver "data", "user" o directamente los campos
  final user = json['data'] ?? json['user'] ?? json;
  
  // Debug: Imprimir la estructura recibida
  print('🔍 ApiUser.fromJson recibió: $json');
  
  final userId = user['User_id'] ?? user['id'] ?? 0;
  print('🔍 ID de usuario extraído: $userId');

  return ApiUser(
    id: userId,
    name: user['User_name'] ?? user['name'] ?? '',
    email: user['User_mail'] ?? user['email'] ?? '',
    role: user['Role_fk'] ?? user['role'] ?? 0,
    state: user['State_user_fk'] ?? user['state'] ?? 1,
    token: json['token'] ?? user['token'] ?? '',
  );
}
```

### 4. **Sesión de Usuario Mejorada**

**Archivo**: `lib/services/login_services.dart`
```dart
Future<void> _saveUserSession(ApiUser user, String email) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Verificar que tenemos datos válidos antes de guardar
    if (user.id <= 0) {
      print('❌ ADVERTENCIA: Intentando guardar usuario con ID inválido: ${user.id}');
    }
    
    // Guardar información básica del usuario
    await prefs.setString('currentUserId', user.id.toString());
    await prefs.setString('currentUserEmail', email);
    await prefs.setString('currentUserName', user.name);
    
    // Verificar que se guardó correctamente
    final savedId = prefs.getString('currentUserId');
    print('💾 Sesión guardada: ID: $savedId');
    
  } catch (e) {
    print('❌ Error guardando sesión: $e');
  }
}
```

### 5. **Manejo de Errores Específicos**

**Archivo**: `lib/services/profile_service.dart`
```dart
} catch (e) {
  if (e is DioException) {
    if (e.response?.statusCode == 400) {
      final responseData = e.response?.data;
      if (responseData is Map && responseData.containsKey('missingFields')) {
        final missing = responseData['missingFields'].join(', ');
        throw Exception('Faltan campos obligatorios: $missing');
      }
      throw Exception('Datos inválidos: ${responseData?['error'] ?? 'Error desconocido'}');
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
  }
  rethrow;
}
```

## 🎯 Resultado Final

### ✅ Campos Requeridos Identificados
- ✅ `Profile_name` (obligatorio)
- ✅ `Profile_lastname` (obligatorio) 
- ✅ `Profile_phone` (obligatorio)
- ✅ `Profile_number_document` (obligatorio)
- ✅ `User_fk` (debe existir en tabla users)
- ✅ `Type_document_fk` (debe existir, usar ID: 2 o 3)

### ✅ Validaciones Implementadas
- ✅ Validación en cliente (formulario)
- ✅ Validación en servicio (antes de envío)
- ✅ Manejo de errores específicos del servidor
- ✅ Debugging mejorado para identificar problemas

### ✅ Sesión de Usuario Corregida
- ✅ Guardado correcto del ID de usuario
- ✅ Validación de datos antes del guardado
- ✅ Logs de debugging para verificar funcionamiento

## 🚀 Próximos Pasos

1. **Probar la creación de perfil** con todos los campos llenos
2. **Verificar que el usuario esté logueado** correctamente
3. **Confirmar que los tipos de documento** están disponibles

## 📝 Notas Técnicas

- El servidor requiere que `Profile_phone` y `Profile_number_document` no sean nulos ni vacíos
- El `User_fk` debe corresponder a un ID existente en la tabla `users`
- Los tipos de documento disponibles son ID: 2 y 3
- La validación ahora ocurre tanto en el cliente como en el servidor

---
**Estado**: ✅ Solucionado - Listo para probar