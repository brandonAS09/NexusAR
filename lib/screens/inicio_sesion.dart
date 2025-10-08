import 'package:flutter/material.dart';
import 'package:nexus_ar/components/datos_inicio_sesion.dart';

class InicioSesion extends StatefulWidget {
  const InicioSesion({super.key});

  @override
  State<InicioSesion> createState() => _InicioSesionState();
}

class _InicioSesionState extends State<InicioSesion> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
          // Texto de la parte de arriba
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 70),
              Text(
                "INICIAR SESION",
                style: TextStyle(color: Colors.white, fontSize: 32),
              ),
              SizedBox(height: 50),
              DatosInicioSesion(),
            ],
          ),
      ],
    );
  }
}
