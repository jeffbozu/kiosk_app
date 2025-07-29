import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'l10n/app_localizations.dart';
import 'mowiz_page.dart';
import 'mowiz_success_page.dart';
import 'mowiz/mowiz_scaffold.dart';
import 'styles/mowiz_buttons.dart';
import 'sound_helper.dart';

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

    Widget paymentButton(String value, IconData icon, String text, double fSize) {
      final selected = _method == value;
      final scheme = Theme.of(context).colorScheme;
      return FilledButton.icon(
        onPressed: () {
          SoundHelper.playTap();
          setState(() => _method = value);
        },
        icon: Icon(icon, size: fSize + 12),
        label: AutoSizeText(text, maxLines: 1),
        style: kMowizFilledButtonStyle.copyWith(
          textStyle: MaterialStatePropertyAll(TextStyle(fontSize: fSize)),
          backgroundColor: MaterialStatePropertyAll(
            selected ? scheme.primary : scheme.secondary,
          ),
        ),
      );
    }

  Future<void> _pay() async {
    if (_method == null) return;
    final plate = widget.plate.toUpperCase();
    try {
      // save paid plate
      final res = await http.post(
        Uri.parse('http://localhost:3000/v1/onstreet-service/pay-ticket'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'plate': plate}),
      );
      if (res.statusCode != 200) {
        debugPrint('HTTP ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
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

    return MowizScaffold(
      title: t('summaryPay'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isLargeTablet = width >= 900;
          final isTablet = width >= 600 && width < 900;
          final padding = EdgeInsets.all(width * 0.05);
          final double gap = width * 0.04;
          final double titleFont = isLargeTablet
              ? 32
              : isTablet
                  ? 28
                  : 24;

          return Padding(
            padding: padding,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            // Cuadro con la información resumida del ticket.
            // Se deja crecer de forma dinámica y con scroll interno
            // para evitar cualquier overflow si hay mucho texto.
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    AutoSizeText(
                      t('totalTime'),
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: titleFont - 4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AutoSizeText(
                      '${widget.minutes ~/ 60}h ${widget.minutes % 60}m',
                      maxLines: 1,
                      style: TextStyle(fontSize: titleFont + 8),
                    ),
                    const SizedBox(height: 16),
                    AutoSizeText(
                      "${t('startTime')}: ${timeFormat.format(widget.start)}",
                      maxLines: 1,
                      style: TextStyle(fontSize: titleFont - 4),
                    ),
                    const SizedBox(height: 8),
                    AutoSizeText(
                      "${t('endTime')}: ${timeFormat.format(finish)}",
                      maxLines: 1,
                      style: TextStyle(fontSize: titleFont - 4),
                    ),
                    const SizedBox(height: 16),
                    AutoSizeText(
                      "${t('totalPrice')}: ${widget.price.toStringAsFixed(2)} €",
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: titleFont,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ),
            SizedBox(height: gap * 2),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.1),
              child: paymentButton('card', Icons.credit_card, t('card'), titleFont),
            ),
            SizedBox(height: gap),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.1),
              child: paymentButton('qr', Icons.qr_code_2, t('qrPay'), titleFont),
            ),
            SizedBox(height: gap),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.1),
              child:
                  paymentButton('mobile', Icons.phone_iphone, t('mobilePay'), titleFont),
            ),
            SizedBox(height: gap * 2),
            FilledButton(
              onPressed: _method != null
                  ? () {
                      SoundHelper.playTap();
                      _pay();
                    }
                  : null,
              style: kMowizFilledButtonStyle.copyWith(
                textStyle: MaterialStatePropertyAll(
                  TextStyle(fontSize: titleFont),
                ),
              ),
              child: AutoSizeText(t('pay'), maxLines: 1),
            ),
            SizedBox(height: gap),
            FilledButton(
              onPressed: () {
                SoundHelper.playTap();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MowizPage()),
                  (route) => false,
                );
              },
              style: kMowizFilledButtonStyle.copyWith(
                backgroundColor: MaterialStatePropertyAll(
                  Theme.of(context).colorScheme.secondary,
                ),
                textStyle: MaterialStatePropertyAll(
                  TextStyle(fontSize: titleFont),
                ),
              ),
              child: AutoSizeText(t('cancel'), maxLines: 1),
            ),
          ],
        ),
        ),
      );
        },
      ),
    );
  }
}
