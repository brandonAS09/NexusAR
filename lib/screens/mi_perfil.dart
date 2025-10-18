import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexus_ar/core/app_colors.dart';
import 'package:nexus_ar/screens/legal.dart';

class MiPerfilScreen extends StatefulWidget {
  const MiPerfilScreen({super.key});

  @override
  State<MiPerfilScreen> createState() => _MiPerfilScreenState();
}

class _MiPerfilScreenState extends State<MiPerfilScreen> {
  String? _correoUsuario;

  @override
  void initState() {
    super.initState();
    _cargarCorreo();
  }

  Future<void> _cargarCorreo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _correoUsuario = prefs.getString('correo_usuario') ?? 'Correo no disponible';
    });
  }

  void _navigateToLegal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LegalScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.botonInicioSesion,
        title: const Text('Mi Perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            const Icon(Icons.account_circle_outlined,
                size: 150, color: AppColors.botonInicioSesion),
            const SizedBox(height: 10),
            const Text(
              'Mi Perfil',
              style: TextStyle(
                  fontSize: 44, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              'Correo: ${_correoUsuario ?? "Cargando..."}',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 300),
            const Divider(
              color: Colors.white,
              thickness: 2,
              indent: 50,
              endIndent: 50,
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.botonInicioSesion,
                padding:
                    const EdgeInsets.symmetric(horizontal: 100, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () => _navigateToLegal(context),
              child: const Text('Legal',
                  style: TextStyle(fontSize: 24, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
