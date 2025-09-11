import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

class ModernLanguageSelector extends StatefulWidget {
  const ModernLanguageSelector({Key? key}) : super(key: key);

  @override
  State<ModernLanguageSelector> createState() => _ModernLanguageSelectorState();
}

class _ModernLanguageSelectorState extends State<ModernLanguageSelector>
    with TickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _changeLanguage(String localeCode) {
    setState(() {
      _isOpen = false;
      _animationController.reverse();
    });
    
    // Cambiar idioma
    final context = this.context;
    if (context.mounted) {
      // Aquí implementarías el cambio de idioma
      // Por ahora solo cerramos el dropdown
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    String currentLang = 'ES'; // Por defecto español
    
    return Stack(
      children: [
        // Botón principal
        GestureDetector(
          onTap: _toggleDropdown,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isOpen ? theme.colorScheme.primary : Colors.transparent,
                width: 2,
              ),
              boxShadow: _isOpen ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 3,
                ),
              ] : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentLang,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedRotation(
                  turns: _isOpen ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Dropdown
        if (_isOpen) _buildDropdown(),
      ],
    );
  }

  Widget _buildDropdown() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Positioned(
      top: 60, // Ajusta según la altura de tu AppBar
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  width: 160,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLanguageOption('es', 'ES', 'Español'),
                      _buildDivider(),
                      _buildLanguageOption('ca', 'CA', 'Català'),
                      _buildDivider(),
                      _buildLanguageOption('en', 'EN', 'English'),
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

  Widget _buildLanguageOption(String localeCode, String short, String full) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => _changeLanguage(localeCode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Text(
              short,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                full,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Icon(
              Icons.check,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      height: 1,
      color: Colors.grey.withOpacity(0.4),
    );
  }
}

