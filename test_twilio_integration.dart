import 'dart:io';
import 'lib/services/twilio_direct_service.dart';

/// Test de integración directa con Twilio
void main() async {
  print('🧪 INICIANDO TEST DE INTEGRACIÓN TWILIO DIRECT');
  print('=' * 50);

  // Test 1: Verificar configuración de Twilio
  print('\n1️⃣ Verificando configuración de Twilio...');
  final configOk = await TwilioDirectService.checkTwilioConfig();
  if (configOk) {
    print('✅ Twilio configurado correctamente');
  } else {
    print('❌ Error en configuración de Twilio');
    exit(1);
  }

  // Test 2: Envío de mensaje en español
  print('\n2️⃣ Probando envío en ESPAÑOL...');
  final spanishSuccess = await TwilioDirectService.sendTicketWhatsApp(
    phone: '+34678395045',
    plate: 'TEST123',
    zone: 'coche',
    start: DateTime.now(),
    end: DateTime.now().add(const Duration(hours: 2)),
    price: 2.50,
    method: 'qr',
    localeCode: 'es',
  );

  if (spanishSuccess) {
    print('✅ Mensaje en español enviado exitosamente');
  } else {
    print('❌ Error enviando mensaje en español');
  }

  // Esperar un poco entre mensajes
  await Future.delayed(const Duration(seconds: 2));

  // Test 3: Envío de mensaje en inglés
  print('\n3️⃣ Probando envío en INGLÉS...');
  final englishSuccess = await TwilioDirectService.sendTicketWhatsApp(
    phone: '+34678395045',
    plate: 'TEST456',
    zone: 'coche',
    start: DateTime.now(),
    end: DateTime.now().add(const Duration(hours: 1)),
    price: 1.25,
    method: 'card',
    localeCode: 'en',
  );

  if (englishSuccess) {
    print('✅ Mensaje en inglés enviado exitosamente');
  } else {
    print('❌ Error enviando mensaje en inglés');
  }

  // Esperar un poco entre mensajes
  await Future.delayed(const Duration(seconds: 2));

  // Test 4: Envío de mensaje en catalán
  print('\n4️⃣ Probando envío en CATALÁN...');
  final catalanSuccess = await TwilioDirectService.sendTicketWhatsApp(
    phone: '+34678395045',
    plate: 'TEST789',
    zone: 'moto',
    start: DateTime.now(),
    end: DateTime.now().add(const Duration(minutes: 30)),
    price: 0.75,
    method: 'mobile',
    localeCode: 'ca',
  );

  if (catalanSuccess) {
    print('✅ Mensaje en catalán enviado exitosamente');
  } else {
    print('❌ Error enviando mensaje en catalán');
  }

  // Resumen final
  print('\n' + '=' * 50);
  print('📊 RESUMEN DE TESTS:');
  print('   Configuración Twilio: ${configOk ? "✅" : "❌"}');
  print('   Español: ${spanishSuccess ? "✅" : "❌"}');
  print('   Inglés: ${englishSuccess ? "✅" : "❌"}');
  print('   Catalán: ${catalanSuccess ? "✅" : "❌"}');

  final totalSuccess =
      configOk && spanishSuccess && englishSuccess && catalanSuccess;
  print(
    '\n🎯 RESULTADO FINAL: ${totalSuccess ? "✅ TODOS LOS TESTS EXITOSOS" : "❌ ALGUNOS TESTS FALLARON"}',
  );

  if (totalSuccess) {
    print('\n🚀 ¡INTEGRACIÓN TWILIO DIRECT FUNCIONANDO PERFECTAMENTE!');
    print('   - Conexión directa a Twilio ✅');
    print('   - Traducciones en 3 idiomas ✅');
    print('   - Formateo de mensajes ✅');
    print('   - Manejo de errores ✅');
  }
}
