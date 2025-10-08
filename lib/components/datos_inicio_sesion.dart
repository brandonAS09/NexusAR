import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';

class DatosInicioSesion extends StatefulWidget {
  const DatosInicioSesion({super.key});

  @override
  State<DatosInicioSesion> createState() => _DatosInicioSesionState();
}

class _DatosInicioSesionState extends State<DatosInicioSesion> {
  bool _passwordVisible = false;

  void _togglePasswordVisibility() {
    setState(() {
      _passwordVisible = !_passwordVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(10.0));

    final baseDecoration = InputDecoration(
      border: InputBorder.none,
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: AppColors.fieldTextColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
      hintStyle: const TextStyle(color: Colors.white, fontSize: 16),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        children: [
          // Campo de correo
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextField(
              decoration: baseDecoration.copyWith(
                hintText: "Ingresa tu correo",
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          // Campo de contraseña
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextField(
              obscureText: !_passwordVisible,
              decoration: baseDecoration.copyWith(
                hintText: "Ingresa tu contraseña",
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.black,
                  ),
                  onPressed: _togglePasswordVisibility,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}