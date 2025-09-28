import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// Servicio seguro de Twilio para WhatsApp usando proxy
/// Las credenciales están ocultas en el servidor proxy
class TwilioSecureService {
  // URL del proxy de Twilio (credenciales ocultas en servidor)
  static const String _proxyUrl = 'https://twilio-proxy-server.onrender.com';

  /// Envía WhatsApp usando proxy seguro
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
      print('📱 Twilio Secure - Enviando WhatsApp:');
      print('   Teléfono: $phone');
      print('   Idioma: $localeCode');

      // Obtener traducciones
      final t = _getTranslations(localeCode ?? 'es');

      // Formatear fechas según idioma
      final locale = localeCode ?? 'es';
      final dateFmt = DateFormat('dd/MM/yyyy HH:mm', locale);
      final startFormatted = dateFmt.format(start);
      final endFormatted = dateFmt.format(end);
      final duration = _formatDuration(start, end);
      final priceFormatted = _formatPrice(price, locale);

      // Crear mensaje formateado
      final message = _buildMessage(
        t: t,
        plate: plate,
        zone: zone,
        start: startFormatted,
        end: endFormatted,
        duration: duration,
        method: method,
        price: priceFormatted,
        discount: discount,
        qrData: qrData,
      );

      // Enviar a través del proxy (credenciales ocultas)
      final response = await http
          .post(
            Uri.parse('$_proxyUrl/send-whatsapp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'to': phone, 'message': message}),
          )
          .timeout(const Duration(seconds: 30));

      print('📱 Twilio Secure - Respuesta:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('✅ WhatsApp enviado exitosamente via proxy seguro');
          print('   Message SID: ${data['messageSid']}');
          return true;
        } else {
          print('❌ Error del proxy: ${data['error']}');
          return false;
        }
      } else {
        print('❌ Error HTTP del proxy: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error en TwilioSecureService: $e');
      return false;
    }
  }

  /// Obtener traducciones según idioma
  static Map<String, dynamic> _getTranslations(String locale) {
    final translations = {
      'es': {
        'title': '🎫 Ticket de Estacionamiento',
        'plate': 'Matrícula',
        'zone': 'Zona',
        'start': 'Inicio',
        'end': 'Fin',
        'duration': 'Duración',
        'method': 'Pago',
        'price': 'Importe',
        'thanks': 'Gracias por su compra',
        'footer': 'Meypark - Sistema de Gestión de Aparcamiento',
        'zones': {
          'coche': 'Zona Coche',
          'moto': 'Zona Moto',
          'camion': 'Zona Camión',
          'green': 'Zona Verde',
          'blue': 'Zona Azul',
        },
        'methods': {
          'qr': 'QR',
          'card': 'Tarjeta',
          'cash': 'Efectivo',
          'mobile': 'Móvil',
          'bizum': 'Bizum',
        },
      },
      'ca': {
        'title': '🎫 Tiquet d\'Aparcament',
        'plate': 'Matrícula',
        'zone': 'Zona',
        'start': 'Inici',
        'end': 'Fi',
        'duration': 'Durada',
        'method': 'Pagament',
        'price': 'Import',
        'thanks': 'Gràcies per la seva compra',
        'footer': 'Meypark - Sistema de Gestió d\'Aparcament',
        'zones': {
          'coche': 'Zona Cotxe',
          'moto': 'Zona Moto',
          'camion': 'Zona Camió',
          'green': 'Zona Verda',
          'blue': 'Zona Blava',
        },
        'methods': {
          'qr': 'QR',
          'card': 'Targeta',
          'cash': 'Efectiu',
          'mobile': 'Mòbil',
          'bizum': 'Bizum',
        },
      },
      'en': {
        'title': '🎫 Parking Ticket',
        'plate': 'Plate',
        'zone': 'Zone',
        'start': 'Start',
        'end': 'End',
        'duration': 'Duration',
        'method': 'Payment',
        'price': 'Amount',
        'thanks': 'Thank you for your purchase',
        'footer': 'Meypark - Parking Management System',
        'zones': {
          'coche': 'Car Zone',
          'moto': 'Motorcycle Zone',
          'camion': 'Truck Zone',
          'green': 'Green Zone',
          'blue': 'Blue Zone',
        },
        'methods': {
          'qr': 'QR',
          'card': 'Card',
          'cash': 'Cash',
          'mobile': 'Mobile',
          'bizum': 'Bizum',
        },
      },
    };
    return translations[locale] ?? translations['es']!;
  }

  /// Construir mensaje formateado
  static String _buildMessage({
    required Map<String, dynamic> t,
    required String plate,
    required String zone,
    required String start,
    required String end,
    required String duration,
    required String method,
    required String price,
    double? discount,
    String? qrData,
  }) {
    final zones = t['zones'] as Map<String, String>;
    final zoneName = zones[zone] ?? zone;
    final methods = t['methods'] as Map<String, String>;
    final methodName = methods[method] ?? method;

    final buffer = StringBuffer();
    buffer.writeln('${t['title']}');
    buffer.writeln('');
    buffer.writeln('🚙 *${t['plate']}:* $plate');
    buffer.writeln('📍 *${t['zone']}:* $zoneName');
    buffer.writeln('🕐 *${t['start']}:* $start');
    buffer.writeln('🕙 *${t['end']}:* $end');
    buffer.writeln('⏱ *${t['duration']}:* $duration');
    buffer.writeln('💳 *${t['method']}:* $methodName');

    if (discount != null && discount > 0) {
      buffer.writeln('💰 *Descuento:* ${_formatPrice(discount, 'es')}');
      buffer.writeln('💵 *Total:* $price');
    } else {
      buffer.writeln('💰 *${t['price']}:* $price');
    }

    buffer.writeln('');
    buffer.writeln('✅ *${t['thanks']}*');

    if (qrData != null) {
      buffer.writeln('');
      buffer.writeln('📱 *Código QR:* $qrData');
    }

    buffer.writeln('');
    buffer.writeln('📱 *${t['footer']}*');
    buffer.writeln(
      '🕐 *Fecha:* ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
    );

    return buffer.toString();
  }

  /// Formatear duración
  static String _formatDuration(DateTime start, DateTime end) {
    final d = end.difference(start);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  /// Formatear precio
  static String _formatPrice(double price, String locale) {
    if (locale.startsWith('es') || locale.startsWith('ca')) {
      return '${price.toStringAsFixed(2).replaceAll('.', ',')} €';
    } else {
      return '${price.toStringAsFixed(2)} €';
    }
  }
}
