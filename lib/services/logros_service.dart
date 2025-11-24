import 'dart:convert';
import 'package:http/http.dart' as http;

class LogrosService {
  final String baseUrl = "http://10.41.55.194:3000/logros";

  /// 1. Obtener ID de usuario dado su correo (Helper)
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

  /// 2. Obtener la racha actual
  Future<Map<String, dynamic>> obtenerRacha(int idUsuario) async {
    try {
      final url = Uri.parse('$baseUrl/obtenerRacha/$idUsuario');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'racha': data['racha_actual'] ?? 0,
          'mensaje': data['mensaje']
        };
      } else {
        return {'success': false, 'mensaje': 'Error ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'mensaje': 'Error de conexión: $e'};
    }
  }

  /// 3. Actualizar/Iniciar Racha (Llamar cuando se confirma asistencia)
  Future<void> actualizarRacha(int idUsuario) async {
    try {
      final url = Uri.parse('$baseUrl/racha');
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_usuario": idUsuario}),
      );
    } catch (e) {
      print("Error actualizando racha: $e");
    }
  }
}