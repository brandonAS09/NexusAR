import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nexus_ar/components/mapa_bar.dart';
import 'package:nexus_ar/core/app_colors.dart';
import 'package:nexus_ar/components/rutas_boton.dart';
import 'dart:ui' as ui;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapboxMap? mapboxMap;

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

  void _rutaSeleccionada(String ruta) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mostrando $ruta')),
    );
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

          //  Botones
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
