import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.botonInicioSesion,
        title: const Text('Términos Legales'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Text(
          'Legal',
          style: TextStyle(
          fontSize: 64,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          ),
        ),
      ),
    );
  }
}
