import 'package:flutter/material.dart';
import 'package:nexus_ar/components/datos_inicio_sesion.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: InicioSesion(),
      )
    );
  }
}