import 'dart:math';
import 'package:flutter/material.dart';
import 'language_selector.dart';
import 'theme_mode_button.dart';
import 'l10n/app_localizations.dart';
import 'mowiz_pay_page.dart';
import 'mowiz_cancel_page.dart';
import 'home_page.dart';
import 'mowiz/mowiz_scaffold.dart';
// Estilo de botones grandes reutilizable
import 'styles/mowiz_buttons.dart';
import 'sound_helper.dart';

class MowizPage extends StatelessWidget {
  const MowizPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    return MowizScaffold(
      title: 'MeyPark',
      actions: const [
        LanguageSelector(),
        SizedBox(width: 8),
        ThemeModeButton(),
      ],
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
        // LayoutBuilder nos da el ancho disponible para calcular
        // paddings y tamaños de forma proporcional.
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final screenWidth = MediaQuery.of(context).size.width;
          final double buttonWidth = min(screenWidth * 0.9, 400);

          // Punto de quiebre para pantallas anchas. Modifica este valor si
          // necesitas cambiar la responsividad de la página.
          const double breakpoint = 700;
          final bool isWide = width >= breakpoint;

          final padding = EdgeInsets.symmetric(horizontal: width * 0.05);
          final double gap = width * 0.05;

          final double fontSize = max(16, width * 0.045);
          final double buttonHeight = max(48, width * 0.15);
          final double buttonPadding = width * 0.03;

          // Estilo base para ambos botones. Las esquinas redondeadas y el
          // padding se mantienen, pero la altura mínima se ajusta según la
          // orientación para que en vertical se vean proporcionados.
          final ButtonStyle baseStyle = kMowizFilledButtonStyle.copyWith(
            minimumSize:
                MaterialStatePropertyAll(Size.fromHeight(buttonHeight)),
            padding: MaterialStatePropertyAll(
              EdgeInsets.symmetric(vertical: buttonPadding),
            ),
            shape: const MaterialStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(30)),
              ),
            ),
            textStyle:
                MaterialStatePropertyAll(TextStyle(fontSize: fontSize)),
          );

          final buttonConstraints = BoxConstraints(
            maxWidth: buttonWidth,
            minWidth: min(isWide ? screenWidth * 0.4 : screenWidth * 0.9, buttonWidth),
            minHeight: 48,
          );

          final payBtn = ConstrainedBox(
            constraints: buttonConstraints,
            child: FilledButton(
              onPressed: () {
                SoundHelper.playTap();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MowizPayPage(),
                  ),
                );
              },
              style: baseStyle,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(t('payTicket')),
              ),
            ),
          );

          final cancelBtn = ConstrainedBox(
            constraints: buttonConstraints,
            child: FilledButton(
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
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(t('cancelDenuncia')),
              ),
            ),
          );

          // En horizontal los botones se expanden para ocupar el ancho
          // disponible. En vertical se muestran con su tamaño natural.
          final rowChildren = <Widget>[
            Expanded(child: payBtn),
            SizedBox(width: gap),
            Expanded(child: cancelBtn),
          ];
          final columnChildren = <Widget>[payBtn, SizedBox(height: gap), cancelBtn];

          return Center(
            child: FractionallySizedBox(
              widthFactor: isWide ? 1 : 0.9,
              child: Padding(
                padding: padding,
                child: isWide
                    ? Row(children: rowChildren)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: columnChildren,
                      ),
              ),
            ),
          );
        },
        ),
      ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextButton(
              onPressed: () {
                SoundHelper.playTap();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomePage()),
                  (route) => false,
                );
              },
              style:
                  TextButton.styleFrom(minimumSize: const Size.fromHeight(40)),
              child: Text(t('home')),
            ),
          ),
        ],
      ),
    );
  }
}
