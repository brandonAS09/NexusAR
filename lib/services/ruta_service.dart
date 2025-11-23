import 'dart:convert';
import 'package:http/http.dart' as http;

/// 🌐 Servicio de conexión con el backend Node.js
const String _baseUrl = 'http://192.168.100.63:3000';

class RutaService {
  /// --------------------------
  /// 🚩 OBTENER RUTA DEL BACKEND
  /// --------------------------
  Future<List<List<double>>> obtenerRuta({
    required double lat,
    required double lon,
    required String idEdificio,
  }) async {
    final url = Uri.parse('$_baseUrl/api/ruta');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'lat': lat,
        'lon': lon,
        'id_edificio': idEdificio,
      }),
    );
    print("🛰️ Respuesta ruta: ${response.statusCode} ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body); // <---  GeoJSON

      final List? coordinates = data['features']?[0]?['geometry']?['coordinates'];
      if (coordinates == null || coordinates.isEmpty) return [];

      // Convierte [lon, lat] a [lat, lon]
      return coordinates.map<List<double>>((coord) => [coord[1], coord[0]]).toList();
    } else {
      print('❌ Error al obtener ruta: ${response.statusCode} ${response.body}');
      return [];
    }
  }
}