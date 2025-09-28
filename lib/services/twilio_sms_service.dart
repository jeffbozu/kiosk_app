import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// Servicio directo de Twilio para SMS
/// Conecta directamente con la API de Twilio para envío de SMS
class TwilioSMSService {
  // Credenciales de Twilio (hardcodeadas para producción)
  static const String _accountSid =
      'ACa1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6'; // Reemplazar con tu Account SID real
  static const String _authToken =
      'tu_auth_token_real'; // Reemplazar con tu Auth Token real
  static const String _fromNumber = '+15342009076'; // Tu número de Twilio

  // URL base de la API de Twilio
  static const String _baseUrl =
      'https://api.twilio.com/2010-04-01/Accounts/$_accountSid';

  // Traducciones para SMS
  static const Map<String, Map<String, dynamic>> _translations = {
    'es': {
      'title': 'Ticket de Estacionamiento',
      'plate': 'Matrícula',
      'zone': 'Zona',
      'start': 'Inicio',
      'end': 'Fin',
      'duration': 'Duración',
      'payment': 'Pago',
      'amount': 'Importe',
      'thanks': 'Gracias por su compra.',
      'zones': {
        'coche': 'Zona Coche',
        'moto': 'Zona Moto',
        'camion': 'Zona Camión',
        'green': 'Zona Verde',
        'blue': 'Zona Azul',
      },
    },
    'ca': {
      'title': 'Tiquet d\'Aparcament',
      'plate': 'Matrícula',
      'zone': 'Zona',
      'start': 'Inici',
      'end': 'Fi',
      'duration': 'Durada',
      'payment': 'Pagament',
      'amount': 'Import',
      'thanks': 'Gràcies per la seva compra.',
      'zones': {
        'coche': 'Zona Cotxe',
        'moto': 'Zona Moto',
        'camion': 'Zona Camió',
        'green': 'Zona Verda',
        'blue': 'Zona Blava',
      },
    },
    'en': {
      'title': 'Parking Ticket',
      'plate': 'Plate',
      'zone': 'Zone',
      'start': 'Start',
      'end': 'End',
      'duration': 'Duration',
      'payment': 'Payment',
      'amount': 'Amount',
      'thanks': 'Thank you for your purchase.',
      'zones': {
        'coche': 'Car Zone',
        'moto': 'Motorcycle Zone',
        'camion': 'Truck Zone',
        'green': 'Green Zone',
        'blue': 'Blue Zone',
      },
    },
  };

  /// Envía un ticket por SMS directamente a Twilio
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
      // Detectar idioma
      final locale = _detectLocale(localeCode);
      final t = _translations[locale] ?? _translations['es']!;

      // Los datos ya vienen con la hora correcta de España desde la app
      // No necesitamos aplicar corrección adicional
      final startLocal = start;
      final endLocal = end;
      final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
      final duration = _formatDuration(start, end);
      final zones = t['zones'] as Map<String, String>;
      final zoneName = zones[zone] ?? zone;
      final methodName = _getMethodName(method, locale);
      final priceFormatted = _formatPrice(price, locale);

      // Crear mensaje formateado con hora local
      final message = _buildMessage(
        t: t,
        plate: plate,
        zoneName: zoneName,
        start: dateFmt.format(startLocal),
        end: dateFmt.format(endLocal),
        duration: duration,
        method: methodName,
        price: priceFormatted,
      );

      print('📱 Twilio SMS - Enviando mensaje:');
      print('   Teléfono: $phone');
      print('   Idioma: $locale');
      print('   Mensaje: ${message.substring(0, 100)}...');

      // Delay para evitar error 429 (Too Many Requests)
      await Future.delayed(const Duration(seconds: 2));

      // Enviar a Twilio API
      final success = await _sendToTwilio(to: phone, message: message);

