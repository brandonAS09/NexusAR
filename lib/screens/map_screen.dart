import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nexus_ar/core/app_colors.dart';
import 'package:nexus_ar/components/custom_app_bar.dart';
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

  void _startNavigation() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Iniciando navegación...')));
  }

  void _startScanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abriendo scanner de reconocimiento...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: ui.Size.fromHeight(70),
        child: CustomAppBar(
          backButton: true,
          onHelpPressed: null,
          onLogoutPressed: null,
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
            top: MediaQuery.of(context).padding.top + 80,
            right: 12,
            child: Column(
              children: [
                _buildActionButton(
                  icon: Icons.face_retouching_natural,
                  color: AppColors.botonInicioSesion.withOpacity(0.95),
                  onPressed: _startScanner,
                ),
                const SizedBox(height: 12),
                _buildNavigationButton(
                  color: AppColors.botonInicioSesion.withOpacity(0.95),
                  onPressed: _startNavigation,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 26),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildNavigationButton({
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
      ),
      child: IconButton(
        icon: const Icon(Icons.directions, color: Colors.white, size: 26),
        onPressed: onPressed,
      ),
    );
  }
}
