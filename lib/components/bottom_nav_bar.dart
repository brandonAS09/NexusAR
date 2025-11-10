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
    final iconColor = isSelected ? Colors.black : Colors.black45; 
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
    return IgnorePointer(
      ignoring: false,
      child: Container(
        margin: const EdgeInsets.only(left: 40, right: 40, bottom: 100),
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.botonInicioSesion,
          boxShadow: const [
            BoxShadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 5)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildBottomBarIcon(
              icon: Icons.location_on_outlined,
              index: 0,
              isSelected: selectedIndex == 0,
              onTap: () => onItemSelected(0),
            ),
            _buildBottomBarIcon(
              icon: Icons.home_outlined,
              index: 1,
              isSelected: selectedIndex == 1,
              onTap: () => onItemSelected(1),
            ),
            _buildBottomBarIcon(
              icon: Icons.emoji_events_outlined,
              index: 2,
              isSelected: selectedIndex == 2,
              onTap: () => onItemSelected(2),
            ),
            _buildBottomBarIcon(
              icon: Icons.checklist_outlined,
              index: 3,
              isSelected: selectedIndex == 3,
              onTap: () => onItemSelected(3),
            ),
            _buildBottomBarIcon(
              icon: Icons.account_circle_outlined,
              index: 4,
              isSelected: selectedIndex == 4,
              onTap: () => onItemSelected(4),
            ),
          ],
        ),
      ),
    );
  }
}