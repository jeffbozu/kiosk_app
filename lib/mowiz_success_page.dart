import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:confetti/confetti.dart';

import 'l10n/app_localizations.dart';
import 'mowiz_page.dart';
import 'mowiz/mowiz_scaffold.dart';
// Estilo de botones grandes reutilizable para toda la app
import 'styles/mowiz_buttons.dart';

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
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3))..play();
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
      // TODO lógica real de envío de email
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _EmailSentDialog(onClose: _startTimer),
      );
    } else {
      _startTimer();
    }
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
      // TODO lógica real de envío de SMS
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SmsSentDialog(onClose: _startTimer),
      );
    } else {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
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
    final ticketJson =
        'ticket|plate:${widget.plate}|zone:${widget.zone}|start:${widget.start.toIso8601String()}|end:${finish.toIso8601String()}|price:${widget.price}'; // TODO lógica real
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MowizScaffold(
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
            ),
          ),
          // Envolver todo en SingleChildScrollView para evitar overflow
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Lottie.asset(
                    'assets/success.json',
                    height: 120,
                    repeat: false,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t('paymentSuccess'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: QrImageView(
                        data: ticketJson,
                        size: 220,
                        foregroundColor: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
            // Recuadro de resumen sin altura fija para evitar overflow
            Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        t('ticketSummary'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${t('plate')}: ${widget.plate}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        '${t('zone')}: ${widget.zone}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        '${t('startTime')}: ${timeFormat.format(widget.start)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        '${t('endTime')}: ${timeFormat.format(finish)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        '${t('totalPrice')}: ${widget.price.toStringAsFixed(2)} €',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        '${t('paymentMethod')}: ${widget.method}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 32), // Separación mayor entre resumen y botones
            // Acciones distribuidas en dos filas de dos botones
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilledButton(
                            onPressed: () {},
                            style: kMowizFilledButtonStyle,
                            child: Text(t('printTicket')),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: FilledButton(
                            onPressed: _showSmsDialog,
                            style: kMowizFilledButtonStyle,
                            child: Text(t('sendBySms')),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilledButton(
                            onPressed: _showEmailDialog,
                            style: kMowizFilledButtonStyle,
                            child: Text(t('sendByEmail')),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: FilledButton(
                            onPressed: _goHome,
                            style: kMowizFilledButtonStyle,
                            child: Text(t('goHome')),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              t('returningIn', params: {'seconds': '$_seconds'}),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }
}

// Email input dialog
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

// SMS input dialog
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

// Email sent confirmation dialog
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
        if (mounted) {
          Navigator.of(context).pop();
          widget.onClose();
        }
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
          onPressed: () {
            Navigator.of(context).pop();
            widget.onClose();
          },
          child: Text(l.t('close')),
        ),
      ],
    );
  }
}

// SMS sent confirmation dialog
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
        if (mounted) {
          Navigator.of(context).pop();
          widget.onClose();
        }
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
          onPressed: () {
            Navigator.of(context).pop();
            widget.onClose();
          },
          child: Text(l.t('close')),
        ),
      ],
    );
  }
}
