import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'l10n/app_localizations.dart';
import 'mowiz_page.dart';
import 'mowiz_success_page.dart';

class MowizSummaryPage extends StatefulWidget {
  final String plate;
  final String zone;
  final DateTime start;
  final int minutes;
  final double price;
  const MowizSummaryPage({
    super.key,
    required this.plate,
    required this.zone,
    required this.start,
    required this.minutes,
    required this.price,
  });

  @override
  State<MowizSummaryPage> createState() => _MowizSummaryPageState();
}

class _MowizSummaryPageState extends State<MowizSummaryPage> {
  String? _method;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = l.t;
    final finish = widget.start.add(Duration(minutes: widget.minutes));
    final localeCode = l.locale.languageCode == 'es'
        ? 'es_ES'
        : l.locale.languageCode == 'ca'
            ? 'ca_ES'
            : 'en_GB';
    final timeFormat = DateFormat('EEE, d MMM yyyy - HH:mm', localeCode);

    Widget paymentButton(String value, IconData icon, String text) {
      final selected = _method == value;
      final scheme = Theme.of(context).colorScheme;
      return ElevatedButton.icon(
        onPressed: () => setState(() => _method = value),
        icon: Icon(icon, size: 40),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(80),
          backgroundColor: selected ? scheme.primary : scheme.secondary,
          foregroundColor: Colors.white,
        ),
      );
    }

    Future<void> _pay() async {
      if (_method == null) return;
      // TODO: integrate real payment logic and backend communication
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MowizSuccessPage(
            plate: widget.plate,
            zone: widget.zone,
            start: widget.start,
            minutes: widget.minutes,
            price: widget.price,
            method: _method!,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(t('summaryPay'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      t('totalTime'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.minutes ~/ 60}h ${widget.minutes % 60}m',
                      style: const TextStyle(fontSize: 36),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "${t('startTime')}: ${timeFormat.format(widget.start)}",
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${t('endTime')}: ${timeFormat.format(finish)}",
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "${t('totalPrice')}: ${widget.price.toStringAsFixed(2)} €",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            paymentButton('card', Icons.credit_card, t('card')),
            const SizedBox(height: 16),
            paymentButton('qr', Icons.qr_code_2, t('qrPay')),
            const SizedBox(height: 16),
            paymentButton('mobile', Icons.phone_iphone, t('mobilePay')),
            const Spacer(),
            ElevatedButton(
              onPressed: _method != null ? _pay : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(80),
              ),
              child: Text(t('pay')),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MowizPage()),
                  (route) => false,
                );
              },
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(80),
              ),
              child: Text(t('cancel')),
            ),
          ],
        ),
      ),
    );
  }
}
