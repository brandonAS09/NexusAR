import 'dart:convert';
import 'package:http/http.dart' as http;

const String _baseUrl = 'http://10.41.55.194:3000'; // Ajusta si tu servidor usa otra IP/puerto
const Duration _httpTimeout = Duration(seconds: 10);

class AsistenciaService {
  // Solicita al backend la validación de geofence + horario y devuelve el body decodificado.
  // Body enviado: { codigo, email, latitud, longitud }
  Future<Map<String, dynamic>> obtenerHorario(
      String codigoSalon, String email, double lat, double lon) async {
    final url = Uri.parse('$_baseUrl/horario');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'codigo': codigoSalon,
              'email': email,
              'latitud': lat,
              'longitud': lon,
            }),
          )
          .timeout(_httpTimeout);
      return {
        'statusCode': response.statusCode,
        'body': response.body.isNotEmpty ? json.decode(response.body) : null,
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'error': 'Error de conexión al obtener horario: $e'}
      };
    }
  }

  // Verifica si una lat/lon están dentro del geofence del edificio (usa el endpoint del backend)
  // Request body: { id_edificio, latitud, longitud }
  Future<Map<String, dynamic>> verificarUbicacion(
      int idEdificio, double lat, double lon) async {
    // Observa que el backend que tienes expone /asistencia/verificar_ubicacion
    final url = Uri.parse('$_baseUrl/asistencia/verificar_ubicacion');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'id_edificio': idEdificio,
              'latitud': lat,
              'longitud': lon,
            }),
          )
          .timeout(_httpTimeout);
      return {
        'statusCode': response.statusCode,
        'body': response.body.isNotEmpty ? json.decode(response.body) : null,
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'error': 'Error de conexión al verificar ubicación: $e'}
      };
    }
  }

  Future<Map<String, dynamic>> registrarEntrada({
    required int idUsuario,
    required int idMateria,
    required String timestamp,
  }) async {
    final url = Uri.parse('$_baseUrl/asistencia/entrada');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'id_usuario': idUsuario,
              'id_materia': idMateria,
              'timestamp': timestamp,
            }),
          )
          .timeout(_httpTimeout);
      return {
        'statusCode': response.statusCode,
        'body': response.body.isNotEmpty ? json.decode(response.body) : null,
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'error': 'Error de conexión al registrar entrada: $e'}
      };
    }
  }

  Future<Map<String, dynamic>> registrarSalida({
    required int idUsuario,
    required int idMateria,
    required String timestamp,
  }) async {
    final url = Uri.parse('$_baseUrl/asistencia/salida');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'id_usuario': idUsuario,
              'id_materia': idMateria,
              'timestamp': timestamp,
            }),
          )
          .timeout(_httpTimeout);
      return {
        'statusCode': response.statusCode,
        'body': response.body.isNotEmpty ? json.decode(response.body) : null,
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'error': 'Error de conexión al registrar salida: $e'}
      };
    }
  }

  Future<Map<String, dynamic>> consultarEstado({
    required int idUsuario,
    required int idMateria,
  }) async {
    final url = Uri.parse('$_baseUrl/asistencia/$idUsuario/$idMateria');
    try {
      final response = await http.get(url).timeout(_httpTimeout);
      return {
        'statusCode': response.statusCode,
        'body': response.body.isNotEmpty ? json.decode(response.body) : null,
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'error': 'Error de conexión al consultar estado: $e'}
      };
    }
  }

  // Opcional: obtener duración de la materia desde backend (si existe endpoint)
  Future<int?> obtenerDuracionMateria(int idMateria) async {
    final url = Uri.parse('$_baseUrl/materias/$idMateria');
    try {
      final response = await http.get(url).timeout(_httpTimeout);
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        if (data != null && data['duracion_minutos'] != null) {
          return (data['duracion_minutos'] as num).toInt();
        }
      }
    } catch (e) {
      // Ignorar y devolver null para usar el default en el cliente
    }
    return null;
  }
}