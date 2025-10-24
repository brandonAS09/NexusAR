import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';

class RutasBoton extends StatefulWidget {
  final void Function(String)? onRutaSeleccionada;

  const RutasBoton({super.key, this.onRutaSeleccionada});

  @override
  State<RutasBoton> createState() => _RutasBotonState();
}

class _RutasBotonState extends State<RutasBoton> {
  String? _rutaSeleccionada;

  final List<String> _rutas = [
    'E1',
    'E2',
    'E3',
    'E4',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      width: 85,
      decoration: BoxDecoration(
        color: AppColors.botonInicioSesion,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _rutaSeleccionada,
          dropdownColor: Colors.white,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Colors.black,
            size: 30,
          ),
          borderRadius: BorderRadius.circular(10),
          items: _rutas.map((ruta) {
            return DropdownMenuItem<String>(
              value: ruta,
              child: Text(
                ruta,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            );
          }).toList(),
          onChanged: (String? value) {
            setState(() {
              _rutaSeleccionada = value;
            });
            if (value != null && widget.onRutaSeleccionada != null) {
              widget.onRutaSeleccionada!(value);
            }
          },
          hint: const Icon(
            Icons.route_outlined,
            color: Colors.black,
            size: 40,
          ),
        ),
      ),
    );
  }
}
