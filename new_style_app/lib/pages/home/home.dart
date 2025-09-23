import 'package:flutter/material.dart';
import '../../widgets/appbar.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/navigation_bottom.dart';
import '../user/user.dart';
import '../auth/change_password.dart';
import '../auth/login.dart';
import '../products/products.dart';
import '../../models/register_model.dart'; // 🔹 Importamos ApiUser

class HomeScreen extends StatefulWidget {
  final ApiUser user; // 🔹 Recibimos el usuario logueado

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const ProductScreen(),
      UserScreen(user: widget.user), // 🔹 Pasamos el ApiUser
      const ChangePasswordScreen(),
    ];
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
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        title: _getTitle(),
        showBackButton: false,
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: CustomDrawer(
        username: widget.user.name, // 🔹 Mostramos el nombre en el Drawer
        onItemSelected: _onDrawerItemSelected,
        onLogout: _logout,
        currentIndex: _currentIndex,
      ),
      body: PageView(
        controller: _pageController,
        children: _pages,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.jumpToPage(index);
        },
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Productos';
      case 1:
        return 'Perfil';
      case 2:
        return 'Configuración';
      default:
        return 'Mi App';
    }
  }
}
