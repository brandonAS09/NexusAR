import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';

class EnlaceTextoIs extends StatelessWidget{
  final String textoPrincipal;
  final String textoEnlace;
  final VoidCallback onTap;
  final MainAxisAlignment alineacion;

  const EnlaceTextoIs({
    required this.textoPrincipal,
    required this.textoEnlace,
    required this.onTap,
    this.alineacion = MainAxisAlignment.start,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alineacion,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          textoPrincipal,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onTap,
          child: Text(
            textoEnlace,
            style: TextStyle(
              color: AppColors.textoEnlace,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.textoEnlace
            ),
          ),
        )
      ],
    );
  }
}