      if (success) {
        print('✅ SMS enviado exitosamente via Twilio Direct');
        return true;
      } else {
        print('❌ Error enviando SMS via Twilio Direct');
        return false;
      }
    } catch (e) {
      print('❌ Error en TwilioSMSService: $e');
      return false;
    }
  }

  /// Envía mensaje directamente a la API de Twilio
  static Future<bool> _sendToTwilio({
    required String to,
    required String message,
  }) async {
    try {
      // Formatear número de teléfono
      final formattedTo = _formatPhoneNumber(to);

      // Crear autenticación básica
      final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));

      // Preparar datos del mensaje
      final body = {'From': _fromNumber, 'To': formattedTo, 'Body': message};

      // Enviar petición HTTP POST
      final response = await http
          .post(
            Uri.parse('$_baseUrl/Messages.json'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Authorization': 'Basic $credentials',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      print('📱 Twilio SMS API Response:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ SMS enviado - SID: ${data['sid']}');
        return true;
      } else {
        print('❌ Error de Twilio SMS API: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error enviando SMS a Twilio: $e');
      return false;
    }
  }

  /// Construye el mensaje formateado para SMS
  static String _buildMessage({
    required Map<String, dynamic> t,
    required String plate,
    required String zoneName,
    required String start,
    required String end,
    required String duration,
    required String method,
    required String price,
  }) {
    final lines = <String>[];

    lines.add(t['title'] as String);
    lines.add('');
    lines.add('${t['plate'] as String}: $plate');
    lines.add('${t['zone'] as String}: $zoneName');
    lines.add('${t['start'] as String}: $start');
    lines.add('${t['end'] as String}: $end');
    lines.add('${t['duration'] as String}: $duration');
    lines.add('${t['payment'] as String}: $method');
    lines.add('${t['amount'] as String}: $price');
    lines.add('');
    lines.add(t['thanks'] as String);

    return lines.join('\n');
  }

  /// Detecta el idioma del locale
  static String _detectLocale(String? localeCode) {
    if (localeCode == null) return 'es';

    if (localeCode.startsWith('ca')) return 'ca';
    if (localeCode.startsWith('en')) return 'en';
    return 'es';
  }

  /// Formatea la duración
  static String _formatDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }

  /// Obtiene el nombre del método de pago
  static String _getMethodName(String method, String locale) {
    const methods = {
      'es': {
        'card': 'Tarjeta',
        'qr': 'QR Pay',
        'mobile': 'Apple/Google Pay',
        'cash': 'Efectivo',
        'bizum': 'Bizum',
      },
      'ca': {
        'card': 'Targeta',
        'qr': 'QR Pay',
        'mobile': 'Apple/Google Pay',
        'cash': 'Efectiu',
        'bizum': 'Bizum',
      },
      'en': {
        'card': 'Card',
        'qr': 'QR Pay',
        'mobile': 'Apple/Google Pay',
        'cash': 'Cash',
        'bizum': 'Bizum',
      },
    };

    return methods[locale]?[method] ?? method;
  }

  /// Formatea el precio según el idioma
  static String _formatPrice(double price, String locale) {
    if (locale == 'es' || locale == 'ca') {
      return '${price.toStringAsFixed(2).replaceAll('.', ',')} €';
    }
    return '${price.toStringAsFixed(2)} €';
  }

  /// Formatea el número de teléfono
  static String _formatPhoneNumber(String phone) {
    // Limpiar número
    String cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Agregar prefijo internacional si no lo tiene
    if (!cleanPhone.startsWith('+')) {
      if (cleanPhone.startsWith('34')) {
        cleanPhone = '+' + cleanPhone;
      } else if (cleanPhone.startsWith('6') || cleanPhone.startsWith('7')) {
        cleanPhone = '+34' + cleanPhone;
      } else {
        cleanPhone = '+34' + cleanPhone;
      }
    }

    return cleanPhone;
  }

  /// Verifica la configuración de Twilio
  static Future<bool> checkTwilioConfig() async {
    try {
      final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));

      final response = await http
          .get(
            Uri.parse('$_baseUrl.json'),
            headers: {'Authorization': 'Basic $credentials'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ Twilio SMS configurado correctamente');
        return true;
      } else {
        print('❌ Error en configuración de Twilio SMS: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error verificando Twilio SMS: $e');
      return false;
    }
  }

  /// Detecta si estamos en horario de verano en España
  static bool _isDaylightSavingTime(DateTime date) {
    // En España, el horario de verano va del último domingo de marzo al último domingo de octubre
    final year = date.year;

    // Último domingo de marzo
    final marchLastSunday = _getLastSundayOfMonth(year, 3);
    final marchLastSundayDate = DateTime(year, 3, marchLastSunday, 2, 0, 0);

    // Último domingo de octubre
    final octoberLastSunday = _getLastSundayOfMonth(year, 10);
    final octoberLastSundayDate = DateTime(
      year,
      10,
      octoberLastSunday,
      3,
      0,
      0,
    );

    return date.isAfter(marchLastSundayDate) &&
        date.isBefore(octoberLastSundayDate);
  }

  /// Obtiene el último domingo de un mes
  static int _getLastSundayOfMonth(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0).day; // Último día del mes
    for (int day = lastDay; day >= 1; day--) {
      final date = DateTime(year, month, day);
      if (date.weekday == DateTime.sunday) {
        return day;
      }
    }
    return 1; // Fallback
  }

  /// Test de envío de SMS
  static Future<bool> testMessage() async {
    try {
      print('🧪 Probando envío directo de SMS a Twilio...');

      final success = await sendTicketSMS(
        phone: '+34678395045',
        plate: 'TESTSMS123',
        zone: 'coche',
        start: DateTime.now(),
        end: DateTime.now().add(const Duration(hours: 2)),
        price: 2.50,
        method: 'qr',
        localeCode: 'es',
      );

      if (success) {
        print('✅ Test de SMS Twilio exitoso');
        return true;
      } else {
        print('❌ Test de SMS Twilio falló');
        return false;
      }
    } catch (e) {
      print('❌ Error en test de SMS Twilio: $e');
      return false;
    }
  }
}
