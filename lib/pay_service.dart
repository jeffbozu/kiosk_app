// lib/pay_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Función que crea un ticket en Firestore
Future<void> payTicket({
  required String zoneId,
  required String plate,
  required int durationMinutes,
}) async {
  // Referencia a Firestore y usuario actual
  final firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('Usuario no autenticado');
  }

  // Calculamos paidUntil
  final now = DateTime.now();
  final paidUntil = now.add(Duration(minutes: durationMinutes));

  // Creamos el documento en 'tickets'
  await firestore.collection('tickets').add({
    'userId': user.email,
    'zoneId': zoneId,
    'plate': plate,
    'paidUntil': Timestamp.fromDate(paidUntil),
    'status': 'paid',
  });
}
