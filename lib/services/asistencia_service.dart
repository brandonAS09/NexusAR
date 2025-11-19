import 'dart:convert';
import 'package:http/http.dart' as http;

// Asegúrate de que la IP sea la correcta
const String _baseUrl = 'http://10.41.55.194:3000'; 

class AsistenciaService {

  // --- MODIFICADO (Punto 1 de la Guía) ---
  // Ahora requiere latitud y longitud para validar "Guardia de Seguridad"
  Future<Map<String, dynamic>> obtenerHorario(String codigoSalon, String email, double lat, double lon) async {
    // OJO: La guía dice /api/horario, pero tu código usaba /horario.
    // Ajusta esto según tu ruta real. Asumiré '/horario' basado en tu código previo.
    final url = Uri.parse('$_baseUrl/horario'); 
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'codigo': codigoSalon,
          'email': email,
          'latitud': lat,   // <-- NUEVO: Requerido por el backend
          'longitud': lon,  // <-- NUEVO: Requerido por el backend
        }),
      );
      return {
        'statusCode': response.statusCode,
        'body': response.body.isNotEmpty ? json.decode(response.body) : null,
      };
    } catch (e) {
      return {'statusCode': 500, 'body': {'error': 'Error de conexión: $e'}};
    }
  }

  // --- MODIFICADO (Punto 2 de la Guía) ---
  // Ahora requiere el id_edificio
  Future<Map<String, dynamic>> verificarUbicacion(int idEdificio, double lat, double lon) async {
    final url = Uri.parse('$_baseUrl/ubicacion/verificar'); // Verifica si la ruta cambió a /asistencia/verificar_ubicacion en el backend o sigue igual.
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_edificio': idEdificio, // <-- NUEVO: Requerido para saber qué polígono revisar
          'latitud': lat,
          'longitud': lon,
        }),
      );
      return {
        'statusCode': response.statusCode,
        'body': response.body.isNotEmpty ? json.decode(response.body) : null,
      };
    } catch (e) {
      return {'statusCode': 500, 'body': {'error': 'Error de conexión: $e'}};
    }
  }

  // --- SIN CAMBIOS ---
  Future<Map<String, dynamic>> registrarEntrada({
    required int idUsuario,
    required int idMateria,
    required String timestamp,
  }) async {
    final url = Uri.parse('$_baseUrl/asistencia/entrada');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'id_usuario': idUsuario,
        'id_materia': idMateria,
        'timestamp': timestamp,
      }),
    );

    return {
      'statusCode': response.statusCode,
      'body': response.body.isNotEmpty ? json.decode(response.body) : null,
    };
  }

  Future<Map<String, dynamic>> registrarSalida({
    required int idUsuario,
    required int idMateria,
    required String timestamp,
  }) async {
    final url = Uri.parse('$_baseUrl/asistencia/salida');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'id_usuario': idUsuario,
        'id_materia': idMateria,
        'timestamp': timestamp,
      }),
    );

    return {
      'statusCode': response.statusCode,
      'body': response.body.isNotEmpty ? json.decode(response.body) : null,
    };
  }

  Future<Map<String, dynamic>> consultarEstado({
    required int idUsuario,
    required int idMateria,
  }) async {
    final url = Uri.parse('$_baseUrl/asistencia/$idUsuario/$idMateria');
    final response = await http.get(url);
    return {
      'statusCode': response.statusCode,
      'body': response.body.isNotEmpty ? json.decode(response.body) : null,
    };
  }
}