import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';
import 'package:nexus_ar/screens/logros_puntualidad.dart';
import 'package:nexus_ar/screens/menu.dart';
import 'package:nexus_ar/screens/logros_asistencia.dart';

class LogrosScreen extends StatefulWidget {
  const LogrosScreen({super.key});

  @override
  State<LogrosScreen> createState() => _LogrosScreenState();
}

class _LogrosScreenState extends State<LogrosScreen> {
  // Estas variables simulan la "n". 
  // Aquí cargarías los datos reales de tu base de datos o SharedPreferences
  int contadorPuntualidad = 0; 
  int contadorAsistencia = 0;

  @override
  void initState() {
    super.initState();
    // Aquí podrías llamar a una función para obtener los contadores reales
    // _cargarContadores();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle purpleButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: AppColors.botonInicioSesion,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      fixedSize: const Size(240, 120),
      elevation: 6,
    );

    // Estilo común para el texto debajo de los botones
    final TextStyle labelStyle = const TextStyle(
      color: Colors.white,
      fontSize: 14, // Tamaño ajustado para que quepa bien
      fontWeight: FontWeight.bold,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.botonInicioSesion,
        title: const Text(
          "Mis Logros",
          style: TextStyle(color: Colors.black, fontSize: 28),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const MenuScreen(initialIndex: 1),
              ),
              (route) => false,
            );
          },
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 60), // Reduje un poco este espacio inicial

                  // --- BOTÓN 1: PUNTUALIDAD ---
                  ElevatedButton(
                    style: purpleButtonStyle,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LogrosPuntualidadScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Logros de Puntualidad',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 10), // Pequeño espacio entre botón y texto

                  // --- TEXTO 1 ---
                  Text(
                    "Contador de Asistencias\nPerfectas Seguidas: $contadorPuntualidad",
                    textAlign: TextAlign.center,
                    style: labelStyle,
                  ),

                  // Espacio entre secciones (Reduje de 206 a 80 para que se vea mejor)
                  const SizedBox(height: 80),

                  // --- BOTÓN 2: ASISTENCIA ---
                  ElevatedButton(
                    style: purpleButtonStyle,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LogrosAsistenciaScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Logros de Asistencia',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 10),

                  // --- TEXTO 2 ---
                  Text(
                    "Contador de Asistencias\nCompletadas Seguidas: $contadorAsistencia",
                    textAlign: TextAlign.center,
                    style: labelStyle,
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}