import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';
import 'package:nexus_ar/screens/menu.dart'; // ⬅️ Importa el MenuScreen

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(70.0);

  final bool backButton;
  final VoidCallback? onHelpPressed;
  final VoidCallback? onLogoutPressed;
  final Widget? title;
  final bool centerTitle;

  const CustomAppBar({
    super.key,
    this.backButton = false,
    this.onHelpPressed,
    this.onLogoutPressed,
    this.title,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final purpleColor = AppColors.botonInicioSesion;
    final IconData leftIcon = backButton ? Icons.arrow_back : Icons.logout;

    final VoidCallback? onLeftIconPressed = backButton
        ? () async {
            debugPrint(
              '>>> CustomAppBar: backButton pressed. Starting navigation to fresh MenuScreen.',
            );

            // 1) Remover hasta la primera ruta (si existe)
            Navigator.of(context).popUntil((route) {
              debugPrint(
                '  checking route: ${route.settings.name} | isFirst=${route.isFirst}',
              );
              return route.isFirst;
            });

            // 2) Reemplazar la primera ruta por un MenuScreen nuevo (esto fuerza rebuild)
            // Usamos pushReplacement para mantener animación (reemplaza la ruta actual por la nueva)
            await Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => MenuScreen(
                  key: UniqueKey(), // fuerza nuevo State
                  initialIndex: 1, // siempre Home
                ),
              ),
            );

            debugPrint(
              '>>> CustomAppBar: navigation to fresh MenuScreen completed.',
            );
          }
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (title != null)
              Align(
                alignment: centerTitle
                    ? Alignment.center
                    : Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: centerTitle ? 0 : 60,
                    right: centerTitle ? 0 : 60,
                  ),
                  child: title,
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(leftIcon, size: 30, color: Colors.black),
                onPressed: onLeftIconPressed,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(
                  Icons.help_outline,
                  size: 30,
                  color: Colors.black,
                ),
                onPressed: onHelpPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
