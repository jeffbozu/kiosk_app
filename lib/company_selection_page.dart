import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'l10n/app_localizations.dart';
import 'mowiz/mowiz_scaffold.dart';
import 'mowiz_pay_page.dart';
import 'sound_helper.dart';
import 'styles/mowiz_design_system.dart';

class CompanySelectionPage extends StatefulWidget {
  const CompanySelectionPage({super.key});

  @override
  State<CompanySelectionPage> createState() => _CompanySelectionPageState();
}

class _CompanySelectionPageState extends State<CompanySelectionPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectCompany(String company) {
    SoundHelper.playTap();
    _animationController.reverse().then((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MowizPayPage(selectedCompany: company),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final colorScheme = Theme.of(context).colorScheme;

    return MowizScaffold(
      title: 'MeyPark - ${t('selectCompany')}',
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
            final bodyFontSize = MowizDesignSystem.getBodyFontSize(width);
            final buttonHeight = MowizDesignSystem.getPrimaryButtonHeight(width);

            return MowizDesignSystem.getScrollableContent(
              availableHeight: height,
              contentHeight: 600, // Altura estimada del contenido
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: contentWidth,
                    minWidth: MowizDesignSystem.minContentWidth,
                    minHeight: height,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                          // 🎯 Título principal
                          AutoSizeText(
                            t('selectCompany'),
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: titleFontSize,
                              color: colorScheme.primary,
                            ),
                          ),
                          SizedBox(height: spacing * 0.5),
                          
                          // 🎯 Subtítulo explicativo
                          AutoSizeText(
                            t('chooseCompanyDescription'),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: bodyFontSize * 0.9,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          SizedBox(height: spacing * 1.5),

                          // 🎯 Botón EYPSA
                          _buildCompanyButton(
                            company: 'EYPSA',
                            title: 'EYPSA',
                            subtitle: t('eypsaDescription'),
                            color: const Color(0xFF1976D2), // Azul profesional
                            icon: Icons.business,
                            onTap: () => _selectCompany('EYPSA'),
                            buttonHeight: buttonHeight,
                            width: width,
                          ),
                          
                          SizedBox(height: spacing),

                          // 🎯 Botón MOWIZ
                          _buildCompanyButton(
                            company: 'MOWIZ',
                            title: 'MOWIZ',
                            subtitle: t('mowizDescription'),
                            color: const Color(0xFF388E3C), // Verde profesional
                            icon: Icons.local_parking,
                            onTap: () => _selectCompany('MOWIZ'),
                            buttonHeight: buttonHeight,
                            width: width,
                          ),

                          SizedBox(height: spacing * 1.5),

                          // 🎯 Botón de regreso
                          FilledButton(
                            onPressed: () {
                              SoundHelper.playTap();
                              Navigator.of(context).pop();
                            },
                            style: MowizDesignSystem.getSecondaryButtonStyle(
                              width: width,
                              backgroundColor: colorScheme.surface,
                              foregroundColor: colorScheme.onSurface,
                            ).copyWith(
                              side: MaterialStatePropertyAll(
                                BorderSide(
                                  color: colorScheme.outline,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: AutoSizeText(
                              t('back'),
                              maxLines: 1,
                              minFontSize: 14,
                              style: TextStyle(fontSize: bodyFontSize * 0.9),
                            ),
                          ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompanyButton({
    required String company,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    required double buttonHeight,
    required double width,
  }) {
    return FilledButton(
      onPressed: onTap,
      style: MowizDesignSystem.getPrimaryButtonStyle(
        width: width,
        backgroundColor: color,
        foregroundColor: Colors.white,
      ).copyWith(
        padding: MaterialStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: MowizDesignSystem.getPadding(width),
            vertical: MowizDesignSystem.paddingL,
          ),
        ),
        elevation: MaterialStatePropertyAll(4),
      ),
      child: Row(
        children: [
          // 🎯 Icono de la empresa
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // 🎯 Información de la empresa
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  title,
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MowizDesignSystem.getBodyFontSize(width) * 1.1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                AutoSizeText(
                  subtitle,
                  maxLines: 2,
                  minFontSize: 12,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: MowizDesignSystem.getBodyFontSize(width) * 0.8,
                  ),
                ),
              ],
            ),
          ),
          
          // 🎯 Flecha de navegación
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.white.withOpacity(0.8),
            size: 18,
          ),
        ],
      ),
    );
  }
}
