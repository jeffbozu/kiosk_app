import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// Servicio de envío de emails usando servidor proxy
class EmailService {
  // Configuración del servidor proxy
  static const String _baseUrl = 'https://render-mail-2bzn.onrender.com'; // Servidor de email
  // static const String _serverUrl = 'https://tu-servidor.render.com'; // Para producción
  
  // Endpoint del servidor proxy
  static String get _emailEndpoint => '$_baseUrl/api/send-email';
  
  /// Envía un ticket por email usando servidor proxy
  static Future<bool> sendTicketEmail({
    required String recipientEmail,
    required String plate,
    required String zone,
    required DateTime start,
    required DateTime end,
    required double price,
    required String method,
    String? qrData,
    String? customSubject,
    String? customMessage,
    String locale = 'es', // Idioma del email (es, ca, en)
  }) async {
    try {
      // Preparar datos para el servidor proxy
      final emailData = {
        'recipientEmail': recipientEmail,
        'plate': plate,
        'zone': zone,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'price': price,
        'method': method,
        'customSubject': customSubject,
        'customMessage': customMessage,
        'qrData': qrData,
        'locale': locale,
        'provider': 'gmail', // Usar Gmail configurado en el servidor
      };
      
      // Enviar petición al servidor proxy
      final response = await http.post(
        Uri.parse(_emailEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(emailData),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          // Email enviado exitosamente
          return true;
        } else {
          // Error del servidor
          return false;
        }
      } else {
        // Error HTTP
        return false;
      }
      
    } catch (e) {
      // Error en EmailService
      return false;
    }
  }
  
  /// Método auxiliar para verificar estado del servidor
  static Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Servidor proxy disponible: ${data['status']}');
        return true;
      } else {
        print('❌ Servidor proxy no disponible: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error conectando con servidor proxy: $e');
      return false;
    }
  }
  
  /// Método auxiliar para obtener información del servidor
  static Future<Map<String, dynamic>?> getServerInfo() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo info del servidor: $e');
      return null;
    }
  }
}
