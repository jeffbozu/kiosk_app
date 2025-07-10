import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'qr_config_provider.dart';

class TicketDetailsPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const TicketDetailsPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final qrFields = context.watch<QrConfig>().qrFields;

    final ticketId = data['ticketId'] as String?;
    final stream = ticketId != null
        ? FirebaseFirestore.instance
            .collection('tickets')
            .doc(ticketId)
            .snapshots()
        : const Stream.empty();

    TextStyle valueStyle([Color? c]) =>
        TextStyle(fontWeight: FontWeight.bold, color: c ?? scheme.onBackground);

    Widget row(String label, String value, {Color? color}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(value, style: valueStyle(color)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.t('ticketDetails'))),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          final docData = snapshot.data?.data() ?? <String, dynamic>{};
          final merged = {...data, ...docData};

          final widgets = <Widget>[];
          for (final field in qrFields) {
            final value = field == 'ticketId' ? ticketId : merged[field];
            if (value == null) continue;
            Color? color;
            if (field == 'status') {
              if (value.toString() == 'paid') {
                color = Colors.green;
              } else if (value.toString() == 'cancelled') {
                color = Colors.red;
              }
            }
            final key = field == 'zoneName'
                ? 'zone'
                : field;
            widgets.add(row(l.t(key), value.toString(), color: color));
          }

          if (widgets.isEmpty) {
            return const SizedBox();
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widgets,
            ),
          );
        },
      ),
    );
  }
}
