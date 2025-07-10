import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'l10n/app_localizations.dart';
import 'language_selector.dart';
import 'theme_mode_button.dart';

class TicketSuccessPage extends StatefulWidget {
  final String ticketId;
  const TicketSuccessPage({super.key, required this.ticketId});

  @override
  State<TicketSuccessPage> createState() => _TicketSuccessPageState();
}

class _TicketSuccessPageState extends State<TicketSuccessPage> {
  int _seconds = 20;
  Timer? _timer;
  String? _qrData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _startCountdown(20);
    _loadData();
  }

  Future<void> _loadData() async {
    // No modificar el código para cambiar los campos del QR.
    // Edita el array qrFields en Firestore (settings/qrConfig).
    try {
      final fs = FirebaseFirestore.instance;
      final ticketDoc =
          await fs.collection('tickets').doc(widget.ticketId).get();
      final ticketData = ticketDoc.data() ?? {};

      final settings = fs.collection('settings');
      var configDoc = await settings.doc('qrConfig').get();
      if (!configDoc.exists) {
        // Intentar alternativa en minúsculas por si el documento está mal nombrado
        configDoc = await settings.doc('qrconfig').get();
      }

      final fields = List<String>.from(configDoc.data()?['qrFields'] ?? []);

      final lines = <String>[];
      // Calculamos la longitud máxima para alinear las columnas
      final maxLabel = fields.fold<int>(0, (p, e) => e.length > p ? e.length : p);
      for (final field in fields) {
        dynamic value;
        if (field == 'ticketId') {
          value = widget.ticketId;
        } else {
          value = ticketData[field];
          if (value is Timestamp) value = value.toDate();
        }
        final label = field[0].toUpperCase() + field.substring(1);
        final display = (value != null && value.toString().isNotEmpty)
            ? value.toString()
            : 'N/A';
        lines.add('${label.padRight(maxLabel)} : $display');
      }
      setState(() {
        _qrData = lines.join('\n');
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading QR data: $e');
      setState(() => _loading = false);
    }
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
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => EmailSentDialog(onClose: _goHome),
      );
    } else {
      _startCountdown(20);
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
              l.t('paymentDone'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: _loading
                    ? const CircularProgressIndicator()
                    : Builder(
                        builder: (context) {
                          final isDark =
                              Theme.of(context).brightness == Brightness.dark;
                          return Container(
                            color: isDark ? Colors.white : Colors.transparent,
                            child: QrImageView(
                              data: _qrData ?? widget.ticketId,
                              version: QrVersions.auto,
                              size: 250,
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.t('saveTicketQr'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              l.t('returningIn', params: {'seconds': '$_seconds'}),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _goHome,
              child: Text(l.t('goHome')),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _showEmailDialog,
              child: Text(l.t('sendByEmail')),
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
          child: Text(l.t('cancel')),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _email.trim()),
          child: Text(l.t('send')),
        ),
      ],
    );
  }
}

class EmailSentDialog extends StatefulWidget {
  final VoidCallback onClose;
  const EmailSentDialog({super.key, required this.onClose});

  @override
  State<EmailSentDialog> createState() => _EmailSentDialogState();
}

class _EmailSentDialogState extends State<EmailSentDialog> {
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
