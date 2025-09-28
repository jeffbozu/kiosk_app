import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'twilio_sms_service.dart';

/// Servicio de SMS con fallback
/// Intenta primero Twilio Direct, luego fallback a otros servicios
class SMSService {
  static String baseUrl = const String.fromEnvironment(
    'SMS_BASE_URL',
    defaultValue: 'https://render-whatsapp-tih4.onrender.com',
  );

  static Future<bool> sendTicketSMS({
    required String phone,
    required String plate,
    required String zone,
    required DateTime start,
    required DateTime end,
    required double price,
    required String method,
    double? discount,
    String? qrData,
    String? localeCode,
  }) async {
    try {
      print('📱 SMS Service - Intentando envío directo a Twilio...');

      // 🚀 Intentar primero con Twilio Direct
      final twilioSuccess = await TwilioSMSService.sendTicketSMS(
        phone: phone,
        plate: plate,
        zone: zone,
        start: start,
        end: end,
        price: price,
        method: method,
        discount: discount,
        qrData: qrData,
        localeCode: localeCode,
      );

      if (twilioSuccess) {
        print('✅ SMS enviado exitosamente via Twilio Direct');
        return true;
      }

      print('📱 SMS Service - Twilio Direct falló, intentando con RENDER...');

      // Fallback a RENDER si Twilio falla
      final l = localeCode ?? 'es_ES';
      final dateFmt = DateFormat('dd/MM/yyyy HH:mm', l);
      final duration = _formatDuration(start, end);

      final ticket = {
        'plate': plate,
        'zone': zone,
        'start': dateFmt.format(start),
        'end': dateFmt.format(end),
        'duration': duration,
        'price': price,
        'discount': discount,
        'method': method,
        'qrData': qrData,
      };

      final payload = {
        'phone': phone,
        'ticket': ticket,
        'localeCode': localeCode ?? 'es_ES',
      };
      final uri = Uri.parse('$baseUrl/v1/sms/send');

      // Enviando mensaje SMS
      print('📱 SMS Service - Enviando mensaje via RENDER:');
      print('   URL: $uri');
      print('   Teléfono: $phone');
      print('   Payload: ${jsonEncode(payload)}');

      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      print('📱 SMS Service - Respuesta RENDER:');
      print('   Status Code: ${res.statusCode}');
      print('   Response Body: ${res.body}');

      // Procesando respuesta
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final success =
            data['ok'] == true ||
            data['success'] == true ||
            data['status'] == 'queued' ||
            data['status'] == 'sent';

        print('📱 SMS Service - Éxito RENDER: $success');
        return success;
      } else {
        print('📱 SMS Service - Error HTTP RENDER: ${res.statusCode}');
        return false;
      }
    } catch (e) {
      print('📱 SMS Service - Error: $e');
      return false;
    }
  }

  /// Fallback a API alternativa
  static Future<bool> _sendAlternativeSMS({
    required String phone,
    required String plate,
    required String zone,
    required DateTime start,
    required DateTime end,
    required double price,
    required String method,
    double? discount,
    String? qrData,
    String? localeCode,
  }) async {
    try {
      // Aquí podrías implementar un servicio alternativo
      print('📱 SMS Service - API alternativa no implementada');
      return false;
    } catch (e) {
      print('❌ Error en API alternativa SMS: $e');
      return false;
    }
  }

  static String _formatDuration(DateTime start, DateTime end) {
    final d = end.difference(start);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
