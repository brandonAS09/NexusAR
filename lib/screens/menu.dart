import 'package:flutter/material.dart';

class MenuScreen extends StatelessWidget {
  // Constructor con la key opcional
  const MenuScreen({super.key});

  // El método build define la estructura de la pantalla
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Título de la barra de aplicaciones.
        // Flutter añade automáticamente el botón de "Atrás" si se navega.
        title: const Text('Menú Principal'),
        backgroundColor: Colors.indigo, // Color de la barra
      ),
      body: const Center(
        // El widget Center asegura que el texto esté en el medio de la pantalla
        child: Text(
          'Menú', // El texto simple
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900, // Extra-negrita
            color: Colors.black87,
            letterSpacing: 2.0,
          ),
        ),
      ),
      backgroundColor: Colors.white, // Color de fondo de la pantalla
    );
  }
}