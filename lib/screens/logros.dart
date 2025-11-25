import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexus_ar/core/app_colors.dart';
import 'package:nexus_ar/screens/logros_puntualidad.dart'; 
import 'package:nexus_ar/screens/menu.dart';
import 'package:nexus_ar/screens/logros_asistencia.dart';
import 'package:nexus_ar/services/logros_service.dart';

class LogrosScreen extends StatefulWidget {
  const LogrosScreen({super.key});

  @override
  State<LogrosScreen> createState() => _LogrosScreenState();
}

class _LogrosScreenState extends State<LogrosScreen> {
  final LogrosService _service = LogrosService();

  int contadorPuntualidad = 0; 
  int contadorAsistencia = 0;  
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarContadores();
  }

  Future<void> _cargarContadores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? email = prefs.getString('email_usuario');

      if (email != null) {
        // 1. Obtener ID a partir del email
        final int? idUsuario = await _service.obtenerIdPorEmail(email);
        
        if (idUsuario != null) {
          // 2. Obtener Racha usando el ID
          final resultado = await _service.obtenerRacha(idUsuario);
          
          if (mounted && resultado['success'] == true) {
            setState(() {
              // Actualizamos AMBOS contadores según el JSON del backend
              contadorAsistencia = resultado['racha_asistencia'];
              contadorPuntualidad = resultado['racha_puntualidad'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error cargando logros: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Estilos reutilizables
    final ButtonStyle purpleButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: AppColors.botonInicioSesion,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      fixedSize: const Size(240, 120),
      elevation: 6,
    );

    final TextStyle labelStyle = const TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.botonInicioSesion,
        title: const Text("Mis Logros", style: TextStyle(color: Colors.black, fontSize: 28)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MenuScreen(initialIndex: 1)),
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            // PASAMOS LA RACHA ACTUAL COMO PARÁMETRO
                            builder: (context) => LogrosPuntualidadScreen(
                              rachaActual: contadorPuntualidad
                            ),
                          ),
                        ).then((_) {
                           // Opcional: Recargar al volver si quisieras refrescar datos
                           _cargarContadores();
                        });
                      },
                      child: const Text(
                        'Logros de Puntualidad',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Contador de Asistencias\nPerfectas Seguidas: $contadorPuntualidad",
                      textAlign: TextAlign.center,
                      style: labelStyle,
                    ),

                    const SizedBox(height: 80),

                    // --- BOTÓN 2: ASISTENCIA ---
                    ElevatedButton(
                      style: purpleButtonStyle,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            // PASAMOS LA RACHA ACTUAL COMO PARÁMETRO
                            builder: (context) => LogrosAsistenciaScreen(
                              rachaActual: contadorAsistencia
                            ),
                          ),
                        ).then((_) {
                           _cargarContadores();
                        });
                      },
                      child: const Text(
                        'Logros de Asistencia',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 10),
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