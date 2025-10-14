import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  Widget _buildBottomBarIcon({
    required IconData icon,
    required int index,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final iconColor = isSelected ? Colors.white : Colors.white70;
    final iconSize = isSelected ? 35.0 : 32.0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 40, right: 40, bottom: 30),
      decoration: BoxDecoration(
        color: AppColors.botonInicioSesion,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      // Estructura de navegacion inferior
      child: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomBarIcon(
              icon: Icons.location_on,
              index: 0,
              isSelected: selectedIndex == 0,
              onTap: () => onItemSelected(0),
            ),

            // 1: Logros
            _buildBottomBarIcon(
              icon: Icons.emoji_events,
              index: 1,
              isSelected: selectedIndex == 1,
              onTap: () => onItemSelected(1),
            ),

            // 2: Notificaciones
            _buildBottomBarIcon(
              icon: Icons.notifications,
              index: 2,
              isSelected: selectedIndex == 2,
              onTap: () => onItemSelected(2),
            ),
            // 3: Perfil
            _buildBottomBarIcon(
              icon: Icons.person,
              index: 3,
              isSelected: selectedIndex == 3,
              onTap: () => onItemSelected(3),
            ),
          ],
        ),
      ),
    );
  }
}
