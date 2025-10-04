# API Routes Documentation
## Sincronización entre JavaScript Frontend y Flutter Mobile App

Este archivo documenta la sincronización completa de rutas entre el frontend web (JavaScript) y la aplicación móvil (Flutter).

## 🔗 Rutas Principales del API

### JavaScript ➡️ Flutter (ApiConfig)

| **JavaScript Const** | **Flutter Constant** | **Endpoint** | **Uso** |
|---------------------|---------------------|--------------|---------|
| `URL_ADDRESS` | `urlAddress` | `/api_v1/address` | Direcciones |
| `URL_ADDRESS_PROFILE` | `urlAddressProfile` | `/api_v1/addressProfile` | Perfil de direcciones |
| `URL_API_USER` | `urlApiUser` | `/api_v1/apiUser` | Usuario API |
| `URL_BRAND` | `urlBrand` | `/api_v1/brand` | Marcas |
| `URL_CODIGE` | `urlCodige` | `/api_v1/codige` | Códigos de producto |
| `URL_COLORS` | `urlColors` | `/api_v1/colors` | Colores |
| `URL_COMPANY` | `urlCompany` | `/api_v1/company` | Empresa |
| `URL_IMAGE` | `urlImage` | `/api_v1/img` | Imágenes |
| `URL_MODULE` | `urlModule` | `/api_v1/module` | Módulos |
| `URL_ORDERS` | `urlOrders` | `/api_v1/orders` | Órdenes |
| `URL_PRODUCTS` | `urlProducts` | `/api_v1/products` | **Productos** ✅ |
| `URL_PROFILE` | `urlProfile` | `/api_v1/profile` | **Perfiles** ✅ |
| `URL_ROLE` | `urlRole` | `/api_v1/role` | Roles |
| `URL_ROLE_MODULE` | `urlRoleModule` | `/api_v1/roleModule` | Roles-Módulos |
| `URL_SIZE` | `urlSize` | `/api_v1/size` | Tallas |
| `URL_STATE_ORDER` | `urlStateOrder` | `/api_v1/stateOrder` | Estado órdenes |
| `URL_STATE_USER` | `urlStateUser` | `/api_v1/stateUser` | Estado usuarios |
| `URL_TYPE_DOCUMENT` | `urlTypeDocument` | `/api_v1/typeDocument` | **Tipos de documento** ✅ |
| `URL_TYPE_PRODUCT` | `urlTypeProduct` | `/api_v1/typeProduct` | Tipos de producto |
| `URL_USERS` | `urlUsers` | `/api_v1/users` | **Usuarios** ✅ |

## 🎛️ Rutas de Dashboard

### JavaScript ➡️ Flutter

| **JavaScript Const** | **Flutter Constant** | **Endpoint** |
|---------------------|---------------------|--------------|
| `URL_DASHBOARD_ADDRESS` | `urlDashboardAddress` | `/dashboard/address/` |
| `URL_DASHBOARD_BRAND` | `urlDashboardBrand` | `/dashboard/brand/` |
| `URL_DASHBOARD_PRODUCTS` | `urlDashboardProducts` | `/dashboard/product/` |
| `URL_DASHBOARD_PROFILE` | `urlDashboardProfile` | `/dashboard/profile/` |
| `URL_DASHBOARD_USERS` | `urlDashboardUsers` | `/dashboard/users/` |
| *(... todos los demás dashboards ...)* | *(implementados)* | *(disponibles)* |

## 🌐 Rutas de Vistas Generales

### JavaScript ➡️ Flutter

