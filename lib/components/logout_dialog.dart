import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';

class LogoutDialog {
  static Future<bool?> show(BuildContext context) async {

    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4), // Fondo oscuro translúcido
      barrierDismissible: true,
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
                    const Text(
                      '¿Seguro que deseas cerrar sesión?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDialogButton(
                          context,
                          text: 'Si',
                          color: AppColors.botonInicioSesion,
                          textColor: Colors.black,
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                        _buildDialogButton(
                          context,
                          text: 'No',
                          color: AppColors.botonInicioSesion,
                          textColor: Colors.black,
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                      ],
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

  static Widget _buildDialogButton(
    BuildContext context, {
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(100, 45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
