import 'dart:convert';
import 'package:http/http.dart' as http;

/// Script de prueba detallada para WhatsApp
void main() async {
  print('🧪 Probando WhatsApp con diferentes formatos...');
  
  const String baseUrl = 'https://render-whatsapp-tih4.onrender.com';
  
  // Probar diferentes endpoints
  final endpoints = [
    '/v1/whatsapp/send',
    '/api/whatsapp/send',
    '/whatsapp/send',
  ];
  
  // Probar diferentes formatos de datos
  final testFormats = [
    // Formato 1: Con ticket anidado
    {
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
    },
    
    // Formato 2: Datos planos
    {
      'phone': '+34678395045',
      'plate': 'TEST123',
      'zone': 'coche',
      'start': '29/09/2025 10:15',
      'end': '29/09/2025 12:15',
      'duration': '2h',
      'price': 2.50,
      'method': 'mobile',
      'qrData': 'QR_TEST_DATA_12345',
      'localeCode': 'es',
    },
    
    // Formato 3: Con message explícito
    {
      'phone': '+34678395045',
      'message': '🎫 *Ticket de Estacionamiento*\n\n🚙 *Matrícula:* TEST123\n📍 *Zona:* Zona Coche\n🕐 *Inicio:* 29/09/2025 10:15\n🕙 *Fin:* 29/09/2025 12:15\n⏱ *Duración:* 2h\n💳 *Pago:* Móvil\n💰 *Importe:* 2,50€\n\n✅ *Gracias por su compra.*',
      'plate': 'TEST123',
      'zone': 'coche',
      'start': '29/09/2025 10:15',
      'end': '29/09/2025 12:15',
      'duration': '2h',
      'price': 2.50,
      'method': 'mobile',
      'qrData': 'QR_TEST_DATA_12345',
      'localeCode': 'es',
    },
  ];

  for (int i = 0; i < endpoints.length; i++) {
    final endpoint = endpoints[i];
    print('\n🔍 Probando endpoint: $endpoint');
    
    for (int j = 0; j < testFormats.length; j++) {
      final testData = testFormats[j];
      print('\n📱 Formato ${j + 1}:');
      print('   Datos: ${jsonEncode(testData)}');
      
      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl$endpoint'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode(testData),
            )
            .timeout(const Duration(seconds: 15));

        print('   Status: ${response.statusCode}');
        print('   Body: ${response.body}');
        
        if (response.statusCode == 200) {
          print('   ✅ ¡Éxito!');
          return;
        }
      } catch (e) {
        print('   ❌ Error: $e');
      }
    }
  }
  
  print('\n🏁 Todas las pruebas completadas');
}
