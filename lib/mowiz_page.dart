import 'package:flutter/material.dart';
import 'modern_language_selector.dart';
import 'theme_mode_button.dart';
import 'l10n/app_localizations.dart';
import 'company_selection_page.dart';
import 'mowiz_cancel_page.dart';
import 'home_page.dart';
import 'mowiz/mowiz_scaffold.dart';
import 'styles/mowiz_buttons.dart';
import 'styles/mowiz_design_system.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'sound_helper.dart';

class MowizPage extends StatelessWidget {
  const MowizPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    return MowizScaffold(
      title: 'MeyPark',
      actions: const [
        ModernLanguageSelector(),
        SizedBox(width: 8),
        ThemeModeButton(),
      ],
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            // 🎨 Usar sistema de diseño homogéneo
            final contentWidth = MowizDesignSystem.getContentWidth(width);
            final horizontalPadding = MowizDesignSystem.getHorizontalPadding(contentWidth);
            final spacing = MowizDesignSystem.getSpacing(width);
            final titleFontSize = MowizDesignSystem.getTitleFontSize(width);
            final buttonHeight = MowizDesignSystem.getPrimaryButtonHeight(width);

            final ButtonStyle baseStyle = MowizDesignSystem.getPrimaryButtonStyle(
              width: width,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            );

            final payBtn = FilledButton(
              onPressed: () {
                SoundHelper.playTap();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CompanySelectionPage(),
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
              style: MowizDesignSystem.getPrimaryButtonStyle(
                width: width,
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
              ),
              child: AutoSizeText(
                t('cancelDenuncia'),
                maxLines: 1,
                minFontSize: 14,
              ),
            );

            // 🟣 Botón home (inferior)
            final homeBtn = Padding(
              padding: EdgeInsets.only(top: spacing, bottom: MowizDesignSystem.spacingM),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: contentWidth * 0.8,
                  ),
                  child: SizedBox(
                    width: contentWidth * 0.6,
                    height: MowizDesignSystem.getSecondaryButtonHeight(width),
                    child: TextButton(
                      onPressed: () {
                        SoundHelper.playTap();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomePage()),
                          (route) => false,
                        );
                      },
                      style: TextButton.styleFrom(
                        minimumSize: Size.fromHeight(MowizDesignSystem.getSecondaryButtonHeight(width)),
                        textStyle: TextStyle(
                          fontSize: MowizDesignSystem.getBodyFontSize(width),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(t('home')),
                    ),
                  ),
                ),
              ),
            );

            // 🎨 Usar layout responsive del sistema de diseño
            Widget mainButtons;
            if (MowizDesignSystem.isKiosk(width)) {
              // Layout específico para aparcímetro (botones centrados y grandes)
              mainButtons = MowizDesignSystem.getKioskLayout(
                buttons: [payBtn, cancelBtn],
                spacing: spacing,
              );
            } else {
              // Layout responsive normal
              mainButtons = MowizDesignSystem.getButtonLayout(
                width: width,
                buttons: [payBtn, cancelBtn],
                spacing: spacing,
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MowizDesignSystem.getContentWidth(width),
                  minWidth: MowizDesignSystem.minContentWidth,
                  minHeight: height,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(child: mainButtons),
                      homeBtn,
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
