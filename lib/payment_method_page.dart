import 'dart:async';
import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'language_selector.dart';
import 'theme_mode_button.dart';

class PaymentMethodPage extends StatefulWidget {
  final String zoneId;
  final String plate;
  final int duration;
  final double price;
  const PaymentMethodPage({
    super.key,
    required this.zoneId,
    required this.plate,
    required this.duration,
    required this.price,
  });

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  String? _selectedMethod;
  bool _processing = false;
  String? _message;

  Future<void> _startPayment() async {
    final l = AppLocalizations.of(context);
    if (_selectedMethod == null) {
      setState(() => _message = l.t('selectMethodError'));
      return;
    }
    setState(() {
      _processing = true;
      _message = l.t('processingPayment');
    });
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _processing = false;
      _message = null;
    });

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PaymentSuccessDialog(onClose: () {
        Navigator.of(ctx).pop();
      }),
    );

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('selectMethod')),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
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
            ElevatedButton.icon(
              onPressed: () => setState(() => _selectedMethod = 'card'),
              icon: const Icon(Icons.credit_card, size: 40),
              label: Text(l.t('cardPayment')),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedMethod == 'card'
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() => _selectedMethod = 'qr'),
              icon: const Icon(Icons.qr_code_2, size: 40),
              label: Text(l.t('qrPayment')),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedMethod == 'qr'
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 32),
            if (_message != null) ...[
              Text(
                _message!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
            ],
            if (_processing)
              const Center(child: CircularProgressIndicator()),
            const Spacer(),
            ElevatedButton(
              onPressed: _processing ? null : _startPayment,
              child: Text(l.t('pay')),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentSuccessDialog extends StatefulWidget {
  final VoidCallback onClose;
  const PaymentSuccessDialog({super.key, required this.onClose});

  @override
  State<PaymentSuccessDialog> createState() => _PaymentSuccessDialogState();
}

class _PaymentSuccessDialogState extends State<PaymentSuccessDialog> {
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
          Text(l.t('paymentSuccess')),
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
