import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nexus_ar/screens/inicio_sesion.dart';
import 'core/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 👇 Configura el token de Mapbox una sola vez
  MapboxOptions.setAccessToken("pk.eyJ1IjoiYnJhbmRvbmFzMDkiLCJhIjoiY21oMmN1MmE0MGF4YzJqb2JseXh5cnhwdiJ9.xYSjGak9r8yqwj8byf0drA");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: InicioSesion(),
      ),
    );
  }
}
