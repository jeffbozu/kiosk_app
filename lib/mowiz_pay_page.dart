import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'mowiz_time_page.dart';
import 'mowiz/mowiz_scaffold.dart';
// Estilo común para botones grandes
import 'styles/mowiz_buttons.dart';

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
    return MowizScaffold(
      title: t('payTicket'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t('selectZone'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => setState(() => _selectedZone = 'blue'),
                    style: kMowizFilledButtonStyle.copyWith(
                      backgroundColor: MaterialStatePropertyAll(
                        // Color corporativo para la zona azul
                        _selectedZone == 'blue'
                            ? const Color(0xFF007CF7)
                            : colorScheme.secondary,
                      ),
                    ),
                    child: Text(t('zoneBlue')),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () => setState(() => _selectedZone = 'green'),
                    style: kMowizFilledButtonStyle.copyWith(
                      backgroundColor: MaterialStatePropertyAll(
                        // Color corporativo para la zona verde
                        _selectedZone == 'green'
                            ? const Color(0xFF01AE00)
                            : colorScheme.secondary,
                      ),
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
              style: const TextStyle(fontSize: 24),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _confirmEnabled
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MowizTimePage(
                            zone: _selectedZone!,
                            plate: _plateCtrl.text.trim(),
                          ),
                        ),
                      );
                    }
                  : null,
              // Estilo grande reutilizado
              style: kMowizFilledButtonStyle,
              child: Text(t('confirm')),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              // Estilo grande reutilizado
              style: kMowizFilledButtonStyle,
              child: Text(t('cancel')),
            ),
          ],
        ),
      ),
    );
  }
}
