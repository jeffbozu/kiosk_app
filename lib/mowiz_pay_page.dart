import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'l10n/app_localizations.dart';
import 'mowiz_time_page.dart';
import 'mowiz/mowiz_scaffold.dart';
import 'mowiz_page.dart';
// Estilo común para botones grandes
import 'styles/mowiz_buttons.dart';
import 'sound_helper.dart';

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
      title: 'MeyPark - ${t('selectZone')}',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isLargeTablet = width >= 900;
          final isTablet = width >= 600 && width < 900;
          final padding = EdgeInsets.all(width * 0.05);
          final double gap = width * 0.04;
          final double titleFont = isLargeTablet
              ? 32
              : isTablet
                  ? 28
                  : 24;
          final double inputFont = isLargeTablet
              ? 28
              : isTablet
                  ? 24
                  : 20;

          final zoneButton = (String value, String text, Color color) =>
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    SoundHelper.playTap();
                    setState(() => _selectedZone = value);
                  },
                  style: kMowizFilledButtonStyle.copyWith(
                    backgroundColor: MaterialStatePropertyAll(
                      _selectedZone == value ? color : colorScheme.secondary,
                    ),
                    textStyle: MaterialStatePropertyAll(
                      TextStyle(fontSize: inputFont),
                    ),
                  ),
                  child: AutoSizeText(
                    text,
                    maxLines: 1,
                  ),
                ),
              );

          return Padding(
            padding: padding,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AutoSizeText(
                    t('selectZone'),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: titleFont,
                    ),
                  ),
                  SizedBox(height: gap),
                  Row(
                    children: [
                      zoneButton(
                        'blue',
                        t('zoneBlue'),
                        const Color(0xFF007CF7),
                      ),
                      SizedBox(width: gap),
                      zoneButton(
                        'green',
                        t('zoneGreen'),
                        const Color(0xFF01AE00),
                      ),
                    ],
                  ),
                  SizedBox(height: gap),
                  TextField(
                    controller: _plateCtrl,
                    enabled: _selectedZone != null,
                    decoration: InputDecoration(
                      labelText: t('plate'),
                      hintText: t('enterPlate'),
                    ),
                    style: TextStyle(fontSize: inputFont),
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: gap * 1.5),
                  FilledButton(
                    onPressed: _confirmEnabled
                        ? () {
                            SoundHelper.playTap();
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
                    style: kMowizFilledButtonStyle.copyWith(
                      textStyle:
                          MaterialStatePropertyAll(TextStyle(fontSize: titleFont)),
                    ),
                    child: AutoSizeText(
                      t('confirm'),
                      maxLines: 1,
                    ),
                  ),
                  SizedBox(height: gap),
                  FilledButton(
                    onPressed: () {
                      SoundHelper.playTap();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const MowizPage()),
                        (route) => false,
                      );
                    },
                    style: kMowizFilledButtonStyle.copyWith(
                      textStyle:
                          MaterialStatePropertyAll(TextStyle(fontSize: titleFont)),
                    ),
                    child: AutoSizeText(
                      t('back'),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
