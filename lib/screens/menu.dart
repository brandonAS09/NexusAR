import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';
import 'package:nexus_ar/components/bottom_nav_bar.dart';
import 'package:nexus_ar/components/custom_app_bar.dart';
import 'package:nexus_ar/temp/conten_page.dart';
import 'package:nexus_ar/screens/help.dart';
import 'package:nexus_ar/components/logout_dialog.dart';
import 'package:nexus_ar/screens/inicio_sesion.dart';
import 'package:nexus_ar/screens/mi_perfil.dart';
import 'package:nexus_ar/screens/map_screen.dart'; // ✅ Import del mapa

class MenuScreen extends StatefulWidget {
  final int initialIndex;

  const MenuScreen({super.key, this.initialIndex = 1});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late int _selectedIndex;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  // PÁGINAS ESTÁTICAS: El orden debe ser: [LOGROS (index 1), NOTIFICACIONES (index 2)]
  final List<Widget> _staticPages = [
    const ContentPage(title: 'Bienvenido a la aplicacion'),
    const ContentPage(title: 'LOGROS'),        // ⬅️ INDEX 2
    const ContentPage(title: 'NOTIFICACIONES'), // ⬅️ INDEX 3
  ];

  // 🔹 Controlador de taps del menú inferior
  void _onItemTapped(int index) {
    // ⬅️ Si toca “Ubicación”, ir a MapScreen
    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MapScreen()),
      );
      return;
    }

    // ⬅️ Si toca “Mi Perfil”, ir a pantalla de perfil
    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MiPerfilScreen()),
      );
      return;
    }

    // ⬅️ Otros botones cambian el contenido dentro del menú
    setState(() {
      _selectedIndex = index;
      _isInitialLoad = false;
    });
  }

  // 🔹 Navegar a pantalla de ayuda
  void _navigateToHelpScreen() async {
    final newIndex = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => HelpScreen(selectedIndex: _selectedIndex),
      ),
    );

    if (newIndex != null && newIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = 1;
      });
    }
  }

  // 🔹 Mostrar diálogo de cierre de sesión
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
        : 'UBICACIÓN';

    final List<Widget> pages = [
      ContentPage(title: page0Title), // 0: UBICACIÓN (ya no visible, se reemplaza por MapScreen)
      ..._staticPages, // 2: LOGROS, 3: NOTIFICACIONES
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      extendBody: true,
      extendBodyBehindAppBar: true,

      // 1️⃣ Barra superior
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: CustomAppBar(
          onHelpPressed: _navigateToHelpScreen,
          onLogoutPressed: _showLogoutDialog,
          backButton: false,
        ),
      ),

      // 2️⃣ Contenido central
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),

      // 3️⃣ Barra inferior
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
