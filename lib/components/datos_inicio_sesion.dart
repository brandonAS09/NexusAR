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
      enabledBorder: const OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: AppColors.fieldTextColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
      hintStyle: const TextStyle(color: Colors.white70, fontSize: 16),
    );

    return Column(
      children: [
        // Campo de correo
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TextField(
            decoration: baseDecoration.copyWith(
              hintText: "Correo Electrónico",
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        // Campo de contraseña
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  obscureText: !_passwordVisible,
                  decoration: baseDecoration.copyWith(
                    hintText: "Contraseña",
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 10.0),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    _passwordVisible ? Icons.visibility_off : Icons.visibility,
                    color: Colors.black,
                    size: 28,
                  ),
                  onPressed: _togglePasswordVisibility,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}