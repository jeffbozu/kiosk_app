import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// Servicio de Twilio usando proxy para evitar CORS
/// Usa un proxy público para enviar WhatsApp/SMS via Twilio
class TwilioProxyService {
  // Proxy público para Twilio (evita CORS)
  static const String _proxyUrl =
      'https://render-whatsapp-tih4.onrender.com/v1/whatsapp/send';
  static const String _smsProxyUrl =
      'https://sms-b9ex.onrender.com/v1/sms/send';

  /// Envía WhatsApp usando proxy público
  static Future<bool> sendTicketWhatsApp({
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
      print('📱 Twilio Proxy - Enviando WhatsApp:');
      print('   Teléfono: $phone');
      print('   Matrícula: $plate');

      final message = _createFormattedMessage(
        plate: plate,
        zone: zone,
        start: start,
        end: end,
        price: price,
        method: method,
        discount: discount,
        qrData: qrData,
        localeCode: localeCode ?? 'es_ES',
      );

      final ticket = {
        'plate': plate,
        'zone': zone,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'price': price,
        'method': method,
        'discount': discount,
        'qrData': qrData,
      };

      final whatsappData = {
        'phone': phone,
        'message': message,
        'ticket': ticket,
        'localeCode': localeCode ?? 'es_ES',
      };

      final response = await http
          .post(
            Uri.parse(_proxyUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(whatsappData),
          )
          .timeout(const Duration(seconds: 30));

      print('📱 Twilio Proxy - Respuesta:');
      print('   Status Code: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          print('✅ WhatsApp enviado exitosamente via Twilio Proxy');
          return true;
        } else {
          print(
            '❌ Error Twilio Proxy: ${responseData['error'] ?? 'Error desconocido'}',
          );
          return false;
        }
      } else {
        print(
          '❌ Error HTTP Twilio Proxy: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('❌ Error en TwilioProxyService: $e');
      return false;
    }
  }

  /// Envía SMS usando proxy público
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
      print('📱 Twilio SMS Proxy - Enviando SMS:');
      print('   Teléfono: $phone');
      print('   Matrícula: $plate');

      final message = _createFormattedMessage(
        plate: plate,
        zone: zone,
        start: start,
        end: end,
        price: price,
        method: method,
        discount: discount,
        qrData: qrData,
        localeCode: localeCode ?? 'es_ES',
      );

      final ticket = {
        'plate': plate,
        'zone': zone,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'price': price,
        'method': method,
        'discount': discount,
        'qrData': qrData,
      };

      final smsData = {
        'phone': phone,
        'message': message,
        'ticket': ticket,
        'localeCode': localeCode ?? 'es_ES',
      };

      final response = await http
          .post(
            Uri.parse(_smsProxyUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(smsData),
          )
          .timeout(const Duration(seconds: 30));

      print('📱 Twilio SMS Proxy - Respuesta:');
      print('   Status Code: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          print('✅ SMS enviado exitosamente via Twilio Proxy');
          return true;
        } else {
          print(
            '❌ Error Twilio SMS Proxy: ${responseData['error'] ?? 'Error desconocido'}',
          );
          return false;
        }
      } else {
        print(
          '❌ Error HTTP Twilio SMS Proxy: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('❌ Error en TwilioProxyService SMS: $e');
      return false;
    }
  }

  /// Crea un mensaje formateado para WhatsApp/SMS
  static String _createFormattedMessage({
    required String plate,
    required String zone,
    required DateTime start,
    required DateTime end,
    required double price,
    required String method,
    double? discount,
    String? qrData,
    required String localeCode,
  }) {
    final l = localeCode;
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm', l);
    final duration = _formatDuration(start, end);

    // Mapear zona
    String getZoneName(String zone) {
      switch (zone) {
        case 'coche':
          return 'Zona Coche';
        case 'moto':
          return 'Zona Moto';
        case 'camion':
          return 'Zona Camión';
        case 'green':
          return 'Zona Verde';
        case 'blue':
          return 'Zona Azul';
        default:
          return zone;
      }
    }

    // Mapear método de pago
    String getMethodName(String method) {
      switch (method) {
        case 'qr':
          return 'QR';
        case 'card':
          return 'Tarjeta';
        case 'cash':
          return 'Efectivo';
        case 'mobile':
          return 'Móvil';
        case 'bizum':
          return 'Bizum';
        default:
          return method;
      }
    }

    // Formatear precio
    String formatPrice(double price) {
      if (l.startsWith('es') || l.startsWith('ca')) {
        return '${price.toStringAsFixed(2).replaceAll('.', ',')} €';
      } else {
        return '${price.toStringAsFixed(2)} €';
      }
    }

    final buffer = StringBuffer();
    buffer.writeln('🎫 *Ticket de Estacionamiento*');
    buffer.writeln('');
    buffer.writeln('🚙 *Matrícula:* $plate');
    buffer.writeln('📍 *Zona:* ${getZoneName(zone)}');
    buffer.writeln('🕐 *Inicio:* ${dateFmt.format(start)}');
    buffer.writeln('🕙 *Fin:* ${dateFmt.format(end)}');
    buffer.writeln('⏱ *Duración:* $duration');
    buffer.writeln('💳 *Pago:* ${getMethodName(method)}');

    if (discount != null && discount > 0) {
      buffer.writeln('💰 *Descuento:* ${formatPrice(discount)}');
      buffer.writeln('💵 *Total:* ${formatPrice(price)}');
    } else {
      buffer.writeln('💰 *Importe:* ${formatPrice(price)}');
    }

    buffer.writeln('');
    buffer.writeln('✅ *Gracias por su compra.*');

    if (qrData != null) {
      buffer.writeln('');
      buffer.writeln('📱 *Código QR:* $qrData');
    }

    return buffer.toString();
  }

  /// Formatea la duración entre dos fechas
  static String _formatDuration(DateTime start, DateTime end) {
    final d = end.difference(start);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
