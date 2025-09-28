import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'sendgrid_direct_service.dart';
import 'sendgrid_proxy_service.dart';

/// Servicio de envío de emails usando servidor proxy
class EmailService {
  // Configuración del servidor proxy
  static const String _baseUrl =
      'https://render-mail-2bzn.onrender.com'; // Servidor de email
  // static const String _serverUrl = 'https://tu-servidor.render.com'; // Para producción

  // Endpoint del servidor proxy
  static String get _emailEndpoint => '$_baseUrl/api/send-email';

  /// Envía un ticket por email usando servidor proxy con fallback a SendGrid directo
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
      print('📧 Email Service - Intentando envío via servidor proxy...');

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
      final response = await http
          .post(
            Uri.parse(_emailEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(emailData),
          )
          .timeout(const Duration(seconds: 15));

      print('📧 Email Service - Respuesta del servidor:');
      print('   Status Code: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('📧 Email Service - Datos parseados: $responseData');

        if (responseData['success'] == true) {
          print('✅ Email enviado exitosamente via servidor proxy');
          return true;
        } else {
          print(
            '❌ Error del servidor: ${responseData['error'] ?? 'Error desconocido'}',
          );
          print('📧 Email Service - Intentando SendGrid directo...');

          // Fallback a SendGrid directo
          return await SendGridDirectService.sendTicketEmail(
            recipientEmail: recipientEmail,
            plate: plate,
            zone: zone,
            start: start,
            end: end,
            price: price,
            method: method,
            qrData: qrData,
            customSubject: customSubject,
            customMessage: customMessage,
            locale: locale,
          );
        }
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
        print('📧 Email Service - Intentando SendGrid directo...');

        // Fallback a SendGrid directo
        final directSuccess = await SendGridDirectService.sendTicketEmail(
          recipientEmail: recipientEmail,
          plate: plate,
          zone: zone,
          start: start,
          end: end,
          price: price,
          method: method,
          qrData: qrData,
          customSubject: customSubject,
          customMessage: customMessage,
          locale: locale,
        );

        if (directSuccess) {
          return true;
        }

        // Último fallback a SendGrid con proxy
        print(
          '📧 Email Service - SendGrid directo falló, intentando con proxy...',
        );
        return await SendGridProxyService.sendTicketEmail(
          recipientEmail: recipientEmail,
          plate: plate,
          zone: zone,
          start: start,
          end: end,
          price: price,
          method: method,
          qrData: qrData,
          customSubject: customSubject,
          customMessage: customMessage,
          locale: locale,
        );
      }
    } catch (e) {
      // Error en EmailService - Intentar SendGrid directo
      print('❌ Error en EmailService: $e');
      print('📧 Email Service - Intentando SendGrid directo...');

      // Fallback a SendGrid directo
      final directSuccess = await SendGridDirectService.sendTicketEmail(
        recipientEmail: recipientEmail,
        plate: plate,
        zone: zone,
        start: start,
        end: end,
        price: price,
        method: method,
        qrData: qrData,
        customSubject: customSubject,
        customMessage: customMessage,
        locale: locale,
      );

      if (directSuccess) {
        return true;
      }

      // Último fallback a SendGrid con proxy
      print(
        '📧 Email Service - SendGrid directo falló, intentando con proxy...',
      );
      return await SendGridProxyService.sendTicketEmail(
        recipientEmail: recipientEmail,
        plate: plate,
        zone: zone,
        start: start,
        end: end,
        price: price,
        method: method,
        qrData: qrData,
        customSubject: customSubject,
        customMessage: customMessage,
        locale: locale,
      );
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

  /// Método para probar el rendimiento del servidor optimizado
  static Future<Map<String, dynamic>?> getServerPerformance() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/performance'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo rendimiento del servidor: $e');
      return null;
    }
  }

  /// Método para probar envío de email con datos de prueba
  static Future<bool> testEmailSending() async {
    try {
      print('🧪 Probando envío de email...');

      final testData = {
        'recipientEmail': 'test@example.com',
        'plate': 'TEST123',
        'zone': 'coche',
        'start': DateTime.now().toIso8601String(),
        'end': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
        'price': 2.50,
        'method': 'tarjeta',
        'locale': 'es',
        'provider': 'gmail',
      };

      final response = await http
          .post(
            Uri.parse(_emailEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(testData),
          )
          .timeout(const Duration(seconds: 30));

      print('🧪 Respuesta de prueba: ${response.statusCode}');
      print('🧪 Cuerpo: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error en prueba de email: $e');
      return false;
    }
  }
}
