import 'package:flutter/material.dart';
import '../../widgets/appbar.dart';
import '../../widgets/navigation_bottom.dart'; 
import '../../widgets/sidebar.dart'; 
import '../../models/register_model.dart'; 
import '../cart/cart.dart';
import '../blog/blog_modas.dart';
import '../home/home.dart';
class MainScreen extends StatefulWidget {
  final ApiUser user;

  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final List<Widget> _pages = [
    HomeScreen(user: widget.user), // 👈 vista de inicio
    const CartScreen(),
  ];

  void _onItemSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    Navigator.pop(context);
  }

  void _onLogout() {
    Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,

      appBar: CustomAppBar(
        title: "Bienvenido, ${widget.user.name}",
        onMenuPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),

      drawer: CustomDrawer(
        username: widget.user.name,
        currentIndex: _currentIndex,
        onItemSelected: _onItemSelected,
        onLogout: _onLogout,
        notificationCount: 3,
      ),

      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
