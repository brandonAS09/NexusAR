import 'dart:convert';
import 'package:http/http.dart' as http;

class RutaService {
  final String baseUrl = "http://10.0.2.2:3000"; // Ej: http://192.168.1.5:3000

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
      final features = data["features"] as List;
      final geometry = features.first["geometry"];
      final coords = geometry["coordinates"] as List;

      // Formato: [ [lat, lon], [lat, lon], ... ]
      return coords.map<List<double>>((p) => [p[1], p[0]]).toList();
    } else {
      throw Exception("Error al obtener ruta: ${response.body}");
    }
  }
}
