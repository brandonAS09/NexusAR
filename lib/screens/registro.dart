import 'package:flutter/material.dart';
import 'package:nexus_ar/components/boton_inicio_sesion.dart';
import 'package:nexus_ar/components/campo_correo_registro.dart';
import 'package:nexus_ar/components/requisitos_contra.dart';
import 'package:nexus_ar/components/aviso_error.dart';
import 'package:nexus_ar/core/app_colors.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  bool _errorCorreoYaExiste = false;
  bool _errorContrasenaNoCoincide = false;
  bool _errorContrasenaNoCumpleRequisitos = false;
  bool _passwordVisible1 = false;
  bool _passwordVisible2 = false;

  void _togglePasswordVisibility1() {
    setState(() {
      _passwordVisible1 = !_passwordVisible1;
    });
  }

  void _togglePasswordVisibility2() {
    setState(() {
      _passwordVisible2 = !_passwordVisible2;
    });
  }

  // SIMULACIÓN DE REGISTRO Y ACTIVACIÓN DE ERRORES
  void _simularCrearCuenta() {
    setState(() {
      _errorCorreoYaExiste = false;
      _errorContrasenaNoCoincide = false;
      _errorContrasenaNoCumpleRequisitos = false;
    });

    // Esto simula que el backend regresa diferentes tipos de fallos.
    if (DateTime.now().second % 3 == 0) {
      // Error: Correo ya existe
      setState(() {
        _errorCorreoYaExiste = true;
      });
    } else if (DateTime.now().second % 3 == 1) {
      // Error: Contraseñas no coinciden
      setState(() {
        _errorContrasenaNoCoincide = true;
      });
    } else {
      // Error: Contraseña no cumple requisitos
      setState(() {
        _errorContrasenaNoCumpleRequisitos = true;
      });
    }
  }

  Widget _buildNormalField(String hintText) {
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
      contentPadding: const EdgeInsets.symmetric(
        vertical: 20.0,
        horizontal: 15.0,
      ),
      hintStyle: const TextStyle(color: Colors.white, fontSize: 16),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        obscureText: false,
        decoration: baseDecoration.copyWith(hintText: hintText),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildPasswordField(
    String hintText,
    bool isVisible,
    VoidCallback toggleVisibility,
  ) {
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
      contentPadding: const EdgeInsets.symmetric(
        vertical: 20.0,
        horizontal: 15.0,
      ),
      hintStyle: const TextStyle(color: Colors.white, fontSize: 16),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              obscureText: !isVisible,
              decoration: baseDecoration.copyWith(hintText: hintText),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 10.0),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                isVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.black,
                size: 28,
              ),
              onPressed: toggleVisibility,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // titulo
              const Text(
                "REGISTRO",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Usuario
              _buildNormalField("Nombre de Usuario"),

              const SizedBox(height: 15),

              // correo
              const CampoCorreoRegistro(),

              // ERROR: Correo ya registrado
              if (_errorCorreoYaExiste)
                const AvisoError(
                  mensaje:
                      "El correo que ingresaste ya está registrado. Intenta con otro.",
                ),

              const SizedBox(height: 25),

              // texto de requisitos contra
              const RequisitosContra(),

              // ingresar contra
              _buildPasswordField(
                "Contraseña",
                _passwordVisible1,
                _togglePasswordVisibility1,
              ),

              // repetir contra
              _buildPasswordField(
                "Repetir Contraseña",
                _passwordVisible2,
                _togglePasswordVisibility2,
              ),

              // ERROR: Contraseña no cumple con requisitos
              if (_errorContrasenaNoCumpleRequisitos)
                const AvisoError(
                  mensaje:
                      "La contraseña no cumple con los requerimientos. Intenta de nuevo.",
                ),

              if (!_errorContrasenaNoCumpleRequisitos)
                const SizedBox(height: 15),

              // ERROR: Contraseñas no coinciden
              if (_errorContrasenaNoCoincide)
                const AvisoError(
                  mensaje: "La contraseña no concuerda. Intenta de nuevo.",
                ),

              const SizedBox(height: 40),

              // linea
              const Divider(color: Colors.white, thickness: 1),

              const SizedBox(height: 30),

              // boton Crear Cuenta
              BotonInicioSesion(
                texto: 'Crear Cuenta',
                onPressed: _simularCrearCuenta,
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
