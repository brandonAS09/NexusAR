import 'package:flutter/material.dart';
import 'package:nexus_ar/components/aviso_error.dart';
import 'package:nexus_ar/components/boton_inicio_sesion.dart';
import 'package:nexus_ar/components/datos_inicio_sesion.dart';
import 'package:nexus_ar/components/enlace_texto_is.dart';
import 'package:nexus_ar/core/app_colors.dart';
import 'package:nexus_ar/screens/registro.dart';
import 'package:nexus_ar/services/api_service.dart'; // ⭐️ IMPORTACIÓN DEL SERVICIO API

class InicioSesion extends StatefulWidget {
  const InicioSesion({super.key});

  @override
  State<InicioSesion> createState() => _InicioSesionState();
}

class _InicioSesionState extends State<InicioSesion> {
  // ⭐️ CONTROLADORES DE TEXTO: OBTENDRÁN LOS VALORES DEL FORMULARIO
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _errorActual;
  bool _isLoading = false;
  
  // Instancia del servicio API
  final _apiService = ApiService();

  // Regex de validación UABC (del backend)
  final RegExp _correoUabcRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@uabc\.edu\.mx$");

  // Mensajes de error específicos para el cliente (validación local)
  static const String _msgVacioCorreo = "El campo de correo electrónico se encuentra vacío.";
  static const String _msgVacioContrasena = "El campo de la contraseña se encuentra vacío.";
  static const String _msgNoInstitucional = "El correo debe ser institucional (uabc.edu.mx).";
  
  // ⭐️ LIMPIEZA DE CONTROLADORES AL DESTRUIR EL WIDGET
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

    // 2. VALIDACIÓN DE CLIENTE (Campos vacíos)
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
    
    // 3. VALIDACIÓN DE CLIENTE (Correo institucional UABC)
    // Esto se hace en el backend, pero es bueno validarlo aquí también para UX
    if (!_correoUabcRegex.hasMatch(correo)) {
      setState(() {
        _errorActual = _msgNoInstitucional;
        _isLoading = false;
      });
      return;
    }

    // 4. LLAMADA AL BACKEND
    try {
      final resultado = await _apiService.login(correo, password);

      // ÉXITO: El backend devolvió 200.
      print("Login Exitoso: Usuario ${resultado['usuario']['nombre']}");
      
      // Mostrar un mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡Bienvenido, ${resultado['usuario']['nombre']}!')),
      );
      
      // Aquí iría la navegación a la pantalla principal
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));

    } on Exception catch (e) {
      // 5. MANEJO DE ERRORES DEL BACKEND/CONEXIÓN
      // Limpiamos el prefijo "Exception: " si existe.
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      
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

              // Titulo
              const Text(
                "INICIAR SESION",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 50),

              // ⭐️ CAMPOS DE TEXTO: Pasamos los controladores
              DatosInicioSesion(
                correoController: _correoController,
                passwordController: _passwordController,
              ),

              // Aviso de error global
              if (hayError) AvisoError(mensaje: _errorActual!),

              // Espacio condicional (ajustado para que el botón se vea centrado verticalmente)
              SizedBox(height: hayError ? 40 : 120),

              // boton ingresar
              BotonInicioSesion(
                // Mostramos estado de carga
                texto: _isLoading ? "INGRESANDO..." : "INGRESAR",
                onPressed: _isLoading ? () {} : _iniciarSesion, // Deshabilitar si está cargando
              ),
              const SizedBox(height: 30),

              const Divider(color: Colors.white, thickness: 1),
              const SizedBox(height: 15),

              // enlace registrarse
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
