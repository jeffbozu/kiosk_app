import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'l10n/app_localizations.dart';
import 'language_selector.dart';
import 'theme_mode_button.dart';

class PaymentSuccessPage extends StatefulWidget {
  final String ticketId;
  const PaymentSuccessPage({super.key, required this.ticketId});

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  int _seconds = 20;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds > 1) {
        setState(() => _seconds--);
      } else {
        t.cancel();
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('paymentSuccess')),
        automaticallyImplyLeading: false,
        actions: const [
          LanguageSelector(),
          SizedBox(width: 8),
          ThemeModeButton(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.t('scanQr'), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: QrImageView(
                  data: widget.ticketId,
                  version: QrVersions.auto,
                  size: 250,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.t('returningIn', params: {'seconds': '$_seconds'}),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
              child: Text(l.t('goHome')),
            ),
          ],
        ),
      ),
    );
  }
}
