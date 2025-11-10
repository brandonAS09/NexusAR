import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';
import 'package:nexus_ar/screens/menu.dart';

class AsistenciaScreen extends StatefulWidget {
  const AsistenciaScreen({super.key});

  @override
  State<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends State<AsistenciaScreen> {
  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    // botón estilo reutilizable para que coincida con la imagen
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
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              // Espacio antes de botones para parecerse al mock
              const SizedBox(height: 80),
              // Primer botón (no hace nada por ahora)
              ElevatedButton(
                style: purpleButtonStyle,
                onPressed: () {
                  // Intencionalmente vacío por ahora
                },
                child: const Text(
                  'Asistencia\ncon QR',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 206),

              // Segundo botón (no hace nada por ahora)
              ElevatedButton(
                style: purpleButtonStyle,
                onPressed: () {
                  // Intencionalmente vacío por ahora
                },
                child: const Text(
                  'Registro de\nAsistencias',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // Relleno para empujar contenido hacia arriba si la pantalla es grande
              const Spacer(),
              const Divider(
                color: Colors.white54,
                thickness: 1,
                indent: 50,
                endIndent: 50,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}