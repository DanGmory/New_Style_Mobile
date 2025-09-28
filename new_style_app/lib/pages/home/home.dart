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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? _lastPressedAt;
  final CartService _cartService = CartService();
  int _cartItemCount = 0;

  late List<FeaturePage> _features;

  @override
  void initState() {
    super.initState();
    _features = buildFeatures(
      widget.user,
      onNavigateToProducts: _navigateToProductsPage,
      themeService: widget.themeService,
    );
    _loadCartItemCount();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
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

    return Stack(
      children: [
        Icon(
          Icons.shopping_cart,
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
        ),
        if (_cartItemCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                _cartItemCount > 99 ? '99+' : '$_cartItemCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _onDrawerItemSelected(int index) {
    setState(() {
      _currentIndex = index;
      _pageController.jumpToPage(index);
    });
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
        body: PageView(
          controller: _pageController,
          children: _features.map((feature) => feature.page).toList(),
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            _pageController.jumpToPage(index);
            // Recargar contador del carrito cuando se seleccione cualquier pestaña
            if (index != 2) {
              // No recargar si ya estamos en el carrito
              _loadCartItemCount();
            }
          },
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: _features.asMap().entries.map((entry) {
            final index = entry.key;
            final feature = entry.value;

            // Si es el carrito (índice 2), usar el ícono con badge
            if (index == 2 && feature.icon == Icons.shopping_cart) {
              return BottomNavigationBarItem(
                icon: _buildCartIcon(),
                label: feature.title,
              );
            }

            return BottomNavigationBarItem(
              icon: Icon(feature.icon),
              label: feature.title,
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getTitle() {
    if (_currentIndex < _features.length) {
      return _features[_currentIndex].title;
    }
    return 'Bienvenido, ${widget.user.name}';
  }
}
