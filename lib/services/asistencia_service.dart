import 'dart:convert';
import 'package:http/http.dart' as http;

// Asegúrate de que la IP sea la correcta
const String _baseUrl = 'http://10.41.55.194:3000'; 
const Duration _httpTimeout = Duration(seconds: 10);

class AsistenciaService {
  
  // --- Métodos existentes (SIN CAMBIOS) ---
  Future<Map<String, dynamic>> obtenerHorario(String codigoSalon, String email, double lat, double lon) async {
    final url = Uri.parse('$_baseUrl/horario');
    try {
      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: json.encode({'codigo': codigoSalon, 'email': email, 'latitud': lat, 'longitud': lon})).timeout(_httpTimeout);
      return {'statusCode': response.statusCode, 'body': response.body.isNotEmpty ? json.decode(response.body) : null};
    } catch (e) { return {'statusCode': 500, 'body': {'error': 'Error de conexión: $e'}}; }
  }

  Future<Map<String, dynamic>> verificarUbicacion(int idEdificio, double lat, double lon) async {
    final url = Uri.parse('$_baseUrl/asistencia/verificar_ubicacion');
    try {
      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: json.encode({'id_edificio': idEdificio, 'latitud': lat, 'longitud': lon})).timeout(_httpTimeout);
      return {'statusCode': response.statusCode, 'body': response.body.isNotEmpty ? json.decode(response.body) : null};
    } catch (e) { return {'statusCode': 500, 'body': {'error': 'Error de conexión: $e'}}; }
  }

  Future<Map<String, dynamic>> registrarEntrada({required int idUsuario, required int idMateria, required String timestamp}) async {
    final url = Uri.parse('$_baseUrl/asistencia/entrada');
    try {
      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: json.encode({'id_usuario': idUsuario, 'id_materia': idMateria, 'timestamp': timestamp})).timeout(_httpTimeout);
      return {'statusCode': response.statusCode, 'body': response.body.isNotEmpty ? json.decode(response.body) : null};
    } catch (e) { return {'statusCode': 500, 'body': {'error': 'Error de conexión: $e'}}; }
  }

  Future<Map<String, dynamic>> registrarSalida({required int idUsuario, required int idMateria, required String timestamp}) async {
    final url = Uri.parse('$_baseUrl/asistencia/salida');
    try {
      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: json.encode({'id_usuario': idUsuario, 'id_materia': idMateria, 'timestamp': timestamp})).timeout(_httpTimeout);
      return {'statusCode': response.statusCode, 'body': response.body.isNotEmpty ? json.decode(response.body) : null};
    } catch (e) { return {'statusCode': 500, 'body': {'error': 'Error de conexión: $e'}}; }
  }

  Future<Map<String, dynamic>> consultarEstado({required int idUsuario, required int idMateria}) async {
    final url = Uri.parse('$_baseUrl/asistencia/$idUsuario/$idMateria');
    try {
      final response = await http.get(url).timeout(_httpTimeout);
      return {'statusCode': response.statusCode, 'body': response.body.isNotEmpty ? json.decode(response.body) : null};
    } catch (e) { return {'statusCode': 500, 'body': {'error': 'Error de conexión: $e'}}; }
  }

  // --- AQUÍ ESTÁ LA CORRECCIÓN ---
  // Cambiamos 'int idUsuario' por 'dynamic usuarioIdentificador'
  // Esto permite que la función reciba tanto el ID (int) como el Correo (String)
  Future<List<dynamic>> obtenerHistorial(dynamic usuarioIdentificador, {int? mes, int? dia}) async {
    String query = "";
    if (mes != null) query += "?mes=$mes";
    if (dia != null) query += "${query.isEmpty ? '?' : '&'}dia=$dia";

    Uri url;
    
    // Si lo que recibimos es texto, asumimos que es un CORREO y usamos la ruta especial
    if (usuarioIdentificador is String) {
      url = Uri.parse('$_baseUrl/asistencia/historial/correo/$usuarioIdentificador$query');
    } 
    // Si es número, usamos la ruta normal de ID
    else {
      url = Uri.parse('$_baseUrl/asistencia/historial/$usuarioIdentificador$query');
    }
    
    try {
      final response = await http.get(url).timeout(_httpTimeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print("Error backend (${response.statusCode}): ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error al obtener historial: $e");
      return [];
    }
  }
}