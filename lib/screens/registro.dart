import 'package:flutter/material.dart';
import 'package:nexus_ar/components/boton_inicio_sesion.dart';
import 'package:nexus_ar/components/requisitos_contra.dart';
import 'package:nexus_ar/components/aviso_error.dart';
import 'package:nexus_ar/core/app_colors.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  String? _errorCorreo;
  String? _errorContrasena;
  bool _passwordVisible = false; 
  static const String _msgVacio = "Este campo no puede estar vacío";
  static const String _msgNoInstitucional = "El correo debe ser institucional (uabc.edu.mx)";
  static const String _msgNoCumpleRequisitos = "La contraseña no cumple con los requisitos";
  static const String _msgCorreoYaExiste = "El correo ya se encuentra registrado";


  void _togglePasswordVisibility() {
    setState(() {
      _passwordVisible = !_passwordVisible;
    });
  }

  void _simularCrearCuenta() {
    setState(() {
      _errorCorreo = null;
      _errorContrasena = null;
    });

    final int modulo = DateTime.now().second % 5;

    switch (modulo) {
      case 0: // Error 1: Campo Correo Vacío
        setState(() { _errorCorreo = _msgVacio; });
        break;
      case 1: // Error 2: Correo No Institucional
        setState(() { _errorCorreo = _msgNoInstitucional; });
        break;
      case 2: // Error 3: Correo ya registrado
        setState(() { _errorCorreo = _msgCorreoYaExiste; }); 
        break;
      case 3: // Error 4: Contraseña Vacía 
        setState(() { _errorContrasena = _msgVacio; });
        break;
      case 4: // Error 5: Contraseña no cumple requisitos
        setState(() { _errorContrasena = _msgNoCumpleRequisitos; }); 
        break;
    }
  }

  Widget _buildPasswordField() {
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

    final bool mostrarErrorContrasena = _errorContrasena != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  obscureText: !_passwordVisible,
                  decoration: baseDecoration.copyWith(
                    hintText: "Contraseña", 
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible ? Icons.visibility_off : Icons.visibility,
                        color: Colors.black, 
                        size: 28,
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          if (mostrarErrorContrasena)
            AvisoError(mensaje: _errorContrasena!),
        ],
      ),
    );
  }
  InputDecoration _buildInputDecoration({
    required String hintText,
    required bool isError,
    String? errorMessage,
  }) {
    const borderRadius = BorderRadius.all(Radius.circular(10.0));
    Color fillColor = AppColors.fieldTextColor;
    
    return InputDecoration(
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
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 20.0,
        horizontal: 15.0,
      ),
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white, fontSize: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hayErrorCorreo = _errorCorreo != null;

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

              const SizedBox(height: 50), 

              // Correo Electrónico
              TextField(
                keyboardType: TextInputType.emailAddress,
                decoration: _buildInputDecoration(
                  hintText: "Correo Electrónico",
                  isError: hayErrorCorreo,
                  errorMessage: _errorCorreo,
                ),
                style: const TextStyle(color: Colors.white),
              ),
              
              // Aviso de error del correo
              if (hayErrorCorreo)
                AvisoError(mensaje: _errorCorreo!),

              const SizedBox(height: 25), 

              // texto de requisitos contra
              const RequisitosContra(),

              // ingresar contra
              _buildPasswordField(), 

              const SizedBox(height: 40),

              // linea divisoria
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