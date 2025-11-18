import 'dart:convert';
import 'package:http/http.dart' as http;

/// 🌐 Servicio de conexión con el backend Node.js
///
/// ⚙️ Si usas emulador Android:
///   usa `10.0.2.2`
/// Este se usa para el CEL en la UABC
/// 10.41.55.194
///
/// ⚙️ Si usas dispositivo físico:0
///   usa tu IP local, ej. `192.168.1.105:3000`
const String _baseUrl = 'http://10.0.2.2:3000';

class ApiService {
  /// --------------------------
  /// 🔑 LOGIN DE USUARIO
  /// --------------------------
  Future<Map<String, dynamic>> login(String correo, String password) async {
    // Usa _baseUrl aquí también (para no mezclar IPs)
    final url = Uri.parse('$_baseUrl/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'correo': correo,
          'password': password,
        }),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseBody;
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        final errorMessage = responseBody['error'] ?? 'Error de autenticación desconocido';
        throw Exception(errorMessage);
      } else {
        throw Exception('Error del servidor: código ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fallo al conectar con el servidor. $e');
    }
  }

  /// --------------------------
  /// 🧾 REGISTRO DE USUARIO
  /// --------------------------
  Future<Map<String, dynamic>> register(String correo, String password) async {
    final url = Uri.parse('$_baseUrl/auth/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'correo': correo,
          'password': password,
        }),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseBody;
      } else if (response.statusCode == 400 || response.statusCode == 409) {
        final errorMessage = responseBody['error'] ?? 'Error al registrar usuario';
        throw Exception(errorMessage);
      } else {
        throw Exception('Error del servidor: código ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('No se pudo conectar con el servidor. $e');
    }
  }
}
