import 'package:flutter/material.dart';
import 'package:nexus_ar/services/api_service.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({Key? key}) : super(key: key);

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _errorCorreo;
  String? _errorContrasena;

  // Expresiones regulares
  final RegExp _correoUabcRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@uabc\.edu\.mx$');
  final RegExp _passwordRegex =
      RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d).{8,}$');

  // Mensajes de error
  final String _msgVacio = 'Este campo no puede estar vacío';
  final String _msgNoInstitucional = 'Usa un correo institucional de la UABC';
  final String _msgNoCumpleRequisitos =
      'La contraseña debe tener mínimo 8 caracteres, una mayúscula y un número';
  final String _msgCorreoYaExiste = 'El correo ya está registrado';

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _registrarUsuario() async {
    setState(() {
      _errorCorreo = null;
      _errorContrasena = null;
    });

    final correo = _correoController.text.trim();
    final password = _passwordController.text.trim();

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
          content: Text(respuesta['mensaje'] ?? 'Usuario registrado exitosamente 🎉'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Text(
                  "Crear cuenta",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),

                // Campo de correo
                TextField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo institucional',
                    labelStyle: const TextStyle(color: Colors.white),
                    errorText: _errorCorreo,
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),

                // Campo de contraseña
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: const TextStyle(color: Colors.white),
                    errorText: _errorContrasena,
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 30),

                // Botón de registro
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registrarUsuario,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.greenAccent[400],
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                            'Registrarse',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "¿Ya tienes una cuenta? Inicia sesión",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
