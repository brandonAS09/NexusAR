import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:nexus_ar/core/app_colors.dart';
import 'package:nexus_ar/services/asistencia_service.dart';

class RegistroAsistenciasScreen extends StatefulWidget {
  const RegistroAsistenciasScreen({super.key});

  @override
  State<RegistroAsistenciasScreen> createState() => _RegistroAsistenciasScreenState();
}

class _RegistroAsistenciasScreenState extends State<RegistroAsistenciasScreen> {
  final AsistenciaService _service = AsistenciaService();
  
  bool _isLoading = true;
  List<dynamic> _asistencias = [];
  
  // Filtros seleccionados
  String? selectedMesNombre;
  String? selectedDia;

  // Datos para Dropdowns
  final List<String> meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  List<String> get dias {
    return List.generate(31, (index) => (index + 1).toString());
  }

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  // --- FUNCIÓN PRINCIPAL CORREGIDA ---
  Future<void> _cargarHistorial() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    
    // 1. CAMBIO IMPORTANTE: Leemos el CORREO (String), no el ID (int)
    final String? email = prefs.getString('email_usuario'); 

    if (email == null) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error: No se encontró sesión activa (Falta email_usuario)."),
            backgroundColor: Colors.red,
          )
        );
      }
      return;
    }

    int? mesNumero;
    if (selectedMesNombre != null) {
      mesNumero = meses.indexOf(selectedMesNombre!) + 1;
    }

    int? diaNumero;
    if (selectedDia != null) {
      diaNumero = int.tryParse(selectedDia!);
    }

    // 2. Pasamos el EMAIL al servicio. 
    // Tu servicio ya sabe que si es texto, debe buscar por correo.
    final resultados = await _service.obtenerHistorial(
      email, 
      mes: mesNumero, 
      dia: diaNumero
    );

    if (mounted) {
      setState(() {
        _asistencias = resultados;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2C35),
      appBar: AppBar(
        backgroundColor: AppColors.botonInicioSesion,
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
        actions: [
          if (selectedMesNombre != null || selectedDia != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off, color: Colors.black),
              onPressed: () {
                setState(() {
                  selectedMesNombre = null;
                  selectedDia = null;
                });
                _cargarHistorial();
              },
            )
        ],
      ),
      body: Column(
        children: [
          // SECCIÓN DE FILTROS
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDropdown("Mes", meses, selectedMesNombre, (val) {
                  setState(() => selectedMesNombre = val);
                  _cargarHistorial();
                }),
                _buildDropdown("Día", dias, selectedDia, (val) {
                  setState(() => selectedDia = val);
                  _cargarHistorial();
                }),
              ],
            ),
          ),

          // LISTA DE RESULTADOS
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.botonInicioSesion))
              : _asistencias.isEmpty
                  ? const Center(
                      child: Text(
                        "No se encontraron asistencias.",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _asistencias.length,
                      itemBuilder: (context, index) {
                        final item = _asistencias[index];
                        return _buildAsistenciaCard(
                          materia: item['materia'] ?? "Sin nombre",
                          // Si la fecha viene nula, mostramos un placeholder
                          fecha: item['fecha'] ?? "--/--/----",
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String hint, List<String> items, String? value, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: AppColors.botonInicioSesion,
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
          dropdownColor: Colors.white,
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

  Widget _buildAsistenciaCard({required String materia, required String fecha}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.botonInicioSesion,
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: const Icon(Icons.menu_book, color: Colors.black, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.class_, "Materia:", materia),
                const SizedBox(height: 5),
                _buildInfoRow(Icons.access_time, "Fecha:", fecha),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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