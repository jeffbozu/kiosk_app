import 'dart:async';
import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'mowiz/mowiz_scaffold.dart';
import 'styles/mowiz_buttons.dart';

class MowizCancelPage extends StatefulWidget {
  const MowizCancelPage({super.key});

  @override
  State<MowizCancelPage> createState() => _MowizCancelPageState();
}

class _MowizCancelPageState extends State<MowizCancelPage> {
  final _plateCtrl = TextEditingController();

  @override
  void dispose() {
    _plateCtrl.dispose();
    super.dispose();
  }

  Future<void> _validate() async {
    final t = AppLocalizations.of(context).t;
    final plate = _plateCtrl.text.trim();
    if (plate.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t('plateNotFound'))));
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Text(t('confirmCancellation')),
        actions: [
          // Botón "No" del diálogo de confirmación
          FilledButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: kMowizFilledButtonStyle.copyWith(
              backgroundColor: MaterialStatePropertyAll(
                Theme.of(ctx).colorScheme.secondary,
              ),
            ),
            child: Text(t('no')),
          ),
          // Botón "Sí" del diálogo de confirmación
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: kMowizFilledButtonStyle,
            child: Text(t('yes')),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _SuccessDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    return MowizScaffold(
      title: t('cancelDenuncia'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _plateCtrl,
                decoration: InputDecoration(hintText: t('enterPlate')),
              ),
              const SizedBox(height: 24),
              // Botón principal para validar la matrícula
              FilledButton(
                onPressed: _validate,
                style: kMowizFilledButtonStyle,
                child: Text(t('validate')),
              ),
              const SizedBox(height: 16),
              // Botón de cancelación
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: kMowizFilledButtonStyle.copyWith(
                  backgroundColor: const MaterialStatePropertyAll(
                    Color(0xFFA7A7A7),
                  ),
                ),
                child: Text(t('cancel')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessDialog extends StatefulWidget {
  const _SuccessDialog();

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog> {
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
        Navigator.of(context).pop();
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
    final t = AppLocalizations.of(context).t;
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t('cancellationSuccess'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(t('autoCloseIn', params: {'seconds': '$_seconds'})),
        ],
      ),
      // Diálogo de éxito tras la anulación
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: kMowizFilledButtonStyle,
          child: Text(t('close')),
        ),
      ],
    );
  }
}
