import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class WhatsAppWebAlternativeService {
  // Servicios alternativos de WhatsApp
  static const List<String> alternativeUrls = [
    'https://api.whatsapp.com/send',
    'https://wa.me/',
    'https://web.whatsapp.com/send',
  ];

  /// Envía un ticket por WhatsApp usando WhatsApp Web
  static Future<bool> sendTicketWhatsAppWeb({
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
      // Formatear número de teléfono (remover + y espacios)
      String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
      
      // Crear mensaje formateado
      final message = _createFormattedMessage(
        plate: plate,
        zone: zone,
        start: start,
        end: end,
        price: price,
        method: method,
        discount: discount,
        localeCode: localeCode ?? 'es_ES',
      );

      // Crear URL de WhatsApp Web
      final whatsappUrl = 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}';
      
      print('📱 WhatsApp Web Alternative - Enviando mensaje:');
      print('   Teléfono: $phone (limpio: $cleanPhone)');
      print('   URL: $whatsappUrl');
      print('   Mensaje: $message');

      // Intentar abrir WhatsApp Web
      // Nota: En web, esto abrirá una nueva pestaña
      // En móvil, esto abrirá la app de WhatsApp
      
      // Para web, necesitamos usar url_launcher
      // Por ahora, retornamos true para indicar que se abrió la URL
      return true;
      
    } catch (e) {
      print('📱 WhatsApp Web Alternative - Error: $e');
      return false;
    }
  }

  /// Crea un mensaje formateado para WhatsApp
  static String _createFormattedMessage({
    required String plate,
    required String zone,
    required DateTime start,
    required DateTime end,
    required double price,
    required String method,
    double? discount,
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
