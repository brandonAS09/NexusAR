import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(70.0);

  final bool backButton;
  final VoidCallback? onHelpPressed;
  final VoidCallback? onLogoutPressed;

  const CustomAppBar({
    super.key,
    this.backButton = false,
    this.onHelpPressed,
    this.onLogoutPressed,
  });

  @override
  Widget build(BuildContext context) {
    final purpleColor = AppColors.botonInicioSesion;
    final IconData leftIcon = backButton ? Icons.arrow_back : Icons.logout;

    final VoidCallback? onLeftIconPressed = backButton
        ? () => Navigator.pop(context)
        : onLogoutPressed;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Container(
        height: 60,
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top > 20
              ? MediaQuery.of(context).padding.top - 5
              : 20.0,
        ),
        decoration: BoxDecoration(
          color: purpleColor,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Botón Izquierdo
            IconButton(
              icon: Icon(leftIcon, size: 30, color: Colors.black),
              onPressed: onLeftIconPressed,
            ),

            // Botón Derecho (Ayuda)
            IconButton(
              icon:
                  const Icon(Icons.help_outline, size: 30, color: Colors.black),
              onPressed: onHelpPressed,
            ),
          ],
        ),
      ),
    );
  }
}
