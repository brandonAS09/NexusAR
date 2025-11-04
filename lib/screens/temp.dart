import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:nexus_ar/components/mapa_bar.dart';
import 'package:nexus_ar/core/app_colors.dart';
import 'package:nexus_ar/components/rutas_boton.dart';
import 'package:nexus_ar/services/ruta_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' show MbxImage;
import 'dart:math';
import 'package:image/image.dart' as IMG;

const Color kMorado = Color(0xFFB097F1);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  mb.MapboxMap? mapboxMap;
  mb.PolylineAnnotationManager? polylineManager;
  mb.PointAnnotationManager? pointManager;
  final RutaService rutaService = RutaService();

  StreamSubscription<Position>? _posSub;

  List<List<double>>? _rutaActiva;
  double? _destinoLat;
  double? _destinoLon;

  Timer? _simulacionTimer;
  int _simIndex = 0;
  bool _simulandoRecorrido = false;
  bool iconsLoaded = false;

  final double _campusLat = 31.865374;
  final double _campusLon = -116.667263;

  // NUEVO: cambia el origen de prueba para estar seguro que no colapsa
  final double _testOrigenLat = 31.8660;  // ALEJADO de E1
  final double _testOrigenLon = -116.6680;

  Future<void> _loadMapIcons() async {
    if (mapboxMap == null) return;
    try {
      if (iconsLoaded) return;
      final personBytes = await rootBundle.load("assets/PersonPin.png");
      final locationBytes = await rootBundle.load("assets/LocationPin.png");

      final personImg = IMG.decodeImage(personBytes.buffer.asUint8List())!;
      final locationImg = IMG.decodeImage(locationBytes.buffer.asUint8List())!;

      final personImage = MbxImage(
        data: personBytes.buffer.asUint8List(),
        width: personImg.width,
        height: personImg.height,
      );
      final locationImage = MbxImage(
        data: locationBytes.buffer.asUint8List(),
        width: locationImg.width,
        height: locationImg.height,
      );

      await mapboxMap!.style.addStyleImage(
        "PersonPin",
        1.0,
        personImage,
        false,
        <mb.ImageStretches>[],
        <mb.ImageStretches>[],
        mb.ImageContent(left: 0.0, top: 0.0, right: 0.0, bottom: 0.0),
      );

      await mapboxMap!.style.addStyleImage(
        "LocationPin",
        1.0,
        locationImage,
        false,
        <mb.ImageStretches>[],
        <mb.ImageStretches>[],
        mb.ImageContent(left: 0.0, top: 0.0, right: 0.0, bottom: 0.0),
      );

      iconsLoaded = true;
      print("✅ Iconos PersonPin y LocationPin cargados y añadidos.");
    } catch (e) {
      debugPrint("❌ Error loading Mapbox icon assets: $e");
    }
  }

  void _onMapCreated(mb.MapboxMap map) async {
    mapboxMap = map;
    try {
      polylineManager = await map.annotations.createPolylineAnnotationManager();
      pointManager = await map.annotations.createPointAnnotationManager();
      await _loadMapIcons();
      print("✅ Mapbox managers y iconos listos.");
    } catch (e) {
      print("❌ Error en _onMapCreated: $e");
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _simulacionTimer?.cancel();
    super.dispose();
  }

  void _startLocationUpdates(double destLat, double destLon) async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de GPS denegado')),
      );
      return;
    }
    _posSub?.cancel();
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(distanceFilter: 8),
    ).listen((Position pos) {
      _onLocationUpdate(pos, destLat, destLon);
    });
  }

  void _onLocationUpdate(Position userPos, double destLat, double destLon) {
    double distancia = Geolocator.distanceBetween(
      userPos.latitude, userPos.longitude, destLat, destLon,
    );
    print("🔎 Ubicación actual: (${userPos.latitude},${userPos.longitude}), destino: ($destLat,$destLon), distancia: $distancia");
    if (distancia < 10) {
      print("🛑 ¡Finalizando ruta! Distancia menor al umbral.");
      _finalizaRuta(destLat, destLon);
      _posSub?.cancel();
      return;
    }
    if (_rutaActiva != null && _rutaActiva!.isNotEmpty) {
      int closestIdx = 0;
      double minDist = double.infinity;
      for (int i = 0; i < _rutaActiva!.length; i++) {
        double d = Geolocator.distanceBetween(
          userPos.latitude, userPos.longitude,
          _rutaActiva![i][0], _rutaActiva![i][1],
        );
        if (d < minDist) {
          minDist = d;
          closestIdx = i;
        }
      }
      print("🔎 Closest point index: $closestIdx, minDist: $minDist");
      _redibujarRutaDesde(closestIdx);
    }
  }

  void _simularRecorrido() {
    if (_rutaActiva == null || _rutaActiva!.isEmpty) return;
    setState(() {
      _simulandoRecorrido = true;
    });
    _simIndex = 0;
    _simulacionTimer?.cancel();
    _simulacionTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_simIndex >= _rutaActiva!.length) {
        timer.cancel();
        setState(() {
          _simulandoRecorrido = false;
        });
        _finalizaRuta(_destinoLat!, _destinoLon!);
        return;
      }
      final punto = _rutaActiva![_simIndex];
      final virtualPosition = Position(
        latitude: punto[0],
        longitude: punto[1],
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 0.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
      print("🚶 Simular recorrido index $_simIndex, posición simulada: $virtualPosition");
      _onLocationUpdate(virtualPosition, _destinoLat!, _destinoLon!);
      _simIndex++;
    });
  }

  Future<void> _redibujarRutaDesde(int idx) async {
    if (_rutaActiva == null) return;
    await polylineManager?.deleteAll();
    List<mb.Position> dynamicCoords = _rutaActiva!
        .sublist(idx)
        .map((p) => mb.Position(p[1], p[0]))
        .toList();
    print("🆕 Redibujar ruta desde $idx: nuevos coords: $dynamicCoords");

    await polylineManager?.create(mb.PolylineAnnotationOptions(
      geometry: mb.LineString(coordinates: dynamicCoords),
      lineColor: kMorado.value,
      lineWidth: 5.0,
      lineOpacity: 0.9,
    ));
    print("🔗 Línea actualizada");

    await pointManager?.deleteAll();

    try {
      await pointManager?.create(
        mb.PointAnnotationOptions(
          geometry: mb.Point(coordinates: dynamicCoords.first),
          iconImage: "PersonPin",
          iconSize: 1.8,
        ),
      );
      print("📍 PersonPin colocado en ${dynamicCoords.first}");
      await pointManager?.create(
        mb.PointAnnotationOptions(
          geometry: mb.Point(coordinates: dynamicCoords.last),
          iconImage: "LocationPin",
          iconSize: 1.8,
        ),
      );
      print("📍 LocationPin colocado en ${dynamicCoords.last}");
    } catch (e) {
      print("❌ Error creando los PointAnnotations: $e");
    }
  }

  void _finalizaRuta(double destLat, double destLon) async {
    print("🚩 FINALIZANDO RUTA en destino ($destLat, $destLon)");
    await polylineManager?.deleteAll();
    await pointManager?.deleteAll();
    setState(() {
      _rutaActiva = null;
      _simulandoRecorrido = false;
    });
    String pisoMsg =
        "Recordatorio: si el número del edificio comienza con 1, corresponde al primer piso; si comienza con 2, al segundo piso; si comienza con 3, al tercer piso; y así sucesivamente.";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Has llegado a tu destino.'),
        content: Text(pisoMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Aceptar"),
          )
        ],
      ),
    );
  }

  Future<void> _rutaSeleccionada(String idEdificio) async {
    _posSub?.cancel();
    _simulacionTimer?.cancel();

    if (idEdificio == 'Ninguna') {
      await polylineManager?.deleteAll();
      await pointManager?.deleteAll();
      setState(() {
        _rutaActiva = null;
        _destinoLat = null;
        _destinoLon = null;
        _simulandoRecorrido = false;
      });
      print("🚫 Selección de ruta: ninguna");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se eliminó la ruta seleccionada')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calculando ruta a $idEdificio...')),
    );

    try {
      // CAMBIADO PARA TESTEAR: usa origen alejado
      final double origenLat = _testOrigenLat;
      final double origenLon = _testOrigenLon;
      final ruta = await rutaService.obtenerRuta(
        lat: origenLat,
        lon: origenLon,
        idEdificio: idEdificio,
      );
      print("📦 RUTA de $idEdificio recibida: ${ruta.length} puntos");
      print("Contenido ruta: $ruta");
      if (ruta.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.flutter_dash, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Ruta vacía recibida del servidor')),
              ],
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        print("❌ Ruta vacía");
        return;
      }
      if (ruta.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('La ruta recibida es demasiado corta (${ruta.length} puntos). (Backend issue)'),
            backgroundColor: Colors.orange,
          ),
        );
        print("❌ Ruta demasiado corta (${ruta.length} puntos): $ruta");
        return;
      }
      final first = ruta.first;
      await mapboxMap?.flyTo(
        mb.CameraOptions(
          center: mb.Point(coordinates: mb.Position(first[1], first[0])),
          zoom: 17.0,
        ),
        mb.MapAnimationOptions(duration: 1500),
      );
      await _loadMapIcons();
      setState(() {
        _rutaActiva = ruta;
        _destinoLat = ruta.last[0];
        _destinoLon = ruta.last[1];
        _simulandoRecorrido = false;
      });
      await polylineManager?.deleteAll();
      await pointManager?.deleteAll();
      final coords = ruta.map((p) => mb.Position(p[1], p[0])).toList();
      print("🔗 Polyline inicial coords: $coords");
      await polylineManager?.create(mb.PolylineAnnotationOptions(
        geometry: mb.LineString(coordinates: coords),
        lineColor: kMorado.value,
        lineWidth: 5.0,
        lineOpacity: 0.9,
      ));

      try {
        await pointManager?.create(mb.PointAnnotationOptions(
          geometry: mb.Point(coordinates: coords.first),
          iconImage: "PersonPin",
          iconSize: 1.8,
        ));
        print("📍 PersonPin creado en ${coords.first}");

        await pointManager?.create(mb.PointAnnotationOptions(
          geometry: mb.Point(coordinates: coords.last),
          iconImage: "LocationPin",
          iconSize: 1.8,
        ));
        print("📍 LocationPin creado en ${coords.last}");
      } catch (e) {
        print("❌ ERROR al crear puntos iniciales: $e");
      }
      _startLocationUpdates(_destinoLat!, _destinoLon!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ruta recibida: ${ruta.length} puntos')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.flutter_dash, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error al obtener la ruta: $e')),
            ],
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      print("❌ ERROR en rutaSeleccionada: $e");
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
            child: mb.MapWidget(
              key: const ValueKey('mapWidget'),
              styleUri: mb.MapboxStyles.MAPBOX_STREETS,
              cameraOptions: mb.CameraOptions(
                center: mb.Point(coordinates: mb.Position(_campusLon, _campusLat)),
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
          if (_destinoLat != null && _destinoLon != null)
            Positioned(
              bottom: 96,
              right: 24,
              child: ElevatedButton.icon(
                icon: Icon(_simulandoRecorrido ? Icons.pause : Icons.directions_walk, color: Colors.white),
                label: Text(_simulandoRecorrido ? 'Detener simular recorrido' : 'Simular recorrido'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onPressed: () {
                  if (_simulandoRecorrido) {
                    _simulacionTimer?.cancel();
                    setState(() { _simulandoRecorrido = false; });
                  } else {
                    _simularRecorrido();
                  }
                },
              ),
            ),
          if (_destinoLat != null && _destinoLon != null)
            Positioned(
              bottom: 32,
              right: 24,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.flag, color: Colors.white),
                label: const Text('Simular llegada'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMorado,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onPressed: () => _finalizaRuta(_destinoLat!, _destinoLon!),
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

  void _startScanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abriendo scanner de reconocimiento...')),
    );
  }
}