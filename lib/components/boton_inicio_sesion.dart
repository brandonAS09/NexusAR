import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';

class BotonInicioSesion extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed; // <-- permite null aquí ✅

  const BotonInicioSesion({
    required this.texto,
    this.onPressed, // <-- ya no es required
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed, // <-- Flutter maneja null automáticamente
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.botonInicioSesion,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
        elevation: 0,
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
