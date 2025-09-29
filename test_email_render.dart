import 'dart:convert';
import 'package:http/http.dart' as http;

/// Script de prueba para envío de email al servidor de Render
void main() async {
  print('🧪 Probando envío de email al servidor de Render...');
  
  // URL del servidor de Render
  const String baseUrl = 'https://render-mail-2bzn.onrender.com';
  const String endpoint = '$baseUrl/api/send-email';
  
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
    'qrData': 'QR_TEST_DATA_12345',
    'discount': 0.0,
  };

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

    if (healthResponse.statusCode != 200) {
      print('❌ Servidor no disponible');
      return;
    }

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
      print('   Processing Time: ${responseData['processingTime'] ?? 'N/A'}ms');
    } else {
      print('\n❌ Error en el envío:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');
      
      try {
        final errorData = jsonDecode(response.body);
        print('   Error: ${errorData['error'] ?? 'N/A'}');
        print('   Details: ${errorData['details'] ?? 'N/A'}');
      } catch (e) {
        print('   No se pudo parsear el error');
      }
    }
  } catch (e) {
    print('\n❌ Error en la prueba: $e');
    print('   Tipo de error: ${e.runtimeType}');
  }
}
