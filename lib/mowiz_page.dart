import 'package:flutter/material.dart';
import 'language_selector.dart';
import 'theme_mode_button.dart';
import 'l10n/app_localizations.dart';
import 'mowiz_pay_page.dart';
import 'mowiz_cancel_page.dart';
import 'mowiz/mowiz_scaffold.dart';
// Estilo de botones grandes reutilizable
import 'styles/mowiz_buttons.dart';

class MowizPage extends StatelessWidget {
  const MowizPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    return MowizScaffold(
      title: t('mowizTitle'),
      actions: const [
        LanguageSelector(),
        SizedBox(width: 8),
        ThemeModeButton(),
      ],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MowizPayPage(),
                  ),
                );
              },
              // Uso de estilo común para botones grandes
              style: kMowizFilledButtonStyle,
              child: Text(t('payTicket')),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MowizCancelPage(),
                  ),
                );
              },
              // Uso de estilo común para botones grandes
              style: kMowizFilledButtonStyle.copyWith(
                backgroundColor: const MaterialStatePropertyAll(Color(0xFFA7A7A7)),
              ),
              child: Text(t('cancelDenuncia')),
            ),
          ],
        ),
      ),
    );
  }
}
