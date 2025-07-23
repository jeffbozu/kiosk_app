import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'l10n/app_localizations.dart';
import 'mowiz_page.dart';

class MowizSuccessPage extends StatefulWidget {
  final String plate;
  final String zone;
  final DateTime start;
  final int minutes;
  final double price;
  final String method;

  const MowizSuccessPage({
    super.key,
    required this.plate,
    required this.zone,
    required this.start,
    required this.minutes,
    required this.price,
    required this.method,
  });

  @override
  State<MowizSuccessPage> createState() => _MowizSuccessPageState();
}

class _MowizSuccessPageState extends State<MowizSuccessPage> {
  int _seconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds > 1) {
        setState(() => _seconds--);
      } else {
        t.cancel();
        _goHome();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MowizPage()),
      (route) => false,
    );
  }

  Future<void> _showEmailDialog() async {
    _pauseTimer();
    final email = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _EmailDialog(),
    );
    if (!mounted) return;
    if (email != null) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _EmailSentDialog(onClose: _goHome),
      );
    }
    if (mounted) _startTimer();
  }

  Future<void> _showSmsDialog() async {
    _pauseTimer();
    final phone = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SmsDialog(),
    );
    if (!mounted) return;
    if (phone != null) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SmsSentDialog(onClose: _goHome),
      );
    }
    if (mounted) _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

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

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Lottie.asset(
              'assets/success.json',
              height: 150,
              repeat: false,
            ),
            const SizedBox(height: 16),
            Text(
              t('paymentSuccess'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Builder(
                  builder: (context) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Container(
                      color: isDark ? Colors.white : Colors.transparent,
                      child: QrImageView(
                        data: 'SIMULATED', // TODO: replace with real data
                        version: QrVersions.auto,
                        size: 250,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                      t('ticketSummary'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${t('plate')}: ${widget.plate}',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${t('zone')}: ${widget.zone}',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${t('startTime')}: ${timeFormat.format(widget.start)}',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${t('endTime')}: ${timeFormat.format(finish)}',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${t('totalPrice')}: ${widget.price.toStringAsFixed(2)} €',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${t('paymentMethod')}: ${widget.method}',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {}, // TODO: implement print functionality
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(80),
              ),
              child: Text(t('printTicket')),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showEmailDialog,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(80),
              ),
              child: Text(t('sendByEmail')),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showSmsDialog,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(80),
              ),
              child: Text(t('sendBySms')),
            ),
            const SizedBox(height: 16),
            Text(
              t('returningIn', params: {'seconds': '$_seconds'}),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _goHome,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(80),
              ),
              child: Text(t('goHome')),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailDialog extends StatefulWidget {
  const _EmailDialog();

  @override
  State<_EmailDialog> createState() => _EmailDialogState();
}

class _EmailDialogState extends State<_EmailDialog> {
  String _email = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.t('enterEmail')),
      content: TextField(
        autofocus: true,
        keyboardType: TextInputType.emailAddress,
        onChanged: (v) => _email = v,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.t('close')),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _email.trim()),
          child: Text(l.t('send')),
        ),
      ],
    );
  }
}

class _SmsDialog extends StatefulWidget {
  const _SmsDialog();

  @override
  State<_SmsDialog> createState() => _SmsDialogState();
}

class _SmsDialogState extends State<_SmsDialog> {
  String _phone = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.t('enterPhone')),
      content: TextField(
        autofocus: true,
        keyboardType: TextInputType.phone,
        onChanged: (v) => _phone = v,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.t('close')),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _phone.trim()),
          child: Text(l.t('send')),
        ),
      ],
    );
  }
}

class _EmailSentDialog extends StatefulWidget {
  final VoidCallback onClose;
  const _EmailSentDialog({required this.onClose});

  @override
  State<_EmailSentDialog> createState() => _EmailSentDialogState();
}

class _EmailSentDialogState extends State<_EmailSentDialog> {
  int _seconds = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds > 1) {
        setState(() => _seconds--);
      } else {
        t.cancel();
        widget.onClose();
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
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.t('emailSent')),
          const SizedBox(height: 8),
          Text(l.t('returningIn', params: {'seconds': '$_seconds'})),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: widget.onClose,
          child: Text(l.t('close')),
        ),
      ],
    );
  }
}

class _SmsSentDialog extends StatefulWidget {
  final VoidCallback onClose;
  const _SmsSentDialog({required this.onClose});

  @override
  State<_SmsSentDialog> createState() => _SmsSentDialogState();
}

class _SmsSentDialogState extends State<_SmsSentDialog> {
  int _seconds = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds > 1) {
        setState(() => _seconds--);
      } else {
        t.cancel();
        widget.onClose();
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
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.t('smsSent')),
          const SizedBox(height: 8),
          Text(l.t('returningIn', params: {'seconds': '$_seconds'})),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: widget.onClose,
          child: Text(l.t('close')),
        ),
      ],
    );
  }
}
