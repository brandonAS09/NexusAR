import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';
import 'package:nexus_ar/components/boton_inicio_sesion.dart';
import 'package:nexus_ar/components/requisitos_contra.dart';
import 'package:nexus_ar/components/aviso_error.dart';
import 'package:nexus_ar/services/api_service.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final ApiService _apiService = ApiService();

  String? _errorCorreo;
  String? _errorContrasena;
  bool _passwordVisible = false;
  bool _isLoading = false;

  // Mensajes
  static const String _msgVacio = "Este campo no puede estar vacío";
  static const String _msgNoInstitucional =
      "El correo debe ser institucional (uabc.edu.mx)";
  static const String _msgNoCumpleRequisitos =
      "La contraseña debe tener al menos 8 caracteres, una mayúscula, una minúscula y un número";
  static const String _msgCorreoYaExiste =
      "El correo ya se encuentra registrado";

  // Regex
  final RegExp _correoUabcRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@uabc\.edu\.mx$');
  final RegExp _passwordRegex =
      RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d).{8,}$');

  void _togglePasswordVisibility() {
    setState(() {
      _passwordVisible = !_passwordVisible;
    });
  }

  Future<void> _registrarUsuario() async {
    setState(() {
      _errorCorreo = null;
      _errorContrasena = null;
    });

    final correo = _correoController.text.trim();
    final password = _passwordController.text.trim();

    // Validaciones locales
    if (correo.isEmpty) {
      setState(() => _errorCorreo = _msgVacio);
      return;
    }
    if (!_correoUabcRegex.hasMatch(correo)) {
      setState(() => _errorCorreo = _msgNoInstitucional);
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorContrasena = _msgVacio);
      return;
    }
    if (!_passwordRegex.hasMatch(password)) {
      setState(() => _errorContrasena = _msgNoCumpleRequisitos);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final respuesta = await _apiService.register(correo, password);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(respuesta['mensaje'] ?? 'Usuario registrado exitosamente 🎉'),
          backgroundColor: Colors.green,
        ),
      );

      _correoController.clear();
      _passwordController.clear();
    } catch (e) {
      final mensaje = e.toString();

      if (mensaje.contains("registrado")) {
        setState(() => _errorCorreo = _msgCorreoYaExiste);
      } else if (mensaje.contains("institucional")) {
        setState(() => _errorCorreo = _msgNoInstitucional);
      } else if (mensaje.contains("contraseña")) {
        setState(() => _errorContrasena = _msgNoCumpleRequisitos);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $mensaje"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Campo de contraseña (con icono de mostrar/ocultar)
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
      contentPadding:
          const EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
      hintStyle: const TextStyle(color: Colors.white, fontSize: 16),
    );

    final bool mostrarError = _errorContrasena != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _passwordController,
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
          if (mostrarError) AvisoError(mensaje: _errorContrasena!),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hintText) {
    const borderRadius = BorderRadius.all(Radius.circular(10.0));
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
      fillColor: AppColors.fieldTextColor,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
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
              TextField(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                decoration: _buildInputDecoration("Correo Electrónico"),
                style: const TextStyle(color: Colors.white),
              ),
              if (hayErrorCorreo) AvisoError(mensaje: _errorCorreo!),
              const SizedBox(height: 25),
              const RequisitosContra(),
              _buildPasswordField(),
              const SizedBox(height: 40),
              const Divider(color: Colors.white, thickness: 1),
              const SizedBox(height: 30),
              BotonInicioSesion(
                texto: _isLoading ? "Creando..." : "Crear Cuenta",
                onPressed: _isLoading ? () {} : _registrarUsuario,
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
