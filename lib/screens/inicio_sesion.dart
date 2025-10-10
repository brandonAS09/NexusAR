import 'package:flutter/material.dart';
import 'package:nexus_ar/components/aviso_error.dart';
import 'package:nexus_ar/components/boton_inicio_sesion.dart';
import 'package:nexus_ar/components/datos_inicio_sesion.dart';
import 'package:nexus_ar/components/enlace_texto_is.dart';
import 'package:nexus_ar/core/app_colors.dart';
import 'package:nexus_ar/screens/registro.dart';
import 'package:nexus_ar/screens/menu.dart';
import 'package:nexus_ar/services/api_service.dart';

class InicioSesion extends StatefulWidget {
  const InicioSesion({super.key});

  @override
  State<InicioSesion> createState() => _InicioSesionState();
}

class _InicioSesionState extends State<InicioSesion> {
  // Controladores de texto: obtendrán los valores del formulario
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _errorActual;
  bool _isLoading = false;

  // Instancia del servicio API
  final _apiService = ApiService();

  // Regex de validación UABC (del backend)
  final RegExp _correoUabcRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@uabc\.edu\.mx$");

  // Mensajes de error específicos para el cliente (validación local)
  static const String _msgVacioCorreo =
      "Por favor, ingresa tu correo electrónico.";
  static const String _msgVacioContrasena = "Por favor, ingresa tu contraseña.";
  static const String _msgNoInstitucional =
      "El correo electrónico debe ser institucional (@uabc.edu.mx).";

  // Limpieza de controladores al destruir el widget
  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    // 1. Limpiar errores y establecer estado de carga
    setState(() {
      _errorActual = null;
      _isLoading = true;
    });

    final correo = _correoController.text.trim();
    final password = _passwordController.text;

    // 2. Validación de cliente (campos vacíos)
    if (correo.isEmpty) {
      setState(() {
        _errorActual = _msgVacioCorreo;
        _isLoading = false;
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _errorActual = _msgVacioContrasena;
        _isLoading = false;
      });
      return;
    }

    // 3. Validación de correo institucional UABC
    if (!_correoUabcRegex.hasMatch(correo)) {
      setState(() {
        _errorActual = _msgNoInstitucional;
        _isLoading = false;
      });
      return;
    }

    // 4. Llamada al backend
    try {
      final resultado = await _apiService.login(correo, password);

      // Éxito: El backend devolvió 200
      print("Login Exitoso: Usuario ${resultado['usuario']['nombre']}");

      // Mostrar un mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Bienvenido, ${resultado['usuario']['nombre']}!'),
        ),
      );

      // 🚀 Navegación exitosa al menú
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MenuScreen()),
      );
    } on Exception catch (e) {
      String errorMessage = e.toString();

      // 1. Eliminar prefijos del sistema
      errorMessage = errorMessage
          .replaceFirst('Exception: ', '')
          .replaceFirst('Exception', '')
          .trim();

      // 2. Eliminar prefijo del servidor si existe
      const serverPrefix = "Fallo al conectar con el servidor. :";
      if (errorMessage.startsWith(serverPrefix)) {
        errorMessage = errorMessage.replaceFirst(serverPrefix, '').trim();
      }

      // 3. Normalizar mensaje si contiene "contraseña incorrecta"
      if (errorMessage.toLowerCase().contains('contraseña incorrecta')) {
        errorMessage = 'Contraseña incorrecta';
      }

      setState(() {
        _errorActual = errorMessage;
      });
    } finally {
      // 6. Finalizar carga
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _goToRegistro() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistroScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hayError = _errorActual != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Título
              const Text(
                "INICIAR SESIÓN",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 50),

              // Campos de texto
              DatosInicioSesion(
                correoController: _correoController,
                passwordController: _passwordController,
              ),

              // Aviso de error
              if (hayError) AvisoError(mensaje: _errorActual!),

              // Espaciado
              SizedBox(height: hayError ? 40 : 120),

              // Botón ingresar
              BotonInicioSesion(
                texto: _isLoading ? "INGRESANDO..." : "INGRESAR",
                onPressed: _isLoading ? () {} : _iniciarSesion,
              ),

              const SizedBox(height: 30),

              const Divider(color: Colors.white, thickness: 1),
              const SizedBox(height: 15),

              // Enlace registro
              EnlaceTextoIs(
                textoPrincipal: "¿No tienes cuenta?",
                textoEnlace: "Regístrate aquí",
                onTap: _goToRegistro,
                alineacion: MainAxisAlignment.center,
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
