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
      body: LayoutBuilder(
        // LayoutBuilder nos da el ancho disponible para calcular
        // paddings y tamaños de forma proporcional.
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          // Punto de quiebre para pantallas anchas. Modifica este valor si
          // necesitas cambiar la responsividad de la página.
          const double breakpoint = 700;
          final bool isWide = width >= breakpoint;

          // Padding y separación basados en el ancho disponible. Utilizamos
          // un porcentaje para que los botones ocupen entre el 80% y 95%
          // del ancho sin pegarse a los bordes.
          final padding = EdgeInsets.symmetric(horizontal: width * 0.05);
          final double gap = isWide ? 32 : 24;

          // Tamaño de fuente adaptativo para los botones principales
          final double fontSize = isWide ? 28 : 24;

          // Alto deseado para los botones. En orientación vertical se reduce
          // para evitar que ocupen toda la pantalla.
          final double buttonHeight = isWide ? 120 : 68;
          final double buttonPadding = isWide ? 24 : 16;

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
    );
  }
}
