import 'package:cloud_firestore/cloud_firestore.dart';

/// Función que crea un ticket en Firestore
/// Permite inyectar una instancia opcional de Firestore para test o mocks.
Future<String> payTicket({
  required String zoneId,
  required String zoneName,
  required String plate,
  required int durationMinutes,
  required double price,
  required String paymentMethod,
  required String userId,
  FirebaseFirestore? firestore,  // parámetro opcional para inyección
}) async {
  // Usa la instancia inyectada o la instancia por defecto
  final fs = firestore ?? FirebaseFirestore.instance;

  // Calculamos paidUntil
  final now = DateTime.now();
  final paidUntil = now.add(Duration(minutes: durationMinutes));

  // Creamos el documento en 'tickets' usando la instancia correcta
  final doc = await fs.collection('tickets').add({
    'zoneId': zoneId,
    'zoneName': zoneName,
    'plate': plate,
    'paidUntil': Timestamp.fromDate(paidUntil),
    'status': 'paid',
    'duration': durationMinutes,
    'price': price,
    'paymentMethod': paymentMethod,
    'userId': userId,
  });

  // Retornamos el id del nuevo documento
  return doc.id;
}
