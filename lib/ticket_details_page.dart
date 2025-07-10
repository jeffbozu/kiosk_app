import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';

class TicketDetailsPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const TicketDetailsPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final status = data['status']?.toString();
    Color? statusColor;
    if (status == 'paid') {
      statusColor = Colors.green;
    } else if (status == 'cancelled') {
      statusColor = Colors.red;
    }
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

    final widgets = <Widget>[];
    void add(String field, String labelKey) {
      final value = data[field];
      if (value == null) return;
      widgets.add(row(labelKey == 'status' ? l.t('status') : l.t(labelKey),
          value.toString(),
          color: field == 'status' ? statusColor : null));
    }

    add('ticketId', 'ticketId');
    add('plate', 'plate');
    add('zoneName', 'zone');
    add('paidUntil', 'validUntil');
    add('paymentMethod', 'paymentMethod');
    add('status', 'status');
    add('price', 'price');

    return Scaffold(
      appBar: AppBar(title: Text(l.t('ticketDetails'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets),
      ),
    );
  }
}
