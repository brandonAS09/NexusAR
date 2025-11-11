import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';
import 'package:nexus_ar/screens/menu.dart';
import 'package:nexus_ar/screens/qr.dart';

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

  Future<void> _openQrScanner() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const ScanQrScreen()),
    );

    if (result != null && mounted) {
      // Por ahora mostramos un dialog con el valor escaneado.
      // Más adelante aquí llamaremos al backend /attendance/start y mostraremos el modal solicitado.
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('QR detectado'),
          content: Text('Contenido: $result'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      // El usuario salió sin escanear o canceló
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escaneo cancelado o no se detectó QR')),
      );
    }
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
        title: const Text('Asistencia'),
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
              const SizedBox(height: 80),
              ElevatedButton(
                style: purpleButtonStyle,
                onPressed: _openQrScanner,
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
              ElevatedButton(
                style: purpleButtonStyle,
                onPressed: () {
                  // Aquí irá la pantalla de registro de asistencias
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