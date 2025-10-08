import 'package:flutter/material.dart';
import 'package:nexus_ar/components/aviso_error.dart';
import 'package:nexus_ar/components/boton_inicio_sesion.dart';
import 'package:nexus_ar/components/datos_inicio_sesion.dart';
import 'package:nexus_ar/components/enlace_texto_is.dart';

class InicioSesion extends StatefulWidget {
  const InicioSesion({super.key});

  @override
  State<InicioSesion> createState() => _InicioSesionState();
}

class _InicioSesionState extends State<InicioSesion> {
  bool _mostrarError = false;
  final String _mensajeError =
      "El correo o la contraseña son incorrectos. Por favor intentelo de nuevo.";

  void _simularLogin() {
    setState(() {
      _mostrarError = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            // Texto de la parte de arriba
            const Text(
              "INICIAR SESION",
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 50),
            // Campos de texto
            const DatosInicioSesion(),
            if (_mostrarError) AvisoError(mensaje: _mensajeError),

            if (!_mostrarError)
              const SizedBox(height: 150),

            // Boton ingresar
            BotonInicioSesion(texto: "Ingresar", onPressed: _simularLogin),
            const SizedBox(height: 30),

            const Divider(color: Colors.white, thickness: 1),
            const SizedBox(height: 15),

            // Enlace registrarse
            EnlaceTextoIs(
              textoPrincipal: "No tienes cuenta?",
              textoEnlace: "Registrate aquí",
              onTap: () {},
              alineacion: MainAxisAlignment.center,
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
