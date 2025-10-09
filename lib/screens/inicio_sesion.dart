import 'package:flutter/material.dart';
import 'package:nexus_ar/components/aviso_error.dart';
import 'package:nexus_ar/components/boton_inicio_sesion.dart';
import 'package:nexus_ar/components/datos_inicio_sesion.dart';
import 'package:nexus_ar/components/enlace_texto_is.dart';
import 'package:nexus_ar/screens/registro.dart';

class InicioSesion extends StatefulWidget {
  const InicioSesion({super.key});

  @override
  State<InicioSesion> createState() => _InicioSesionState();
}

class _InicioSesionState extends State<InicioSesion> {
  String? _errorActual;
  static const String _msgVacioCorreo =
      "El campo de correo electronico se encuentra vacio. Por favor intentelo de nuevo.";
  static const String _msgVacioContrasena =
      "El campo de la contraseña se encuentra vacio. Por favor intentelo de nuevo.";
  static const String _msgNoInstitucional =
      "El correo electronico debe ser institucional (uabc.edu.mx). Por favor intentelo de nuevo.";
  static const String _msgNoRegistrado =
      "Este correo electronico no se encuentra registrado.";
  static const String _msgContrasenaIncorrecta =
      "La contraseña es incorrecta. Por favor intentelo de nuevo.";

  void _simularLogin() {
    setState(() {
      _errorActual = null;

      final int modulo = DateTime.now().second % 5;

      switch (modulo) {
        case 0:
          _errorActual = _msgVacioCorreo;
          break;
        case 1:
          _errorActual = _msgVacioContrasena;
          break;
        case 2:
          _errorActual = _msgNoInstitucional;
          break;
        case 3:
          _errorActual = _msgNoRegistrado;
          break;
        case 4:
          _errorActual = _msgContrasenaIncorrecta;
          break;
      }
    });
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

    return SingleChildScrollView(
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

            // Campos de texto
            const DatosInicioSesion(),

            if (hayError) AvisoError(mensaje: _errorActual!),

            if (!hayError) const SizedBox(height: 150),

            SizedBox(height: 100,),
            // boton ingresar
            BotonInicioSesion(texto: "Ingresar", onPressed: _simularLogin),
            const SizedBox(height: 30),

            const Divider(color: Colors.white, thickness: 1),
            const SizedBox(height: 15),

            // enlace registrarse
            EnlaceTextoIs(
              textoPrincipal: "No tienes cuenta?",
              textoEnlace: "Registrate aquí",
              onTap: _goToRegistro,
              alineacion: MainAxisAlignment.center,
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}