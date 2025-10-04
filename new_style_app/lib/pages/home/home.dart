import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/appbar.dart';
import '../../widgets/sidebar.dart';
import '../auth/login.dart';
import '../../models/register_model.dart';
import '../../models/features_page.dart';
import '../../config/features.dart';
import '../../services/cart_service.dart';
import '../../services/logger_service.dart';
import '../../services/theme_service.dart';

class HomeScreen extends StatefulWidget {
  final ApiUser user;
  final ThemeService themeService;

  const HomeScreen({super.key, required this.user, required this.themeService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> 
    with WidgetsBindingObserver, TickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? _lastPressedAt;
  final CartService _cartService = CartService();
  int _cartItemCount = 0;
  
  // Controladores de animación
  late AnimationController _fabAnimationController;
  late AnimationController _pageAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<Offset> _pageSlideAnimation;

  late List<FeaturePage> _features;

  @override
  void initState() {
    super.initState();
    
    // Inicializar controladores de animación
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    _fabScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _pageSlideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _pageAnimationController,
      curve: Curves.easeOutQuart,
    ));
    
    _features = buildFeatures(
      widget.user,
      onNavigateToProducts: _navigateToProductsPage,
      themeService: widget.themeService,
    );
    _loadCartItemCount();
    WidgetsBinding.instance.addObserver(this);
    
    // Iniciar animaciones
    _fabAnimationController.forward();
    _pageAnimationController.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _fabAnimationController.dispose();
    _pageAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Actualizar contador del carrito cuando la app vuelva a primer plano
      _loadCartItemCount();
    }
  }

  Future<void> _loadCartItemCount() async {
    try {
      final count = await _cartService.getCartItemCount();
      if (mounted) {
        setState(() {
          _cartItemCount = count;
        });
      }
    } catch (e) {
      LoggerService.error('Error cargando contador del carrito', e);
    }
  }

  void _navigateToProductsPage() {
    // Navegar a la página de productos (índice 1)
    setState(() {
      _currentIndex = 1;
    });
    _pageController.jumpToPage(1);
  }

  Widget _buildCartIcon() {
    const cartIndex = 2; // Índice del carrito en las features
    final isSelected = _currentIndex == cartIndex;
    final theme = Theme.of(context);

    return AnimatedScale(
      scale: isSelected ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Stack(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            color: isSelected ? theme.primaryColor : Colors.grey[600],
            size: 24,
          ),
          if (_cartItemCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.error.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  _cartItemCount > 99 ? '99+' : '$_cartItemCount',
                  style: TextStyle(
                    color: theme.colorScheme.onError,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onDrawerItemSelected(int index) {
    _pageAnimationController.reset();
    setState(() {
      _currentIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    });
    _pageAnimationController.forward();
    _scaffoldKey.currentState?.closeDrawer();
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(themeService: widget.themeService),
      ),
      (route) => false,
    );
  }

  Future<bool> _onWillPop() async {
    if (_lastPressedAt == null ||
        DateTime.now().difference(_lastPressedAt!) >
            const Duration(seconds: 2)) {
      _lastPressedAt = DateTime.now();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Presiona de nuevo para salir")),
      );
      return false;
    }
    await SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: CustomAppBar(
          title: _getTitle(),
          showBackButton: false,
          onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        drawer: CustomDrawer(
          username: widget.user.name,
          onItemSelected: _onDrawerItemSelected,
          onLogout: _logout,
          currentIndex: _currentIndex,
          user: widget.user,
          themeService: widget.themeService,
        ),
        body: SlideTransition(
          position: _pageSlideAnimation,
          child: PageView(
            controller: _pageController,
            children: _features.map((feature) => feature.page).toList(),
            onPageChanged: (index) {
              _pageAnimationController.reset();
              setState(() {
                _currentIndex = index;
              });
              _pageAnimationController.forward();
              
              // Feedback háptico suave
              HapticFeedback.selectionClick();
            },
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              // Animación de feedback
              _fabAnimationController.reverse().then((_) {
                _fabAnimationController.forward();
              });
              
              setState(() {
                _currentIndex = index;
              });
              
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
              );
              
              // Recargar contador del carrito
              if (index != 2) {
                _loadCartItemCount();
              }
              
              // Feedback háptico
              HapticFeedback.lightImpact();
            },
            selectedItemColor: theme.primaryColor,
            unselectedItemColor: Colors.grey[600],
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 11,
            ),
            items: _features.asMap().entries.map((entry) {
              final index = entry.key;
              final feature = entry.value;
              final isSelected = _currentIndex == index;

              // Si es el carrito (índice 2), usar el ícono con badge
              if (index == 2 && feature.icon == Icons.shopping_cart) {
                return BottomNavigationBarItem(
                  icon: ScaleTransition(
                    scale: _fabScaleAnimation,
                    child: _buildCartIcon(),
                  ),
                  label: feature.title,
                );
              }

              return BottomNavigationBarItem(
                icon: AnimatedScale(
                  scale: isSelected ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? _getSelectedIcon(feature.icon) : feature.icon,
                    size: 24,
                  ),
                ),
                label: feature.title,
              );
            }).toList(),
          ),
        ),
        // Floating Action Button para acceso rápido
        floatingActionButton: _currentIndex == 0 ? ScaleTransition(
          scale: _fabScaleAnimation,
          child: FloatingActionButton.extended(
            onPressed: _navigateToProductsPage,
            backgroundColor: theme.primaryColor,
            foregroundColor: theme.colorScheme.onPrimary,
            elevation: 8,
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Explorar'),
            extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
          ),
        ) : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  String _getTitle() {
    if (_currentIndex < _features.length) {
      return _features[_currentIndex].title;
    }
    return 'Bienvenido, ${widget.user.name}';
  }
  
  IconData _getSelectedIcon(IconData defaultIcon) {
    switch (defaultIcon) {
      case Icons.home:
        return Icons.home;
      case Icons.shopping_bag:
        return Icons.shopping_bag;
      case Icons.person:
        return Icons.person;
      case Icons.settings:
        return Icons.settings;
      default:
        return defaultIcon;
    }
  }
}
