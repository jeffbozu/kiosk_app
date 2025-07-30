import 'package:flutter/material.dart';
import 'language_selector.dart';
import 'theme_mode_button.dart';
import 'l10n/app_localizations.dart';
import 'mowiz_pay_page.dart';
import 'mowiz_cancel_page.dart';
import 'mowiz/mowiz_scaffold.dart';
import 'styles/mowiz_buttons.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'sound_helper.dart';

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
      body: SafeArea( // 🟩 SafeArea para evitar solapamiento con notch/barras
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            // 🟧 Máximo ancho para layout desktop/tablet
            const double maxContentWidth = 600;
            // 🟦 Calcula el ancho real a usar (nunca más de maxContentWidth)
            final double contentWidth = width > maxContentWidth ? maxContentWidth : width;

            // Paddings y separación proporcionales al tamaño
            final padding = EdgeInsets.symmetric(horizontal: contentWidth * 0.05);
            final double gap = contentWidth > 500 ? 32 : 24;
            final double fontSize = contentWidth > 500 ? 28 : 20;
            final double buttonHeight = contentWidth > 500 ? 100 : 60;

            // 🟨 Estilo base de los botones
            final ButtonStyle baseStyle = kMowizFilledButtonStyle.copyWith(
              minimumSize: MaterialStatePropertyAll(Size(double.infinity, buttonHeight)),
              padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 0)),
              shape: const MaterialStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                ),
              ),
              textStyle: MaterialStatePropertyAll(
                TextStyle(fontSize: fontSize),
              ),
            );

            final payBtn = FilledButton(
              onPressed: () {
                SoundHelper.playTap();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MowizPayPage(),
                  ),
                );
              },
              style: baseStyle,
              child: AutoSizeText(
                t('payTicket'),
                maxLines: 1,
                minFontSize: 14,
              ),
            );

            final cancelBtn = FilledButton(
              onPressed: () {
                SoundHelper.playTap();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MowizCancelPage(),
                  ),
                );
              },
              style: baseStyle.copyWith(
                backgroundColor: MaterialStatePropertyAll(
                  Theme.of(context).colorScheme.secondary,
                ),
                foregroundColor: MaterialStatePropertyAll(
                  Theme.of(context).colorScheme.onSecondary,
                ),
              ),
              child: AutoSizeText(
                t('cancelDenuncia'),
                maxLines: 1,
                minFontSize: 14,
              ),
            );

            // 🟪 El layout se adapta: en desktop/tablet (ancho) usa Row, en móvil usa Column
            Widget mainContent = contentWidth > 500
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(child: payBtn),
                      SizedBox(width: gap),
                      Expanded(child: cancelBtn),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      payBtn,
                      SizedBox(height: gap),
                      cancelBtn,
                    ],
                  );

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxContentWidth,
                  minWidth: 250,
                  minHeight: height, // Siempre ocupa el alto disponible
                ),
                child: Padding(
                  padding: padding,
                  child: mainContent,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
