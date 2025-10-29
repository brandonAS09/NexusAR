import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nexus_ar/components/mapa_bar.dart';
import 'package:nexus_ar/core/app_colors.dart';
import 'package:nexus_ar/components/rutas_boton.dart';
import 'package:nexus_ar/services/ruta_service.dart';
import 'dart:ui' as ui;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapboxMap? mapboxMap;
  final RutaService rutaService = RutaService();

  final double _campusLat = 31.865374;
  final double _campusLon = -116.667263;

  void _onMapCreated(MapboxMap map) {
    mapboxMap = map;
  }

  void _startScanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abriendo scanner de reconocimiento...')),
    );
  }

  Future<void> _rutaSeleccionada(String idEdificio) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calculando ruta a $idEdificio...')),
    );

    try {
      // Ubicación de ejemplo (reemplaza por ubicación real si la tienes)
      final double lat = 31.8652;
      final double lon = -116.6673;

      final ruta = await rutaService.obtenerRuta(
        lat: lat,
        lon: lon,
        idEdificio: idEdificio,
      );

      if (ruta.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ruta vacía recibida del servidor')),
        );
        return;
      }

      // Centrar cámara en el primer punto de la ruta
      final first = ruta.first; // formato: [lat, lon]
      await mapboxMap?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(first[1], first[0])),
          zoom: 17.0,
        ),
        MapAnimationOptions(duration: 1500),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ruta recibida: ${ruta.length} puntos')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener la ruta: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: ui.Size.fromHeight(70),
        child: MapAppBar(
          backButton: true,
          title: const Text(
            'Mapa del Campus',
            style: TextStyle(
              color: Colors.black,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: Stack(
        children: [
          SizedBox.expand(
            child: MapWidget(
              key: const ValueKey('mapWidget'),
              styleUri: MapboxStyles.MAPBOX_STREETS,
              cameraOptions: CameraOptions(
                center: Point(coordinates: Position(_campusLon, _campusLat)),
                zoom: 17,
              ),
              onMapCreated: _onMapCreated,
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top,
            right: 16,
            child: Column(
              children: [
                _buildActionButton(
                  icon: Icons.camera_alt_outlined,
                  iconColor: Colors.black,
                  iconSize: 50,
                  color: AppColors.botonInicioSesion,
                  onPressed: _startScanner,
                ),
                const SizedBox(height: 105),

                RutasBoton(onRutaSeleccionada: _rutaSeleccionada),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color iconColor,
    required double iconSize,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor, size: iconSize),
        onPressed: onPressed,
        splashRadius: 28,
      ),
    );
  }
}