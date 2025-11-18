import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';

/// Un helper para mostrar diálogos de asistencia con el estilo "blur"
class AsistenciaDialogs {

  /// Muestra el diálogo de "Asistencia en curso"
  static Future<void> showInitial(BuildContext context) {
    return _showBlurredDialog(
      context: context,
      // Usamos un 'TextSpan' para poder dar diferentes estilos
      title: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          children: [
            const TextSpan(text: 'Tu asistencia está en curso.\n\n'),
            TextSpan(
              text: 'Se verificará tu ubicación periódicamente. Si sales del área, tu tiempo se pausará.',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      actions: [
        _buildDialogButton(
          context,
          text: 'Entendido',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  /// Muestra el diálogo final (éxito o error de tiempo)
  static Future<void> showFinal(BuildContext context, String message) {
    return _showBlurredDialog(
      context: context,
      title: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        _buildDialogButton(
          context,
          text: 'Entendido',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  /// Muestra un diálogo de error genérico
  static Future<void> showError(BuildContext context, String title, String content) {
     return _showBlurredDialog(
      context: context,
      title: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          children: [
            TextSpan(text: '$title\n\n'),
            TextSpan(
              text: content,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      actions: [
        _buildDialogButton(
          context,
          text: 'OK',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  /// --- El constructor de diálogo base (copiado de tu LogoutDialog) ---
  static Future<T?> _showBlurredDialog<T>({
    required BuildContext context,
    required Widget title,
    required List<Widget> actions,
  }) {
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4), // Fondo oscuro translúcido
      barrierDismissible: false, // No se puede cerrar tocando fuera
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent, // fondo transparente
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // desenfoque
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.fieldTextColor.withOpacity(0.7), // boton traslucido
                  border: Border.all(color: AppColors.botonInicioSesion, width: 4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    title, // El título/contenido
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: actions, // Los botones
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// --- El constructor de botones (copiado de tu LogoutDialog) ---
  static Widget _buildDialogButton(
    BuildContext context, {
    required String text,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.botonInicioSesion, // Usamos tu color de botón
        minimumSize: const Size(100, 45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black, // Usamos tu color de texto
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}