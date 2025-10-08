import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';

class AvisoError extends StatelessWidget {
  final String mensaje;
  const AvisoError({
    required this.mensaje,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Contenedor del mensaje
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.cuadroError,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.bordeCuadroError,
          width: 1.5
        ),
        boxShadow:[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2)
          ),
        ],
      ),
      // Mensaje de error
      child: Text(
        mensaje,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 14
        ),
      ),
    );
  }
}