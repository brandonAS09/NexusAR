import 'dart:convert';
import 'package:http/http.dart' as http;

// Asegúrate de que esta IP sea la correcta de tu PC
const String _baseUrl = 'http://10.41.55.194:3000';

class ArService {
  Future<Map<String, dynamic>> obtenerInfoClase(String codigoQr) async {
    final url = Uri.parse('$_baseUrl/ar/info_clase');
    
    // 1. Limpiamos el código (quitamos espacios vacíos por si acaso)
    final String codigoLimpio = codigoQr.trim();

    // DEBUG: Imprimimos qué vamos a enviar
    print("📡 ENVIANDO A: $url");
    print("📦 BODY: {'id_salon': '$codigoLimpio'}"); 

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          // OJO AQUÍ: Asegúrate que tu backend espera "codigo_salon"
          // Si tu backend espera "id", "id_salon" o "qr", esto fallará con 400.
          'codigo_qr': codigoLimpio, 
          
          // SI TU BACKEND ESPERA UN NÚMERO (INT) Y NO UN STRING, USA ESTO EN SU LUGAR:
          // 'codigo_salon': int.tryParse(codigoLimpio) ?? 0,
        }),
      );

      print("📥 STATUS: ${response.statusCode}");
      print("📥 RESPUESTA: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Devolvemos el mensaje real del servidor para saber qué salió mal
        return {
          'error': 'Error ${response.statusCode}: ${response.body}'
        };
      }
    } catch (e) {
      print("❌ ERROR EXCEPCIÓN: $e");
      return {'error': 'Error de conexión: $e'};
    }
  }
}