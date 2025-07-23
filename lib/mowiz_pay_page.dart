import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';

class MowizPayPage extends StatefulWidget {
  const MowizPayPage({super.key});

  @override
  State<MowizPayPage> createState() => _MowizPayPageState();
}

class _MowizPayPageState extends State<MowizPayPage> {
  String? _selectedZone; // 'blue' or 'green'
  final _plateCtrl = TextEditingController();

  bool get _confirmEnabled =>
      _selectedZone != null && _plateCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _plateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(t('payTicket'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t('selectZone'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _selectedZone = 'blue'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      backgroundColor: _selectedZone == 'blue'
                          ? colorScheme.primary
                          : colorScheme.secondary,
                    ),
                    child: Text(t('zoneBlue')),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _selectedZone = 'green'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      backgroundColor: _selectedZone == 'green'
                          ? colorScheme.primary
                          : colorScheme.secondary,
                    ),
                    child: Text(t('zoneGreen')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _plateCtrl,
              enabled: _selectedZone != null,
              decoration: InputDecoration(
                labelText: t('plate'),
                hintText: t('enterPlate'),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _confirmEnabled ? () {} : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 24),
              ),
              child: Text(t('confirm')),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 24),
              ),
              child: Text(t('cancel')),
            ),
          ],
        ),
      ),
    );
  }
}
