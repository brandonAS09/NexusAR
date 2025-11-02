import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';

/// Botón dropdown para seleccionar el edificio destino
class RutasBoton extends StatefulWidget {
  final void Function(String)? onRutaSeleccionada;

  const RutasBoton({super.key, this.onRutaSeleccionada});

  @override
  State<RutasBoton> createState() => _RutasBotonState();
}

class _RutasBotonState extends State<RutasBoton> {
  String? _rutaSeleccionada;

  // Agrega aquí todas las opciones de edificios/rutas
  final List<String> _rutas = [
    'E1', 'E2', 'E3', 'E4', 'E5', 'E6', 'E7', 'E8', 'E9', 'E10',
    'E11', 'E12', 'E13', 'E14', 'E15', 'E16', 'E17', 'E18', 'E19', 'E20',
    'E21', 'E22', 'E23', 'E24', 'E25', 'E26', 'E27', 'E28', 'E29', 'E30',
    'Biblioteca', 'Cafeteria', 'Laboratorio', 'Auditorio', 'Estacionamiento', 'Administracion'
    // Puedes agregar más nombres según tus edificios/rutas
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      width: 120,
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
          isExpanded: true,
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