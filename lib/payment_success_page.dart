import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _askEmailDone = false;
  int _seconds = 10;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    _seconds = 10;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds > 1) {
        setState(() => _seconds--);
      } else {
        t.cancel();
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    });
  }

  Future<void> _sendEmail() async {
    final email = await _askForEmail();
    if (email != null) await _launchEmail(email);
    setState(() => _askEmailDone = true);
    _startCountdown();
  }

  Future<String?> _askForEmail() async {
    String email = '';
    final l = AppLocalizations.of(context);
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l.t('enterEmail')),
        content: TextField(
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'correo@ejemplo.com'),
          onChanged: (v) => email = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(l.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email)) {
                Navigator.pop(ctx, email);
              }
            },
            child: Text(l.t('send')),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Ticket Kiosk&body=Tu ticket: ${widget.ticketId}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
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
            Text(l.t('digitalTicket'), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Center(
              child: QrImageView(
                data: widget.ticketId,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const Spacer(),
            if (!_askEmailDone) ...[
              Text(l.t('sendTicketEmail'), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() => _askEmailDone = true);
                      _startCountdown();
                    },
                    child: Text(l.t('no')),
                  ),
                  ElevatedButton(
                    onPressed: _sendEmail,
                    child: Text(l.t('yes')),
                  ),
                ],
              ),
            ] else ...[
              Text(
                l.t('returningIn', params: {'seconds': '$_seconds'}),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: Text(l.t('goHome')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
