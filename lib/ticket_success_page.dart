import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'l10n/app_localizations.dart';
import 'language_selector.dart';
import 'theme_mode_button.dart';

class TicketSuccessPage extends StatefulWidget {
  final String ticketId;
  final String qrData;
  const TicketSuccessPage({super.key, required this.ticketId, required this.qrData});

  @override
  State<TicketSuccessPage> createState() => _TicketSuccessPageState();
}

class _TicketSuccessPageState extends State<TicketSuccessPage> {
  int _seconds = 20;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown(20);
  }

  void _startCountdown(int secs) {
    _timer?.cancel();
    _seconds = secs;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds > 1) {
        setState(() => _seconds--);
      } else {
        t.cancel();
        _goHome();
      }
    });
  }

  void _goHome() {
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _showEmailDialog() async {
    _timer?.cancel();
    final email = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const EmailDialog(),
    );
    if (!mounted) return;
    if (email != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).t('emailSent'))),
      );
      _startCountdown(10);
    } else {
      _startCountdown(_seconds);
    }
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
            Text(
              '✅ ${l.t('paymentSuccess')}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Container(
                  color: Colors.white,
                  child: QrImageView(
                    data: widget.qrData,
                    version: QrVersions.auto,
                    size: 250,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.t('scanToSave'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _showEmailDialog,
                    child: Text(l.t('sendByEmail')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _goHome,
              child: Text(l.t('closeAndReturn')),
            ),
          ],
        ),
      ),
    );
  }
}

class EmailDialog extends StatefulWidget {
  const EmailDialog({super.key});

  @override
  State<EmailDialog> createState() => _EmailDialogState();
}

class _EmailDialogState extends State<EmailDialog> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.t('enterEmail')),
      content: Form(
        key: _formKey,
        child: TextFormField(
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          onChanged: (v) => _email = v,
          validator: (v) {
            final value = v?.trim() ?? '';
            if (value.isEmpty) return l.t('invalidEmail');
            final reg = RegExp(r'^[^@]+@[^@]+\.[^@]+');
            if (!reg.hasMatch(value)) return l.t('invalidEmail');
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.t('no')),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, _email.trim());
            }
          },
          child: Text(l.t('yes')),
        ),
      ],
    );
  }
}

