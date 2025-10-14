import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';

// Widget reutilizable para mostrar un texto en el centro de la pantalla.
class ContentPage extends StatelessWidget {
  final String title;

  const ContentPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundColor,
      child: Center(
        child: Padding(
          // Padding superior extra para que el texto no choque con el CustomAppBar
          padding: const EdgeInsets.only(top: 0.0, left: 50.0, right: 50.0), 
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}
