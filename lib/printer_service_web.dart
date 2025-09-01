import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:universal_html/html.dart' as html;

/// Servicio de impresión web que genera y descarga tickets como PDF
class PrinterServiceWeb {
  /// Genera y descarga un ticket como PDF
  static Future<bool> printTicket({
    required String plate,
    required String zone,
    required DateTime start,
    required DateTime end,
    required double price,
    required String method,
    String? qrData,
  }) async {
    try {
      // Generar PDF del ticket
      final pdfBytes = await _generateTicketPDF(
        plate: plate,
        zone: zone,
        start: start,
        end: end,
        price: price,
        method: method,
        qrData: qrData,
      );
      
      // Crear blob y descargar
      final blob = html.Blob([pdfBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // Crear enlace de descarga
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'ticket_${plate}_${start.millisecondsSinceEpoch}.pdf')
        ..click();
      
      // Limpiar URL
      html.Url.revokeObjectUrl(url);
      
      return true;
    } catch (e) {
      print('Error generando PDF del ticket: $e');
      return false;
    }
  }
  
  /// Genera el PDF del ticket
  static Future<Uint8List> _generateTicketPDF({
    required String plate,
    required String zone,
    required DateTime start,
    required DateTime end,
    required double price,
    required String method,
    String? qrData,
  }) async {
    final pdf = pw.Document();
    
    // Generar QR como imagen
    final qrImage = await _generateQrImage(qrData ?? '');
    
    // Crear página del ticket
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              pw.Center(
                child: pw.Text(
                  'TICKET DE ESTACIONAMIENTO',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Información del ticket
              _buildInfoRow('Matrícula:', plate),
              _buildInfoRow('Zona:', _getZoneName(zone)),
              _buildInfoRow('Fecha de inicio:', _formatDateTime(start)),
              _buildInfoRow('Fecha de fin:', _formatDateTime(end)),
              _buildInfoRow('Duración:', _formatDuration(start, end)),
              pw.Divider(),
              _buildInfoRow('Precio total:', '${price.toStringAsFixed(2)} €', isBold: true),
              _buildInfoRow('Método de pago:', _getMethodName(method)),
              
              pw.SizedBox(height: 30),
              
              // QR Code
              if (qrImage != null) ...[
                pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(qrImage),
                    width: 150,
                    height: 150,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'Escanea para verificar',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey,
                    ),
                  ),
                ),
              ],
              
              pw.SizedBox(height: 20),
              
              // Pie de página
              pw.Center(
                child: pw.Text(
                  'Ticket generado el ${_formatDateTime(DateTime.now())}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    return pdf.save();
  }
  
  /// Construye una fila de información
  static pw.Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Genera imagen del QR
  static Future<Uint8List?> _generateQrImage(String qrData) async {
    try {
      if (qrData.isEmpty) return null;
      
      // En web, simulamos la generación del QR
      // En producción real, usarías una librería de generación de QR para Dart
      return null;
    } catch (e) {
      print('Error generando QR: $e');
      return null;
    }
  }
  
  /// Obtiene nombre de zona
  static String _getZoneName(String zone) {
    switch (zone.toLowerCase()) {
      case 'green':
        return 'Zona Verde';
      case 'blue':
        return 'Zona Azul';
      default:
        return zone;
    }
  }
  
  /// Obtiene nombre del método de pago
  static String _getMethodName(String method) {
    switch (method.toLowerCase()) {
      case 'card':
        return 'Tarjeta';
      case 'qr':
        return 'QR Pay';
      case 'mobile':
        return 'Apple/Google Pay';
      case 'cash':
        return 'Efectivo';
      case 'bizum':
        return 'Bizum';
      default:
        return method;
    }
  }
  
  /// Formatea fecha y hora
  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  /// Formatea duración
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
}
