import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'l10n/app_localizations.dart';
import 'mowiz_time_page.dart';
import 'mowiz/mowiz_scaffold.dart';
import 'mowiz_page.dart';
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            // 🔵 Ancho máximo profesional para evitar botones gigantes
            const double maxContentWidth = 500;
            final double contentWidth = width > maxContentWidth ? maxContentWidth : width;
            final EdgeInsets padding = EdgeInsets.symmetric(horizontal: contentWidth * 0.05);

            final bool isWide = contentWidth >= 700;
            final double gap = isWide ? 32 : 20;
            final double titleFont = isWide ? 28 : 22;
            final double inputFont = isWide ? 22 : 17;
            final double buttonHeight = isWide ? 60 : 48;

            final zoneButton = (String value, String text, Color color) =>
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      SoundHelper.playTap();
                      setState(() => _selectedZone = value);
                    },
                    style: kMowizFilledButtonStyle.copyWith(
                      minimumSize: MaterialStatePropertyAll(Size(double.infinity, buttonHeight)),
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
                      minFontSize: 13,
                    ),
                  ),
                );

            // 🟣 Distribución vertical y centralizada sin scroll
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxContentWidth,
                  minWidth: 260,
                  minHeight: height,
                ),
                child: Padding(
                  padding: padding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                          minimumSize: MaterialStatePropertyAll(Size(double.infinity, buttonHeight)),
                          textStyle: MaterialStatePropertyAll(
                            TextStyle(fontSize: titleFont),
                          ),
                        ),
                        child: AutoSizeText(
                          t('confirm'),
                          maxLines: 1,
                          minFontSize: 13,
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
                          minimumSize: MaterialStatePropertyAll(Size(double.infinity, buttonHeight)),
                          textStyle: MaterialStatePropertyAll(
                            TextStyle(fontSize: titleFont),
                          ),
                        ),
                        child: AutoSizeText(
                          t('back'),
                          maxLines: 1,
                          minFontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
