import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';
// Importamos el nuevo componente
import 'package:nexus_ar/components/bottom_nav_bar.dart'; 

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // Estado para saber qué ícono está seleccionado (0 = Inicio/Bienvenido)
  int _selectedIndex = 0; 

  // Función que se llama cuando se selecciona un ítem de la barra
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Aquí iría la lógica de navegación real a las otras pantallas
    // Por ahora, solo actualizamos el estado.
    
    // Si el índice es 0 (Inicio), mantenemos el contenido de "Bienvenido"
    // Si fuera otro índice (1, 2, 3), podrías navegar o cambiar el contenido.
  }

  @override
  Widget build(BuildContext context) {
    
    // NOTA: Para este prototipo, el contenido del body no cambiará,
    // pero si tuvieras que mostrar "UBICACION", "LOGROS", etc., 
    // tendrías que usar una lista de widgets o páginas.
    
    return Scaffold(
      backgroundColor: AppColors.backgroundColor, 
      
      // 1. APP BAR (Top)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0, 
        iconTheme: const IconThemeData(color: Colors.white),

        // Botón izquierdo: Salir
        leading: IconButton(
          icon: const Icon(Icons.exit_to_app, size: 30),
          onPressed: () {
            // Lógica para cerrar sesión
            Navigator.pop(context); 
          },
        ),

        // Botón derecho: Ayuda
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, size: 30),
            onPressed: () {
              // Lógica de ayuda
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      
      // 2. BODY (Contenido Central)
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Texto "Bienvenido a la Aplicación"
              const Text(
                'Bienvenido a la Aplicación',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.1, 
                ),
              ),
            ],
          ),
        ),
      ),
      
      // ⭐️ 3. BOTTOM NAVIGATION BAR (Usando el Componente Reutilizable)
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
      ),
    );
  }
}