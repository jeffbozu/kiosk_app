import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'l10n/app_localizations.dart';
import 'ticket_details_page.dart';

class TicketScannerPage extends StatefulWidget {
  const TicketScannerPage({super.key});

  @override
  State<TicketScannerPage> createState() => _TicketScannerPageState();
}

class _TicketScannerPageState extends State<TicketScannerPage> {
  bool _processing = false;

  void _onDetect(BarcodeCapture capture) {
    if (_processing) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;
    try {
      final map = jsonDecode(code) as Map<String, dynamic>;
      _processing = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TicketDetailsPage(data: map),
        ),
      );
    } catch (_) {
      // ignore invalid codes
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.t('scanQr'))),
      body: MobileScanner(onDetect: _onDetect),
    );
  }
}