| **JavaScript Const** | **Flutter Constant** | **Endpoint** | **Descripción** |
|---------------------|---------------------|--------------|----------------|
| `URL_GENERAL_VIEW_HOME` | `urlGeneralViewHome` | `/generalViews/home/` | Página principal |
| `URL_GENERAL_VIEW_LOGIN` | `urlGeneralViewLogin` | `/generalViews/login/` | **Login** ✅ |
| `URL_GENERAL_VIEW_REGISTER` | `urlGeneralViewRegister` | `/generalViews/register/` | **Registro** ✅ |
| `URL_GENERAL_VIEW_PROFILE` | `urlGeneralViewProfile` | `/generalViews/profile/` | **Perfil** ✅ |
| `URL_GENERAL_VIEW_CARRITO_COMPRAS` | `urlGeneralViewCarritoCompras` | `/generalViews/carritoCompras/` | **Carrito** ✅ |
| `URL_GENERAL_VIEW_CAMISAS` | `urlGeneralViewCamisas` | `/generalViews/camisas/` | Camisas |
| `URL_GENERAL_VIEW_TORSO` | `urlGeneralViewTorso` | `/generalViews/torso/` | **Productos Torso** ✅ |
| `URL_GENERAL_VIEW_PANTALONES` | `urlGeneralViewPantalones` | `/generalViews/pantalones/` | Pantalones |

## 🛠️ Servicios Implementados en Flutter

### ✅ Servicios Activos

1. **LoginService** (`login_services.dart`)
   - Endpoint: `/api_v1/users/login`
   - Funcionalidad: Autenticación de usuarios ✅

2. **RegisterService** (`register_services.dart`)  
   - Endpoint: `/api_v1/users`
   - Funcionalidad: Registro de usuarios ✅

3. **ProductService** (`product_services.dart`)
   - Endpoint: `/api_v1/products`
   - Funcionalidad: Catálogo de productos con filtros ✅

4. **ProfileService** (`profile_service.dart`)
   - Endpoints múltiples:
     - `/api_v1/profile` (CRUD de perfiles)
     - `/api_v1/typeDocument` (tipos de documento)
     - `/api_v1/codige` (códigos de usuario)
     - `/api_v1/img` (imágenes)
   - Funcionalidad: Gestión completa de perfiles ✅

### 🔄 Detección Inteligente de Red

Todos los servicios implementan detección automática de IP:

```dart
final List<String> testUrls = [
  'http://192.168.1.8:3000',  // IP primaria detectada
  'http://localhost:3000',     // Localhost fallback
  'http://127.0.0.1:3000',     // Local IP fallback
];
```

## 📱 URLs Completas Disponibles

### Getters Principales
- `ApiConfig.loginEndpoint` → `http://localhost:3000/api_v1/users/login`
- `ApiConfig.registerEndpoint` → `http://localhost:3000/api_v1/users`
- `ApiConfig.productsEndpoint` → `http://localhost:3000/api_v1/products`
- `ApiConfig.profileEndpoint` → `http://localhost:3000/api_v1/profile`
- `ApiConfig.typeDocumentEndpoint` → `http://localhost:3000/api_v1/typeDocument`

### Métodos de IP Dinámica
- `ApiConfig.getBaseUrlWithIP(dynamicIP)` 
- `ApiConfig.getEndpointWithIP(dynamicIP, endpoint)`
- `ApiConfig.getAllPossibleUrls(endpoint, detectedIP)`

## 🎯 Estado de Implementación

| **Funcionalidad** | **JavaScript** | **Flutter** | **Estado** |
|------------------|----------------|-------------|------------|
| Autenticación | ✅ | ✅ | Sincronizado |
| Registro | ✅ | ✅ | Sincronizado |
| Productos | ✅ | ✅ | Sincronizado |
| Filtros | ✅ | ✅ | Sincronizado |
| Perfil | ✅ | ✅ | Sincronizado |
| Códigos | ✅ | ✅ | Sincronizado |
| Carrito | ✅ | ✅ | Sincronizado |
| Temas | ❌ | ✅ | Mejorado en Flutter |

## 📝 Notas de Implementación

1. **Compatibilidad Total**: Todas las rutas son idénticas entre JavaScript y Flutter
2. **Red Inteligente**: Flutter implementa detección automática de IP para mejor conectividad móvil  
3. **Cache**: Sistema de cache de 5 minutos para optimizar rendimiento en móvil
4. **Fallbacks**: Múltiples IPs de fallback para garantizar conectividad
5. **Logging**: Sistema de logs detallado para debugging

## 🚀 Próximas Implementaciones

- Dashboard routes (cuando sea necesario para administración)
- Vistas específicas de categorías de productos
- Sistema de imágenes completo
- Notificaciones push
- Sincronización offline

---

**✅ Todas las rutas están sincronizadas y funcionando correctamente entre ambas plataformas.**