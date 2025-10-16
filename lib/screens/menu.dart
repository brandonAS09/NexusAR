import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';
import 'package:nexus_ar/components/bottom_nav_bar.dart';
import 'package:nexus_ar/components/custom_app_bar.dart';
import 'package:nexus_ar/temp/conten_page.dart';
import 'package:nexus_ar/screens/help.dart';
import 'package:nexus_ar/components/logout_dialog.dart';
import 'package:nexus_ar/screens/inicio_sesion.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _selectedIndex = 0;
  bool _isInitialLoad = true;

  final List<Widget> _staticPages = [
    const Placeholder(),
    const ContentPage(title: 'LOGROS'),
    const ContentPage(title: 'NOTIFICACIONES'),
    const ContentPage(title: 'MI PERFIL'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isInitialLoad = false;
    });
  }

  void _navigateToHelpScreen() async {
    final newIndex = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => HelpScreen(selectedIndex: _selectedIndex),
      ),
    );

    if (newIndex != null && newIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = newIndex;
      });
    }
  }

  void _showLogoutDialog() async {
    final bool? shouldLogout = await LogoutDialog.show(context);

    if (shouldLogout == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const InicioSesion()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String page0Title = (_selectedIndex == 0 && _isInitialLoad)
        ? 'Bienvenido a la Aplicación'
        : 'UBICACION';

    final List<Widget> pages = [
      ContentPage(title: page0Title),
      ..._staticPages.sublist(1),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      extendBody: true,
      extendBodyBehindAppBar: true,

      // 1. APP BAR
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: CustomAppBar(
          onHelpPressed: _navigateToHelpScreen,
          onLogoutPressed: _showLogoutDialog, // logout
          backButton: false,
        ),
      ),

      // 2. BODY
      body: IndexedStack(index: _selectedIndex, children: pages),

      // 3. BOTTOM NAVIGATION BAR
      bottomNavigationBar: SizedBox(
        height: 160.0,
        child: CustomBottomNavBar(
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemTapped,
        ),
      ),
    );
  }
}
