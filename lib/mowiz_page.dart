import 'package:flutter/material.dart';
import 'language_selector.dart';
import 'theme_mode_button.dart';
import 'l10n/app_localizations.dart';
import 'mowiz_pay_page.dart';
import 'mowiz_cancel_page.dart';
import 'mowiz/mowiz_scaffold.dart';
// Estilo de botones grandes reutilizable
import 'styles/mowiz_buttons.dart';
import 'package:auto_size_text/auto_size_text.dart';

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
      body: LayoutBuilder(
        // LayoutBuilder nos da el ancho disponible para calcular
        // paddings y tamaños de forma proporcional.
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          // Breakpoints personalizables
          final isLargeTablet = width >= 900;
          final isTablet = width >= 600 && width < 900;
          // Padding y separación basados en el ancho de pantalla
          final padding = EdgeInsets.all(width * 0.05);
          final double gap = width * 0.04;
          // Tamaño de fuente adaptativo para los botones principales
          final double fontSize = isLargeTablet
              ? 32
              : isTablet
                  ? 28
                  : 24;

          final payBtn = Expanded(
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MowizPayPage(),
                  ),
                );
              },
              style: kMowizFilledButtonStyle.copyWith(
                textStyle: MaterialStatePropertyAll(
                  TextStyle(fontSize: fontSize),
                ),
              ),
              child: AutoSizeText(
                t('payTicket'),
                maxLines: 1,
              ),
            ),
          );

          final cancelBtn = Expanded(
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MowizCancelPage(),
                  ),
                );
              },
              style: kMowizFilledButtonStyle.copyWith(
                backgroundColor:
                    const MaterialStatePropertyAll(Color(0xFFA7A7A7)),
                textStyle: MaterialStatePropertyAll(
                  TextStyle(fontSize: fontSize),
                ),
              ),
              child: AutoSizeText(
                t('cancelDenuncia'),
                maxLines: 1,
              ),
            ),
          );

          final rowChildren = <Widget>[payBtn, SizedBox(width: gap), cancelBtn];
          final columnChildren =
              <Widget>[payBtn, SizedBox(height: gap), cancelBtn];

          return Padding(
            padding: padding,
            child: isTablet || isLargeTablet
                ? Row(children: rowChildren)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: columnChildren,
                  ),
          );
        },
      ),
    );
  }
}
