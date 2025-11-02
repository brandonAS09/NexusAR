import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio que llama a tu backend y obtiene la ruta óptima desde la base de datos.
class RutaService {
  final String baseUrl = "http://10.0.2.2:3000"; // Cambia IP si usas físico

  Future<List<List<double>>> obtenerRuta({
    required double lat,
    required double lon,
    required String idEdificio,
  }) async {
    final url = Uri.parse("$baseUrl/api/ruta");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "lat": lat,
        "lon": lon,
        "id_edificio": idEdificio,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Soporta respuesta como FeatureCollection o Feature
      List coords = [];
      if (data.containsKey("features")) {
        // FeatureCollection
        coords = (data["features"] as List)[0]["geometry"]["coordinates"];
      } else if (data.containsKey("geometry")) {
        // Feature simple
        coords = data["geometry"]["coordinates"];
      }

      // Formato: [ [lat, lon], [lat, lon], ... ]
      return coords.map<List<double>>((p) => [p[1], p[0]]).toList();
    } else {
      throw Exception("Error al obtener ruta: ${response.body}");
    }
  }
}