import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

/// Helper function to format price with correct decimal separator based on locale
String formatPrice(double price, String locale) {
  if (locale.startsWith('es') || locale.startsWith('ca')) {
    // Use comma as decimal separator for Spanish and Catalan
    return '${price.toStringAsFixed(2).replaceAll('.', ',')} €';
  } else {
    // Use dot as decimal separator for English and others
    return '${price.toStringAsFixed(2)} €';
  }
}

/// Servicio alternativo que abre WhatsApp Web con el mensaje pre-escrito
class WhatsAppWebService {
  /// Envía un ticket por WhatsApp Web
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
      // Formatear el número de teléfono
      final formattedPhone = _formatPhoneNumber(phone);
      
      // Generar el mensaje del ticket
      final message = _generateTicketMessage(
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
      
      // Crear URL de WhatsApp Web
      final whatsappUrl = 'https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}';
      
      print('📱 WhatsApp Web - Abriendo: $whatsappUrl');
      
      // Abrir WhatsApp Web
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        print('❌ No se puede abrir WhatsApp Web');
        return false;
      }
    } catch (e) {
      print('❌ Error en WhatsApp Web: $e');
      return false;
    }
  }

  /// Formatea el número de teléfono para WhatsApp
  static String _formatPhoneNumber(String phone) {
    // Remover todos los caracteres no numéricos
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Si empieza con 34 (España), mantenerlo
    if (cleanPhone.startsWith('34')) {
      return cleanPhone;
    }
    // Si empieza con 6, 7, 8, 9 (móviles españoles), agregar 34
    else if (cleanPhone.startsWith(RegExp(r'[6789]')) && cleanPhone.length == 9) {
      return '34$cleanPhone';
    }
    // Si tiene 9 dígitos y no empieza con 34, agregar 34
    else if (cleanPhone.length == 9) {
      return '34$cleanPhone';
    }
    // En otros casos, devolver tal como está
    return cleanPhone;
  }
  
  /// Genera el mensaje del ticket
  static String _generateTicketMessage({
    required String plate,
    required String zone,
    required DateTime start,
    required DateTime end,
    required double price,
    required String method,
    double? discount,
    String? qrData,
    String? localeCode,
  }) {
    final l = localeCode ?? 'es_ES';
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm', l);
    final duration = _formatDuration(start, end);
    
    final buffer = StringBuffer();
    buffer.writeln('🎫 *TICKET DE ESTACIONAMIENTO*');
    buffer.writeln('');
    buffer.writeln('🚗 *Matrícula:* $plate');
    buffer.writeln('📍 *Zona:* $zone');
    buffer.writeln('⏰ *Inicio:* ${dateFmt.format(start)}');
    buffer.writeln('⏰ *Fin:* ${dateFmt.format(end)}');
    buffer.writeln('⏱️ *Duración:* $duration');
    buffer.writeln('💳 *Método:* $method');
    
    if (discount != null && discount > 0) {
      buffer.writeln('💰 *Descuento:* ${formatPrice(discount, localeCode ?? 'es')}');
    }
    
    buffer.writeln('💵 *Precio:* ${formatPrice(price, localeCode ?? 'es')}');
    buffer.writeln('');
    buffer.writeln('✅ *Pago procesado exitosamente*');
    buffer.writeln('');
    buffer.writeln('📱 *KioskApp* - Sistema de Estacionamiento');
    
    if (qrData != null && qrData.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('🔗 *Código QR:* $qrData');
    }
    
    return buffer.toString();
  }
  
  /// Formatea la duración
  static String _formatDuration(DateTime start, DateTime end) {
    final d = end.difference(start);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

