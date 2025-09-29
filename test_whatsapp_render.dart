import 'dart:convert';
import 'package:http/http.dart' as http;

/// Script de prueba para envío de WhatsApp al servidor de Render
void main() async {
  print('🧪 Probando envío de WhatsApp al servidor de Render...');
  
  // URL del servidor de WhatsApp
  const String baseUrl = 'https://render-whatsapp-tih4.onrender.com';
  const String endpoint = '$baseUrl/v1/whatsapp/send';
  
  // Datos de prueba
  final testData = {
    'phone': '+34678395045',
    'ticket': {
      'plate': 'TEST123',
      'zone': 'coche',
      'start': '29/09/2025 10:15',
      'end': '29/09/2025 12:15',
      'duration': '2h',
      'price': 2.50,
      'method': 'mobile',
      'qrData': 'QR_TEST_DATA_12345',
    },
    'localeCode': 'es',
  };

  print('📱 Enviando WhatsApp a: ${testData['phone']}');
  print('📱 URL: $endpoint');
  print('📱 Datos: ${jsonEncode(testData)}');

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

    // Enviar WhatsApp
    print('\n📤 Enviando WhatsApp...');
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

    print('\n📱 Respuesta del servidor:');
    print('   Status Code: ${response.statusCode}');
    print('   Headers: ${response.headers}');
    print('   Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print('\n✅ WhatsApp enviado exitosamente!');
      print('   Success: ${responseData['success']}');
      print('   Message: ${responseData['message'] ?? 'N/A'}');
      print('   Status: ${responseData['status'] ?? 'N/A'}');
    } else {
      print('\n❌ Error en el envío:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');
      
      try {
        final errorData = jsonDecode(response.body);
        print('   Error: ${errorData['error'] ?? 'N/A'}');
        print('   Code: ${errorData['code'] ?? 'N/A'}');
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
