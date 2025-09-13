import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'l10n/app_localizations.dart';
import 'mowiz/mowiz_scaffold.dart';
import 'mowiz_pay_page.dart';
import 'sound_helper.dart';

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

            // 🔵 Ancho máximo profesional
            const double maxContentWidth = 600;
            final double contentWidth = width > maxContentWidth ? maxContentWidth : width;
            final EdgeInsets padding = EdgeInsets.symmetric(horizontal: contentWidth * 0.05);

            final bool isWide = contentWidth >= 700;
            final double gap = isWide ? 28 : 16;
            final double titleFont = isWide ? 26 : 20;
            final double subtitleFont = isWide ? 15 : 13;
            final double buttonHeight = isWide ? 65 : 50;

            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxContentWidth,
                    minWidth: 300,
                    minHeight: height,
                  ),
                  child: Padding(
                    padding: padding,
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
                              fontSize: titleFont,
                              color: colorScheme.primary,
                            ),
                          ),
                          SizedBox(height: gap * 0.5),
                          
                          // 🎯 Subtítulo explicativo
                          AutoSizeText(
                            t('chooseCompanyDescription'),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: subtitleFont,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          SizedBox(height: gap * 1.5),

                          // 🎯 Botón EYPSA
                          _buildCompanyButton(
                            company: 'EYPSA',
                            title: 'EYPSA',
                            subtitle: t('eypsaDescription'),
                            color: const Color(0xFF1976D2), // Azul profesional
                            icon: Icons.business,
                            onTap: () => _selectCompany('EYPSA'),
                            buttonHeight: buttonHeight,
                          ),
                          
                          SizedBox(height: gap),

                          // 🎯 Botón MOWIZ
                          _buildCompanyButton(
                            company: 'MOWIZ',
                            title: 'MOWIZ',
                            subtitle: t('mowizDescription'),
                            color: const Color(0xFF388E3C), // Verde profesional
                            icon: Icons.local_parking,
                            onTap: () => _selectCompany('MOWIZ'),
                            buttonHeight: buttonHeight,
                          ),

                          SizedBox(height: gap * 1.5),

                          // 🎯 Botón de regreso
                          FilledButton(
                            onPressed: () {
                              SoundHelper.playTap();
                              Navigator.of(context).pop();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.surface,
                              foregroundColor: colorScheme.onSurface,
                              side: BorderSide(
                                color: colorScheme.outline,
                                width: 1,
                              ),
                              minimumSize: Size(double.infinity, buttonHeight * 0.8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: AutoSizeText(
                              t('back'),
                              maxLines: 1,
                              minFontSize: 14,
                              style: TextStyle(fontSize: subtitleFont),
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
  }) {
    return Material(
      elevation: 8,
      shadowColor: color.withOpacity(0.3),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: buttonHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              children: [
                // 🎯 Icono de la empresa
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // 🎯 Información de la empresa
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        title,
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Flexible(
                        child: AutoSizeText(
                          subtitle,
                          maxLines: 2,
                          minFontSize: 10,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 🎯 Flecha de navegación
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
