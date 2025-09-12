import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'locale_provider.dart';

/// Selector de idiomas moderno y elegante
/// Usa PopupMenuButton para evitar problemas de posicionamiento en AppBar
class ModernLanguageSelector extends StatefulWidget {
  const ModernLanguageSelector({super.key});

  @override
  State<ModernLanguageSelector> createState() => _ModernLanguageSelectorState();
}

class _ModernLanguageSelectorState extends State<ModernLanguageSelector> {
  String _currentLanguage = 'ES';

  final List<Map<String, String>> _languages = [
    {'code': 'es', 'label': 'ES', 'name': 'Español'},
    {'code': 'ca', 'label': 'CA', 'name': 'Català'},
    {'code': 'en', 'label': 'EN', 'name': 'English'},
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Detectar el idioma actual del provider
    final prov = Provider.of<LocaleProvider>(context, listen: false);
    final currentCode = prov.locale.languageCode;
    final currentLang = _languages.firstWhere(
      (lang) => lang['code'] == currentCode,
      orElse: () => _languages.first,
    );
    if (_currentLanguage != currentLang['label']) {
      setState(() {
        _currentLanguage = currentLang['label']!;
      });
    }
  }

  void _selectLanguage(String code, String label) {
    setState(() {
      _currentLanguage = label;
    });
    
    // Cambiar idioma
    final prov = Provider.of<LocaleProvider>(context, listen: false);
    prov.setLocale(Locale(code));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Colores adaptados para modo claro y oscuro
    final primaryColor = isDark ? const Color(0xFF424242) : const Color(0xFFE62144);
    final textColor = Colors.white;
    final borderColor = isDark ? const Color(0xFF616161) : const Color(0xFFD01E3A);
    
    // Colores para el menú desplegable
    final menuBackgroundColor = isDark ? const Color(0xFF303030) : Colors.white;
    final selectedColor = isDark ? const Color(0xFF424242) : const Color(0xFFD01E3A);
    final unselectedColor = isDark ? const Color(0xFF424242) : const Color(0xFFF8F9FA);
    final selectedTextColor = Colors.white;
    final unselectedTextColor = isDark ? Colors.white : const Color(0xFFE62144);

    return PopupMenuButton<String>(
      onSelected: (String code) {
        final lang = _languages.firstWhere((l) => l['code'] == code);
        _selectLanguage(code, lang['label']!);
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: menuBackgroundColor,
      elevation: 8,
      itemBuilder: (BuildContext context) {
        return _languages.map((lang) {
          final isSelected = _currentLanguage == lang['label'];
          return PopupMenuItem<String>(
            value: lang['code']!,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? selectedColor : unselectedColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                      ? selectedColor 
                      : (isDark ? const Color(0xFF616161) : const Color(0xFFE0E0E0)),
                  width: 1.5,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: selectedColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : selectedColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    lang['label']!,
                    style: TextStyle(
                      color: isSelected ? selectedTextColor : unselectedTextColor,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    lang['name']!,
                    style: TextStyle(
                      color: isSelected 
                          ? selectedTextColor.withOpacity(0.9)
                          : unselectedTextColor.withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withOpacity(0.3)
                  : primaryColor.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _currentLanguage,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: textColor,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}