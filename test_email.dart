import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// Script de prueba para envío de email
void main() async {
  print('🧪 Iniciando prueba de envío de email...');
  
  // Datos de prueba
  final testData = {
    'recipientEmail': 'yefreyesteban@gmail.com',
    'plate': 'TEST123',
    'zone': 'coche',
    'start': DateTime.now().toIso8601String(),
    'end': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
    'price': 2.50,
    'method': 'tarjeta',
    'locale': 'es',
    'provider': 'gmail',
    'qrData': 'QR_TEST_DATA_12345',
  };

  // URL del servidor de email
  const String baseUrl = 'https://render-mail-2bzn.onrender.com';
  const String endpoint = '$baseUrl/api/send-email';

  print('📧 Enviando email a: ${testData['recipientEmail']}');
  print('📧 URL: $endpoint');
  print('📧 Datos: ${jsonEncode(testData)}');

  try {
    // Verificar salud del servidor primero
    print('\n🔍 Verificando salud del servidor...');
    final healthResponse = await http.get(
      Uri.parse('$baseUrl/health'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    print('🏥 Health Status: ${healthResponse.statusCode}');
    print('🏥 Health Body: ${healthResponse.body}');

    // Enviar email
    print('\n📤 Enviando email...');
    final response = await http
        .post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(testData),
        )
        .timeout(const Duration(seconds: 30));

    print('\n📧 Respuesta del servidor:');
    print('   Status Code: ${response.statusCode}');
    print('   Headers: ${response.headers}');
    print('   Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print('\n✅ Email enviado exitosamente!');
      print('   Success: ${responseData['success']}');
      print('   Message: ${responseData['message'] ?? 'N/A'}');
    } else {
      print('\n❌ Error en el envío:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');
    }
  } catch (e) {
    print('\n❌ Error en la prueba: $e');
    print('   Tipo de error: ${e.runtimeType}');
  }
}
