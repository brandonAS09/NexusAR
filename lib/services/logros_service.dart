import 'dart:convert';
import 'package:http/http.dart' as http;

class LogrosService {
  // Asegúrate de usar la IP correcta
  final String baseUrl = "http://10.41.55.194:3000/logros"; 

  /// 1. Obtener ID de usuario dado su correo
  Future<int?> obtenerIdPorEmail(String email) async {
    try {
      final url = Uri.parse('$baseUrl/usuario/$email');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id_usuario'];
      }
      return null;
    } catch (e) {
      print("Error obteniendo ID por email: $e");
      return null;
    }
  }

  /// 2. Obtener las rachas actuales para mostrarlas en pantalla
  Future<Map<String, dynamic>> obtenerRacha(int idUsuario) async {
    try {
      final url = Uri.parse('$baseUrl/obtenerRacha/$idUsuario');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'racha_asistencia': data['racha_asistencia'] ?? 0,
          'racha_puntualidad': data['racha_puntualidad'] ?? 0,
          'mensaje': data['mensaje']
        };
      } else {
        return {'success': false, 'mensaje': 'Error ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'mensaje': 'Error de conexión: $e'};
    }
  }
  
  // NOTA: Se eliminaron registrarRachaAsistencia y registrarRachaPuntualidad
  // porque ahora la lógica es automática en el backend.
}