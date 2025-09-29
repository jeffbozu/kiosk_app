import 'dart:convert';
import 'package:http/http.dart' as http;

/// Script simple para probar el envío de email
void main() async {
  print('🧪 Probando envío de email simple...');
  
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

  // Probar diferentes servidores
  final servers = [
    'https://render-mail-2bzn.onrender.com',
    'https://sendgrid-proxy.onrender.com',
    'https://email-service.onrender.com',
  ];

  for (final server in servers) {
    print('\n🔍 Probando servidor: $server');
    
    try {
      // Verificar salud
      final healthResponse = await http.get(
        Uri.parse('$server/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      print('   Health Status: ${healthResponse.statusCode}');
      
      if (healthResponse.statusCode == 200) {
        print('   ✅ Servidor disponible');
        
        // Probar envío
        final response = await http
            .post(
              Uri.parse('$server/api/send-email'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode(testData),
            )
            .timeout(const Duration(seconds: 10));

        print('   📧 Email Status: ${response.statusCode}');
        print('   📧 Response: ${response.body}');
        
        if (response.statusCode == 200) {
          print('   ✅ Email enviado exitosamente!');
          break;
        }
      } else {
        print('   ❌ Servidor no disponible');
      }
    } catch (e) {
      print('   ❌ Error: $e');
    }
  }
  
  print('\n🏁 Prueba completada');
}
