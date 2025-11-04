import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';

class RutasBoton extends StatefulWidget {
  final void Function(String)? onRutaSeleccionada;

  const RutasBoton({super.key, this.onRutaSeleccionada});

  @override
  State<RutasBoton> createState() => _RutasBotonState();
}

class _RutasBotonState extends State<RutasBoton> {
  Map<String, dynamic>? _rutaSeleccionada;

  // Lista con 'nombre' mostrado y 'id' enviado
  final List<Map<String, dynamic>> _rutas = [
    {'nombre': 'Ninguna', 'id': null},
    {'nombre': 'E1', 'id': 1},
    {'nombre': 'E3', 'id': 3},
    {'nombre': 'E4', 'id': 4},
    {'nombre': 'E5', 'id': 5},
    {'nombre': 'E6', 'id': 6},
    {'nombre': 'E7', 'id': 7},
    {'nombre': 'E8', 'id': 8},
    {'nombre': 'E9', 'id': 9},
    {'nombre': 'E10', 'id': 10},
    {'nombre': 'E11', 'id': 11},
    {'nombre': 'E12', 'id': 12},
    {'nombre': 'E13', 'id': 13},
    {'nombre': 'E14', 'id': 14},
    {'nombre': 'E15', 'id': 15},
    {'nombre': 'E16', 'id': 16},
    {'nombre': 'E17', 'id': 17},
    {'nombre': 'E18', 'id': 18},
    {'nombre': 'E19', 'id': 19},
    {'nombre': 'E20', 'id': 20},
    {'nombre': 'E21', 'id': 21},
    {'nombre': 'E26', 'id': 26},
    {'nombre': 'E31', 'id': 31},
    {'nombre': 'E33', 'id': 33},
    {'nombre': 'E34', 'id': 34},
    {'nombre': 'E35', 'id': 35},
    {'nombre': 'E36', 'id': 36},
    {'nombre': 'E37', 'id': 37},
    {'nombre': 'E40', 'id': 40},
    {'nombre': 'E41', 'id': 41},
    {'nombre': 'E45', 'id': 45},
    {'nombre': 'E51', 'id': 51},
    {'nombre': 'E55', 'id': 55},
    {'nombre': 'E57', 'id': 57},
    {'nombre': 'Biblioteca', 'id': 94},
    {'nombre': 'Cafeteria', 'id': 92},
    {'nombre': 'Gimnasio', 'id': 91},
    {'nombre': 'Sorteos', 'id': 93},
    {'nombre': 'Jacuzzi de las tortugas', 'id': 95},
    // Agrega aquí más edificios si es necesario
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      width: 140,
      decoration: BoxDecoration(
        color: AppColors.botonInicioSesion,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
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
            return DropdownMenuItem<Map<String, dynamic>>(
              value: ruta,
              child: Text(
                ruta['nombre'],
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            );
          }).toList(),
          onChanged: (Map<String, dynamic>? value) {
            setState(() {
              _rutaSeleccionada = value;
            });
            if (widget.onRutaSeleccionada != null && value != null) {
              widget.onRutaSeleccionada!(
                value['id'] == null ? 'Ninguna' : value['id'].toString()
              );
            }
          },
          hint: const Icon(Icons.route_outlined, color: Colors.black, size: 40),
        ),
      ),
    );
  }
}