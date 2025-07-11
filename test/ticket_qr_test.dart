import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:kiosk_app/ticket_success_page.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  testWidgets('TicketSuccessPage shows QR with all fields', (tester) async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('settings').doc('qrConfig').set({
      'qrFields': [
        'ticketId',
        'plate',
        'paidUntil',
        'status',
        'paymentMethod',
        'zoneId'
      ]
    });

    final paidUntil = DateTime(2025, 1, 1);
    final ticketDoc = await firestore.collection('tickets').add({
      'plate': '1234ABC',
      'paidUntil': paidUntil,
      'status': 'paid',
      'paymentMethod': 'card',
      'zoneId': 'centro',
    });

    await tester.pumpWidget(MaterialApp(
      home: TicketSuccessPage(ticketId: ticketDoc.id, firestore: firestore),
    ));

    await tester.pumpAndSettle();

    final qrWidget = tester.widget<QrImageView>(find.byType(QrImageView));
    final qrData = qrWidget.data;
    expect(qrData.split('\n').length, 6);
    expect(qrData.contains('N/A'), isFalse);
    expect(qrData.contains('1234ABC'), isTrue);
    expect(qrData.contains('card'), isTrue);
    expect(qrData.contains('centro'), isTrue);
  });
}
