import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';
import 'package:nexus_ar/components/bottom_nav_bar.dart';
import 'package:nexus_ar/components/custom_app_bar.dart';
import 'package:nexus_ar/temp/conten_page.dart';
import 'package:nexus_ar/screens/help.dart';
import 'package:nexus_ar/components/logout_dialog.dart';
import 'package:nexus_ar/screens/inicio_sesion.dart';
import 'package:nexus_ar/screens/mi_perfil.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _selectedIndex = 0;
  bool _isInitialLoad = true;

  // PÁGINAS ESTATICAS: El orden debe ser: [LOGROS (index 1), NOTIFICACIONES (index 2)]
  final List<Widget> _staticPages = [
    const ContentPage(title: 'LOGROS'),       // ⬅️ Este es el INDEX 1
    const ContentPage(title: 'NOTIFICACIONES'),// ⬅️ Este es el INDEX 2
  ];
  
  void _onItemTapped(int index) {
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MiPerfilScreen()),
      );
      return;
    }

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
      ContentPage(title: page0Title), // 0: UBICACION
      ..._staticPages, // 1 y 2: LOGROS y NOTIFICACIONES
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      extendBody: true,
      extendBodyBehindAppBar: true,

      // 1. Barra superior
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: CustomAppBar(
          onHelpPressed: _navigateToHelpScreen,
          onLogoutPressed: _showLogoutDialog,
          backButton: false,
        ),
      ),

      // 2. Contenido
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),

      // 3. Barra inferior
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