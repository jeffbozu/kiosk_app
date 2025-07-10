import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// TODO: Cambiar `qrFields` en Firestore (p. ej. añadir "price") y comprobar
/// que la app muestra el nuevo dato sin recompilar.
class QrConfig extends ChangeNotifier {
  QrConfig() {
    final doc = FirebaseFirestore.instance
        .collection('settings')
        .doc('qrConfig');
    _sub = doc.snapshots().listen(_update);
  }

  late final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> _sub;
  List<String> _qrFields = ['ticketId'];

  List<String> get qrFields => List.unmodifiable(_qrFields);

  void _update(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data();
    final fields = data?['qrFields'];
    List<String> newFields = ['ticketId'];
    if (fields is List) {
      newFields = fields.whereType<String>().toList();
      if (newFields.isEmpty) newFields = ['ticketId'];
    }
    if (!listEquals(newFields, _qrFields)) {
      _qrFields = newFields;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
