class ApiConfig {
  // Host base
  static const String host = "http://192.168.1.14:3000";
  
  // ===== ENDPOINTS DE LA API =====
  // Rutas principales del API (coinciden exactamente con el JavaScript)
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

  // ===== RUTAS PARA DASHBOARDS =====
  static const String urlDashboardAddress = "/dashboard/address/";
  static const String urlDashboardAddressProfile = "/dashboard/addressProfile/";
  static const String urlDashboardApiUser = "/dashboard/apiUser/";
  static const String urlDashboardBrand = "/dashboard/brand/";
  static const String urlDashboardCodige = "/dashboard/codige/";
  static const String urlDashboardColors = "/dashboard/colors/";
  static const String urlDashboardCompany = "/dashboard/company/";
  static const String urlDashboardImage = "/dashboard/img/";
  static const String urlDashboardModule = "/dashboard/module/";
  static const String urlDashboardOrders = "/dashboard/orders/";
  static const String urlDashboardProducts = "/dashboard/product/";
  static const String urlDashboardProfile = "/dashboard/profile/";
  static const String urlDashboardRole = "/dashboard/role/";
  static const String urlDashboardRoleModule = "/dashboard/roleModule/";
  static const String urlDashboardSize = "/dashboard/size/";
  static const String urlDashboardStateOrder = "/dashboard/stateOrder/";
  static const String urlDashboardStateUser = "/dashboard/stateUser/";
  static const String urlDashboardTypeDocument = "/dashboard/typeDocument/";
  static const String urlDashboardTypeProduct = "/dashboard/typeProduct/";
  static const String urlDashboardUsers = "/dashboard/users/";

  // ===== RUTAS PARA VISTAS GENERALES =====
  static const String urlGeneralViewBlogModas = "/generalViews/BlogModas/";
  static const String urlGeneralViewCamisaAlfilerada = "/generalViews/camisaAlfilerada";
  static const String urlGeneralViewCamisaAmericana = "/generalViews/camisaAmericana";
  static const String urlGeneralViewCamisaPasador = "/generalViews/camisaPasador";
  static const String urlGeneralViewCamisas = "/generalViews/camisas/";
  static const String urlGeneralViewCarritoCompras = "/generalViews/carritoCompras/";
  static const String urlGeneralViewElegant = "/generalViews/elegant/";
  static const String urlGeneralViewHome = "/generalViews/home/";
  static const String urlGeneralViewLogeado = "/generalViews/logeado/";
  static const String urlGeneralViewLogin = "/generalViews/login/";
  static const String urlGeneralViewMaster = "/generalViews/master/";
  static const String urlGeneralViewPantalonDrill = "/generalViews/PantalonDrill/";
  static const String urlGeneralViewPantalonGabardina = "/generalViews/pantalonGabardina/";
  static const String urlGeneralViewPantalonLino = "/generalViews/PantalonLino/";
  static const String urlGeneralViewPantalones = "/generalViews/pantalones/";
  static const String urlGeneralViewPasarela = "/generalViews/pasarela/";
  static const String urlGeneralViewProfile = "/generalViews/profile/";
  static const String urlGeneralViewRegister = "/generalViews/register/";
  static const String urlGeneralViewShoptop = "/generalViews/shoptop/";
  static const String urlGeneralViewAbrigoFormal = "/generalViews/torsoAbrigoFormal/";
  static const String urlGeneralViewBlazer = "/generalViews/torsoBlazer/";
  static const String urlGeneralViewGaban = "/generalViews/torsoGaban/";
  static const String urlGeneralViewTorso = "/generalViews/torso/";
  static const String urlGeneralViewUserLoged = "/generalViews/userLoged/";
  static const String urlGeneralViewVisitor = "/generalViews/Visitor/";

  // ===== ENDPOINTS DE AUTENTICACIÓN =====
  static const String urlLogin = "/api_v1/users/login";
  static const String urlRegister = "/api_v1/users";  // POST para crear usuario
  
  // ===== URLs COMPLETAS COMÚNMENTE USADAS =====
  static String get baseUrl => host;
  
  // Endpoints específicos para autenticación
  static String get loginEndpoint => "$host$urlLogin";
  static String get registerEndpoint => "$host$urlRegister";  // POST a /api_v1/users
  static String get usersEndpoint => "$host$urlUsers";
  
  // ===== ENDPOINTS API COMPLETOS =====
  // Productos y catálogos
  static String get productsEndpoint => "$host$urlProducts";
  static String get brandEndpoint => "$host$urlBrand";
  static String get colorsEndpoint => "$host$urlColors";
  static String get sizeEndpoint => "$host$urlSize";
  static String get typeProductEndpoint => "$host$urlTypeProduct";
  
  // Usuarios y perfiles
  static String get profileEndpoint => "$host$urlProfile";
  static String get apiUserEndpoint => "$host$urlApiUser";
  
  // Órdenes y códigos
  static String get ordersEndpoint => "$host$urlOrders";
  static String get codigeEndpoint => "$host$urlCodige";
  
  // Direcciones
  static String get addressEndpoint => "$host$urlAddress";
  static String get addressProfileEndpoint => "$host$urlAddressProfile";
  
  // Sistema y administración
  static String get companyEndpoint => "$host$urlCompany";
  static String get imageEndpoint => "$host$urlImage";
  static String get moduleEndpoint => "$host$urlModule";
  static String get roleEndpoint => "$host$urlRole";
  static String get roleModuleEndpoint => "$host$urlRoleModule";
  static String get stateOrderEndpoint => "$host$urlStateOrder";
  static String get stateUserEndpoint => "$host$urlStateUser";
  static String get typeDocumentEndpoint => "$host$urlTypeDocument";

  // ===== ENDPOINTS DE DASHBOARD COMPLETOS =====
  static String get dashboardAddressEndpoint => "$host$urlDashboardAddress";
  static String get dashboardBrandEndpoint => "$host$urlDashboardBrand";
  static String get dashboardProductsEndpoint => "$host$urlDashboardProducts";
  static String get dashboardProfileEndpoint => "$host$urlDashboardProfile";
  static String get dashboardUsersEndpoint => "$host$urlDashboardUsers";
  
  // ===== ENDPOINTS DE VISTAS GENERALES COMPLETOS =====
  static String get generalViewHomeEndpoint => "$host$urlGeneralViewHome";
  static String get generalViewLoginEndpoint => "$host$urlGeneralViewLogin";
  static String get generalViewRegisterEndpoint => "$host$urlGeneralViewRegister";
  static String get generalViewProfileEndpoint => "$host$urlGeneralViewProfile";
  static String get generalViewCarritoEndpoint => "$host$urlGeneralViewCarritoCompras";
  static String get generalViewProductsEndpoint => "$host$urlGeneralViewTorso";
  static String get generalViewCamisasEndpoint => "$host$urlGeneralViewCamisas";
  static String get generalViewPantalonesEndpoint => "$host$urlGeneralViewPantalones";
  
  // Obtener URL base (retorna el host configurado)
  static String getBaseUrl() => host;
  
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