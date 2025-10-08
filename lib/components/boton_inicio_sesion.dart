import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';

class BotonInicioSesion extends StatelessWidget{
  final String texto;
  final VoidCallback onPressed;

  const BotonInicioSesion({
    required this.texto,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.botonInicioSesion,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
        elevation: 0
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white
        ),
      ),
    );
  }
}