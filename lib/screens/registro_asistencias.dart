import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart'; // Usamos tus colores definidos

class RegistroAsistenciasScreen extends StatefulWidget {
  const RegistroAsistenciasScreen({super.key});

  @override
  State<RegistroAsistenciasScreen> createState() => _RegistroAsistenciasScreenState();
}

class _RegistroAsistenciasScreenState extends State<RegistroAsistenciasScreen> {
  // Variables para los filtros
  String? selectedMes;
  String? selectedDia;

  // Listas para los dropdowns
  final List<String> meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  List<String> get dias {
    // Generamos lista de días del 1 al 31
    return List.generate(31, (index) => (index + 1).toString());
  }

  // DATOS DE PRUEBA (Mocks)
  // Aquí es donde después conectarás tu backend.
  // Como quitamos "Estado", solo dejamos Materia y Fecha.
  final List<Map<String, String>> asistenciasMock = [
    {
      'materia': 'Patrones de Software',
      'fecha': '2/12/2025',
    },
    {
      'materia': 'Programación Avanzada',
      'fecha': '3/12/2025',
    },
    {
      'materia': 'Base de Datos II',
      'fecha': '5/12/2025',
    },
    {
      'materia': 'Inteligencia Artificial',
      'fecha': '6/12/2025',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2C35), // Fondo gris oscuro/negro similar a tu imagen
      appBar: AppBar(
        backgroundColor: AppColors.botonInicioSesion, // Morado
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          "Mis Asistencias",
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // SECCIÓN DE FILTROS (DROPDOWNS)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDropdown("Mes", meses, selectedMes, (val) {
                  setState(() => selectedMes = val);
                }),
                _buildDropdown("Dia", dias, selectedDia, (val) {
                  setState(() => selectedDia = val);
                }),
              ],
            ),
          ),

          // LISTA DE TARJETAS
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: asistenciasMock.length,
              itemBuilder: (context, index) {
                final item = asistenciasMock[index];
                return _buildAsistenciaCard(
                  materia: item['materia']!,
                  fecha: item['fecha']!,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET DEL DROPDOWN PERSONALIZADO
  Widget _buildDropdown(String hint, List<String> items, String? value, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: AppColors.botonInicioSesion, // Fondo Morado
        borderRadius: BorderRadius.circular(10),
      ),
      width: 140,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
          dropdownColor: Colors.white, // Fondo del menú desplegable
          style: const TextStyle(color: Colors.black, fontSize: 16),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // WIDGET DE LA TARJETA DE ASISTENCIA
  Widget _buildAsistenciaCard({required String materia, required String fecha}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.botonInicioSesion, // Fondo Morado
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ÍCONO (Libro abierto o similar)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: const Icon(Icons.menu_book, color: Colors.black, size: 24),
          ),
          
          const SizedBox(width: 15),

          // TEXTOS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.class_, "Materia:", materia),
                const SizedBox(height: 5),
                _buildInfoRow(Icons.access_time, "Fecha:", fecha),
                // Ya no mostramos "Estado" como pediste
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper para las filas de texto dentro de la tarjeta
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Usamos RichText para mezclar negritas y texto normal
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black, fontSize: 15),
              children: [
                TextSpan(
                  text: "$label ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}