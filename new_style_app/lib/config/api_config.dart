/// Configuración centralizada de URLs y endpoints de la API
class ApiConfig {
  // Host base
  static const String host = "http://localhost:3000";
  
  // ===== ENDPOINTS DE LA API =====
  static const String urlAddress = "/api_v1/address";
  static const String urlAddressProfile = "/api_v1/addressProfile";
  static const String urlApiUser = "/api_v1/apiUser";
  static const String urlBrand = "/api_v1/brand";
  static const String urlCodige = "/api_v1/codige";
  static const String urlColors = "/api_v1/colors";
  static const String urlCompany = "/api_v1/company";
  static const String urlImage = "/api_v1/img";
  static const String urlModule = "/api_v1/module";
  static const String urlOrders = "/api_v1/orders";
  static const String urlProducts = "/api_v1/products";
  static const String urlProfile = "/api_v1/profile";
  static const String urlRole = "/api_v1/role";
  static const String urlRoleModule = "/api_v1/roleModule";
  static const String urlSize = "/api_v1/size";
  static const String urlStateOrder = "/api_v1/stateOrder";
  static const String urlStateUser = "/api_v1/stateUser";
  static const String urlTypeDocument = "/api_v1/typeDocument";
  static const String urlTypeProduct = "/api_v1/typeProduct";
  static const String urlUsers = "/api_v1/users";

  // ===== ENDPOINTS DE AUTENTICACIÓN =====
  static const String urlLogin = "/api_v1/users/login";
  static const String urlRegister = "/api_v1/users/register";
  
  // ===== URLs COMPLETAS COMÚNMENTE USADAS =====
  static String get baseUrl => host;
  
  // Endpoints específicos para autenticación
  static String get loginEndpoint => "$host$urlLogin";
  static String get registerEndpoint => "$host$urlRegister";
  static String get usersEndpoint => "$host$urlUsers";
  
  // ===== ENDPOINTS API COMPLETOS =====
  // Productos
  static String get productsEndpoint => "$host$urlProducts";
  
  // Usuarios y autenticación
  static String get profileEndpoint => "$host$urlProfile";
  static String get apiUserEndpoint => "$host$urlApiUser";
  
  // Órdenes
  static String get ordersEndpoint => "$host$urlOrders";
  
  // Direcciones
  static String get addressEndpoint => "$host$urlAddress";
  static String get addressProfileEndpoint => "$host$urlAddressProfile";
  
  // Catálogos
  static String get brandEndpoint => "$host$urlBrand";
  static String get colorsEndpoint => "$host$urlColors";
  static String get sizeEndpoint => "$host$urlSize";
  static String get typeProductEndpoint => "$host$urlTypeProduct";
  static String get companyEndpoint => "$host$urlCompany";
  static String get imageEndpoint => "$host$urlImage";
  static String get moduleEndpoint => "$host$urlModule";
  static String get roleEndpoint => "$host$urlRole";
  static String get roleModuleEndpoint => "$host$urlRoleModule";
  static String get stateOrderEndpoint => "$host$urlStateOrder";
  static String get stateUserEndpoint => "$host$urlStateUser";
  static String get typeDocumentEndpoint => "$host$urlTypeDocument";
  static String get codigeEndpoint => "$host$urlCodige";
  
  // Método para obtener URL completa con IP dinámica
  static String getBaseUrlWithIP(String? dynamicIP) {
    if (dynamicIP != null && dynamicIP.isNotEmpty) {
      return "http://$dynamicIP:3000";
    }
    return host;
  }
  
  // Método para obtener endpoint completo con IP dinámica
  static String getEndpointWithIP(String? dynamicIP, String endpoint) {
    final baseUrl = getBaseUrlWithIP(dynamicIP);
    return "$baseUrl$endpoint";
  }
  
  // Lista de todas las IPs comunes para fallback
  static const List<String> fallbackIps = [
    "192.168.1.100",
    "192.168.1.101", 
    "192.168.1.102",
    "192.168.1.69",
    "192.168.0.100",
    "192.168.0.101",
    "10.0.0.1",
    "10.0.0.2",
    "10.0.2.2", // Android emulator
    "172.16.0.1",
    "127.0.0.1",
  ];
  
  // Obtener todas las URLs posibles para un endpoint
  static List<String> getAllPossibleUrls(String endpoint, {String? detectedIP}) {
    final urls = <String>[];
    
    // Agregar localhost como primera opción
    urls.add("$host$endpoint");
    
    // Agregar IP detectada si existe
    if (detectedIP != null && detectedIP.isNotEmpty) {
      urls.add("http://$detectedIP:3000$endpoint");
    }
    
    // Agregar IPs de fallback
    for (String ip in fallbackIps) {
      if (ip != detectedIP) { // Evitar duplicados
        urls.add("http://$ip:3000$endpoint");
      }
    }
    
    return urls;
  }
  
  // Obtener todas las URLs base posibles (sin endpoint específico)
  static List<String> getAllPossibleBaseUrls({String? detectedIP}) {
    final urls = <String>[];
    
    // Base URL principal
    urls.add("$host/api_v1");
    
    // IP detectada
    if (detectedIP != null && detectedIP.isNotEmpty) {
      urls.add("http://$detectedIP:3000/api_v1");
    }
    
    // IPs de fallback
    for (String ip in fallbackIps) {
      if (ip != detectedIP) {
        urls.add("http://$ip:3000/api_v1");
      }
    }
    
    return urls;
  }
  
  // ===== MÉTODOS AUXILIARES =====
  
  // Endpoints específicos para usuarios
  static String getUserByIdUrl(int userId) => "$host$urlUsers/$userId";
  static String getUserUpdateUrl(int userId) => "$host$urlUsers/$userId";
  
  // Endpoints dinámicos para productos específicos
  static String getProductByIdUrl(int productId) => "$host$urlProducts/$productId";
  
  // Endpoints dinámicos para órdenes
  static String getOrderByIdUrl(int orderId) => "$host$urlOrders/$orderId";
  
  // Método para validar si es una URL válida
  static bool isValidEndpoint(String endpoint) {
    return endpoint.startsWith('/') && endpoint.contains('api_v1');
  }
  
  // Obtener endpoint completo con validación
  static String getValidatedEndpoint(String endpoint) {
    if (!isValidEndpoint(endpoint)) {
      throw ArgumentError('Endpoint inválido: $endpoint');
    }
    return "$host$endpoint";
  }
}