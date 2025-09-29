import 'dart:convert';
import 'package:http/http.dart' as http;

/// Script de prueba para envío de email a jbolanos@meypar.com
void main() async {
  print('🧪 Probando envío de email a jbolanos@meypar.com...');
  
  // URL del servidor de email
  const String baseUrl = 'https://render-mail-2bzn.onrender.com';
  const String endpoint = '$baseUrl/api/send-email';
  
  // Datos de prueba
  final testData = {
    'recipientEmail': 'jbolanos@meypar.com',
    'plate': 'TEST123',
    'zone': 'coche',
    'start': DateTime.now().toIso8601String(),
    'end': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
    'price': 2.50,
    'method': 'tarjeta',
    'locale': 'es',
    'qrData': 'QR_TEST_DATA_12345',
    'discount': 0.0,
  };

  print('📧 Enviando email a: ${testData['recipientEmail']}');
  print('📧 URL: $endpoint');
  print('📧 Datos: ${jsonEncode(testData)}');

  try {
    // Verificar salud del servidor primero
    print('\\n🔍 Verificando salud del servidor...');
    final healthResponse = await http.get(
      Uri.parse('$baseUrl/health'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    print('📊 Health Status: ${healthResponse.statusCode}');
    if (healthResponse.statusCode == 200) {
      final healthData = jsonDecode(healthResponse.body);
      print('📊 Health Data: ${jsonEncode(healthData)}');
    }

    // Enviar email
    print('\\n📧 Enviando email...');
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(testData),
    ).timeout(const Duration(seconds: 30));

    print('\\n📊 Resultados:');
    print('Status Code: ${response.statusCode}');
    print('Headers: ${response.headers}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print('\\n✅ Email enviado exitosamente!');
      print('Success: ${responseData['success']}');
      print('Message: ${responseData['message']}');
      if (responseData['messageId'] != null) {
        print('Message ID: ${responseData['messageId']}');
      }
    } else {
      print('\\n❌ Error en el envío');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
    }

  } catch (e) {
    print('\\n❌ Error en la prueba: $e');
    print('Tipo de error: ${e.runtimeType}');
  }
}
