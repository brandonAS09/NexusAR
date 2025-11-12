import 'dart:convert';
import 'package:http/http.dart' as http;

// Usamos tu IP. ¡Asegúrate de que tu celular esté en la misma red WiFi!
const String _baseUrl = 'http://10.41.55.194:3000';

class AsistenciaService {

  // --- NUEVA FUNCIÓN ---
  // Obtiene la materia, id de usuario y hora_fin de la clase.
  // Requerida por el nuevo AsistenciaScreen.
  Future<Map<String, dynamic>> obtenerHorario(String codigoSalon, String email) async {
    final url = Uri.parse('$_baseUrl/horario');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'codigo': codigoSalon,
          'email': email,
        }),
      );
      return {
        'statusCode': response.statusCode,
        'body': response.body.isNotEmpty ? json.decode(response.body) : null,
      };
    } catch (e) {
      // Error de conexión (ej. servidor apagado o IP incorrecta)
      return {'statusCode': 500, 'body': {'error': 'Error de conexión: $e'}};
    }
  }

  // --- NUEVA FUNCIÓN ---
  // Verifica si las coordenadas están dentro del área de la clase.
  // Requerida por el nuevo AsistenciaScreen.
  Future<Map<String, dynamic>> verificarUbicacion(double lat, double lon) async {
    final url = Uri.parse('$_baseUrl/ubicacion/verificar');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'lat': lat,
          'lon': lon,
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

  // --- Tus funciones originales (Se mantienen igual) ---

  // Registra la entrada: POST /asistencia/entrada
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

  // Registra la salida: POST /asistencia/salida
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

  // Consulta el status final: GET /asistencia/:id_usuario/:id_materia
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

  // --- FUNCIÓN ELIMINADA ---
  // Future<int?> obtenerDuracionMateria(int idMateria) async { ... }
  // Esta función ya no es necesaria porque el nuevo AsistenciaScreen
  // obtiene la 'hora_fin' directamente desde el endpoint '/horario'.
}