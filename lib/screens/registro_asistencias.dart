//import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';
import 'package:nexus_ar/screens/menu.dart';

class RegistroAsistenciasScreen extends StatefulWidget {
  const RegistroAsistenciasScreen({super.key});

  @override
  State<RegistroAsistenciasScreen> createState() => _RegistroAsistenciasScreenState();
}

class _RegistroAsistenciasScreenState extends State<RegistroAsistenciasScreen> {
  
  final bool _isLoading = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle purpleButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: AppColors.botonInicioSesion,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      fixedSize: const Size(240, 120),
      elevation: 6,
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
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : Stack(
          children: [
            SafeArea(
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    // --- BOTÓN 1: PUNTUALIDAD ---
                    ElevatedButton(
                      style: purpleButtonStyle,
                      onPressed: () {
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

                    const SizedBox(height: 80),

                    // --- BOTÓN 2: ASISTENCIA (RACHA) ---
                    ElevatedButton(
                      style: purpleButtonStyle,
                      onPressed: () {
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