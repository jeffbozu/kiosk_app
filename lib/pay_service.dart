// lib/pay_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Función que crea un ticket en Firestore
Future<String> payTicket({
  required String zoneId,
  required String zoneName,
  required String plate,
  required int durationMinutes,
  required double price,
  required String paymentMethod,
  required String userId,
}) async {
  // Referencia a Firestore
  final firestore = FirebaseFirestore.instance;

  // Calculamos paidUntil
  final now = DateTime.now();
  final paidUntil = now.add(Duration(minutes: durationMinutes));

  // Creamos el documento en 'tickets'
  final doc = await firestore.collection('tickets').add({
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

  return doc.id;
}
