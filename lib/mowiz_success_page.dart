import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:confetti/confetti.dart';

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
  static const double _buttonHeight = 44;
  static const TextStyle _buttonTextStyle = TextStyle(fontSize: 16);
  final _confetti = ConfettiController(duration: const Duration(seconds: 3));
  bool _showTick = false;
  int _seconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _confetti.play();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _showTick = true);
    });
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
    _confetti.dispose();
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 600 ? 48.0 : 16.0;
          return Padding(
            padding: EdgeInsets.all(horizontal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ConfettiWidget(
                      confettiController: _confetti,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                    ),
                    AnimatedScale(
                      scale: _showTick ? 1 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Lottie.asset(
                        'assets/success.json',
                        height: 120,
                        repeat: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  t('paymentSuccess'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: Center(
                    child: QrImageView(
                      // TODO: replace static data with real ticket JSON from backend
                      data:
                          'ticket|plate:${widget.plate}|zone:${widget.zone}|start:${widget.start.toIso8601String()}|end:${finish.toIso8601String()}|price:${widget.price}',
                      version: QrVersions.auto,
                      size: 180,
                      foregroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Card(
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
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size.fromHeight(_buttonHeight),
                              textStyle: _buttonTextStyle,
                            ),
                            child: Text(t('printTicket')),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _showEmailDialog,
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size.fromHeight(_buttonHeight),
                              textStyle: _buttonTextStyle,
                            ),
                            child: Text(t('sendByEmail')),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: _showSmsDialog,
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size.fromHeight(_buttonHeight),
                              textStyle: _buttonTextStyle,
                            ),
                            child: Text(t('sendBySms')),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _goHome,
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size.fromHeight(_buttonHeight),
                              textStyle: _buttonTextStyle,
                            ),
                            child: Text(t('goHome')),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween(
                      begin: _seconds.toDouble() + 1, end: _seconds.toDouble()),
                  duration: const Duration(milliseconds: 250),
                  builder: (context, value, child) => Text(
                    t('returningIn',
                        params: {'seconds': value.toInt().toString()}),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
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
class _EmailSentDialog extends StatelessWidget {
  final VoidCallback onClose;
  const _EmailSentDialog({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      content: TweenAnimationBuilder<double>(
        tween: Tween(begin: 10, end: 0),
        duration: const Duration(seconds: 10),
        onEnd: onClose,
        builder: (context, value, child) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.t('emailSent')),
            const SizedBox(height: 8),
            Text(l.t('returningIn',
                params: {'seconds': value.toInt().toString()})),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onClose();
          },
          child: Text(l.t('close')),
        ),
      ],
    );
  }
}

// SMS sent confirmation dialog
class _SmsSentDialog extends StatelessWidget {
  final VoidCallback onClose;
  const _SmsSentDialog({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      content: TweenAnimationBuilder<double>(
        tween: Tween(begin: 10, end: 0),
        duration: const Duration(seconds: 10),
        onEnd: onClose,
        builder: (context, value, child) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.t('smsSent')),
            const SizedBox(height: 8),
            Text(l.t('returningIn',
                params: {'seconds': value.toInt().toString()})),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onClose();
          },
          child: Text(l.t('close')),
        ),
      ],
    );
  }
}
