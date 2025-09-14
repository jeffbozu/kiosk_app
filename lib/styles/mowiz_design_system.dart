import 'package:flutter/material.dart';

/// Sistema de diseño homogéneo para todas las páginas MOWIZ
/// Garantiza consistencia visual y responsive design
class MowizDesignSystem {
  // Evitar instanciación
  MowizDesignSystem._();

  // ========================================
  // 📱 BREAKPOINTS RESPONSIVE OPTIMIZADOS
  // ========================================
  static const double mobileBreakpoint = 480;        // Móviles
  static const double tabletVerticalBreakpoint = 600; // 10" vertical (aparcímetro)
  static const double tabletBreakpoint = 768;        // Tablets horizontales
  static const double desktopBreakpoint = 1024;      // PC/Portátil
  static const double largeDesktopBreakpoint = 1440; // Pantallas grandes

  // ========================================
  // 📏 TAMAÑOS DE FUENTE CONSISTENTES
  // ========================================
  static const double titleFontSize = 28.0;
  static const double subtitleFontSize = 22.0;
  static const double bodyFontSize = 18.0;
  static const double captionFontSize = 16.0;
  static const double smallFontSize = 14.0;
  static const double tinyFontSize = 12.0;
  
  // ========================================
  // 🏪 TAMAÑOS ESPECÍFICOS PARA APARCÍMETRO
  // ========================================
  static const double kioskTitleFontSize = 36.0;     // Títulos más grandes
  static const double kioskSubtitleFontSize = 28.0;  // Subtítulos más grandes
  static const double kioskBodyFontSize = 22.0;      // Texto más legible
  static const double kioskCaptionFontSize = 20.0;   // Captions más grandes

  // ========================================
  // 🔘 ALTURAS DE BOTONES CONSISTENTES
  // ========================================
  static const double primaryButtonHeight = 60.0;
  static const double secondaryButtonHeight = 48.0;
  static const double smallButtonHeight = 40.0;
  static const double largeButtonHeight = 80.0;
  
  // ========================================
  // 🏪 BOTONES ESPECÍFICOS PARA APARCÍMETRO
  // ========================================
  static const double kioskPrimaryButtonHeight = 80.0;   // Botones más grandes
  static const double kioskSecondaryButtonHeight = 65.0; // Botones secundarios más grandes
  static const double kioskSmallButtonHeight = 50.0;     // Botones pequeños más grandes

  // ========================================
  // 📐 ESPACIADO CONSISTENTE
  // ========================================
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // ========================================
  // 📦 PADDING CONSISTENTE
  // ========================================
  static const double paddingXS = 8.0;
  static const double paddingS = 12.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  // ========================================
  // 🎯 ANCHO MÁXIMO DE CONTENIDO
  // ========================================
  static const double maxContentWidth = 800.0;  // Aumentado para PC/portátil
  static const double minContentWidth = 260.0;
  static const double kioskMaxContentWidth = 600.0;  // Específico para aparcímetro

  // ========================================
  // 🔄 BORDER RADIUS CONSISTENTE
  // ========================================
  static const double borderRadiusS = 8.0;
  static const double borderRadiusM = 12.0;
  static const double borderRadiusL = 16.0;
  static const double borderRadiusXL = 24.0;
  static const double borderRadiusXXL = 30.0;

  // ========================================
  // 📱 MÉTODOS RESPONSIVE
  // ========================================
  
  /// Determina si es móvil basado en el ancho
  static bool isMobile(double width) => width < mobileBreakpoint;
  
  /// Determina si es tablet vertical (aparcímetro 10")
  static bool isTabletVertical(double width) => width >= mobileBreakpoint && width < tabletVerticalBreakpoint;
  
  /// Determina si es tablet horizontal basado en el ancho
  static bool isTablet(double width) => width >= tabletVerticalBreakpoint && width < desktopBreakpoint;
  
  /// Determina si es desktop basado en el ancho
  static bool isDesktop(double width) => width >= desktopBreakpoint;
  
  /// Determina si es pantalla ancha basado en el ancho
  static bool isWide(double width) => width >= tabletBreakpoint;
  
  /// Determina si es aparcímetro (tablet vertical 10")
  static bool isKiosk(double width) => isTabletVertical(width);

  // ========================================
  // 🎨 OBTENER TAMAÑOS RESPONSIVE
  // ========================================
  
  /// Obtiene el tamaño de fuente del título según el ancho
  static double getTitleFontSize(double width) {
    if (isKiosk(width)) return kioskTitleFontSize;
    if (isMobile(width)) return titleFontSize * 0.8;
    if (isTablet(width)) return titleFontSize * 0.9;
    return titleFontSize;
  }
  
  /// Obtiene el tamaño de fuente del subtítulo según el ancho
  static double getSubtitleFontSize(double width) {
    if (isKiosk(width)) return kioskSubtitleFontSize;
    if (isMobile(width)) return subtitleFontSize * 0.8;
    if (isTablet(width)) return subtitleFontSize * 0.9;
    return subtitleFontSize;
  }
  
  /// Obtiene el tamaño de fuente del cuerpo según el ancho
  static double getBodyFontSize(double width) {
    if (isKiosk(width)) return kioskBodyFontSize;
    if (isMobile(width)) return bodyFontSize * 0.85;
    if (isTablet(width)) return bodyFontSize * 0.9;
    return bodyFontSize;
  }
  
  /// Obtiene la altura del botón principal según el ancho
  static double getPrimaryButtonHeight(double width) {
    if (isKiosk(width)) return kioskPrimaryButtonHeight;
    if (isMobile(width)) return primaryButtonHeight * 0.8;
    if (isTablet(width)) return primaryButtonHeight * 0.9;
    return primaryButtonHeight;
  }
  
  /// Obtiene la altura del botón secundario según el ancho
  static double getSecondaryButtonHeight(double width) {
    if (isKiosk(width)) return kioskSecondaryButtonHeight;
    if (isMobile(width)) return secondaryButtonHeight * 0.8;
    if (isTablet(width)) return secondaryButtonHeight * 0.9;
    return secondaryButtonHeight;
  }
  
  /// Obtiene el espaciado según el ancho
  static double getSpacing(double width) {
    if (isKiosk(width)) return spacingXL;  // Más espaciado para aparcímetro
    if (isMobile(width)) return spacingM;
    if (isTablet(width)) return spacingL;
    return spacingXL;
  }
  
  /// Obtiene el padding según el ancho
  static double getPadding(double width) {
    if (isKiosk(width)) return paddingXL;  // Más padding para aparcímetro
    if (isMobile(width)) return paddingM;
    if (isTablet(width)) return paddingL;
    return paddingXL;
  }

  // ========================================
  // 📐 OBTENER DIMENSIONES DE CONTENIDO
  // ========================================
  
  /// Obtiene el ancho del contenido según el ancho disponible
  static double getContentWidth(double availableWidth) {
    if (isKiosk(availableWidth)) {
      // Para aparcímetro, usar ancho específico
      if (availableWidth > kioskMaxContentWidth) return kioskMaxContentWidth;
      if (availableWidth < minContentWidth) return minContentWidth;
      return availableWidth;
    }
    if (availableWidth > maxContentWidth) return maxContentWidth;
    if (availableWidth < minContentWidth) return minContentWidth;
    return availableWidth;
  }
  
  /// Obtiene el padding horizontal según el ancho del contenido
  static double getHorizontalPadding(double contentWidth) {
    return contentWidth * 0.05; // 5% del ancho del contenido
  }

  // ========================================
  // 🎨 ESTILOS DE BOTÓN CONSISTENTES
  // ========================================
  
  /// Obtiene el estilo base para botones principales
  static ButtonStyle getPrimaryButtonStyle({
    required double width,
    required Color backgroundColor,
    required Color foregroundColor,
    bool isEnabled = true,
  }) {
    return ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return backgroundColor.withOpacity(0.3);
        }
        return backgroundColor;
      }),
      foregroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return foregroundColor.withOpacity(0.5);
        }
        return foregroundColor;
      }),
      minimumSize: MaterialStatePropertyAll(
        Size(double.infinity, getPrimaryButtonHeight(width))
      ),
      padding: MaterialStatePropertyAll(
        EdgeInsets.symmetric(horizontal: getPadding(width))
      ),
      shape: MaterialStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusXXL),
        ),
      ),
      textStyle: MaterialStatePropertyAll(
        TextStyle(
          fontSize: getBodyFontSize(width),
          fontWeight: FontWeight.w600,
        ),
      ),
      elevation: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return 0;
        }
        return 2;
      }),
    );
  }
  
  /// Obtiene el estilo base para botones secundarios
  static ButtonStyle getSecondaryButtonStyle({
    required double width,
    required Color backgroundColor,
    required Color foregroundColor,
    bool isEnabled = true,
  }) {
    return ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return backgroundColor.withOpacity(0.3);
        }
        return backgroundColor;
      }),
      foregroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return foregroundColor.withOpacity(0.5);
        }
        return foregroundColor;
      }),
      minimumSize: MaterialStatePropertyAll(
        Size(double.infinity, getSecondaryButtonHeight(width))
      ),
      padding: MaterialStatePropertyAll(
        EdgeInsets.symmetric(horizontal: getPadding(width))
      ),
      shape: MaterialStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusL),
        ),
      ),
      textStyle: MaterialStatePropertyAll(
        TextStyle(
          fontSize: getBodyFontSize(width),
          fontWeight: FontWeight.w500,
        ),
      ),
      elevation: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return 0;
        }
        return 1;
      }),
    );
  }

  /// Obtiene el estilo para botones con ancho inteligente (proporcional al texto)
  static ButtonStyle getSmartWidthButtonStyle({
    required double width,
    required Color backgroundColor,
    required Color foregroundColor,
    required String text,
    bool isPrimary = true,
    bool isEnabled = true,
  }) {
    // Calcular ancho mínimo basado en el texto
    final textLength = text.length;
    final minWidth = (textLength * 12.0).clamp(120.0, 300.0); // Ancho mínimo inteligente
    
    return ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return backgroundColor.withOpacity(0.3);
        }
        return backgroundColor;
      }),
      foregroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return foregroundColor.withOpacity(0.5);
        }
        return foregroundColor;
      }),
      minimumSize: MaterialStatePropertyAll(
        Size(minWidth, isPrimary ? getPrimaryButtonHeight(width) : getSecondaryButtonHeight(width))
      ),
      padding: MaterialStatePropertyAll(
        EdgeInsets.symmetric(horizontal: getPadding(width) * 0.8)
      ),
      shape: MaterialStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isPrimary ? borderRadiusXXL : borderRadiusL),
        ),
      ),
      textStyle: MaterialStatePropertyAll(
        TextStyle(
          fontSize: getBodyFontSize(width),
          fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      elevation: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return 0;
        }
        return isPrimary ? 2 : 1;
      }),
    );
  }

  // ========================================
  // 📱 LAYOUT RESPONSIVE
  // ========================================
  
  /// Obtiene el layout de botones según el ancho
  static Widget getButtonLayout({
    required double width,
    required List<Widget> buttons,
    double? spacing,
  }) {
    final effectiveSpacing = spacing ?? getSpacing(width);
    
    if (isWide(width) && buttons.length == 2) {
      // Layout horizontal para pantallas anchas con 2 botones
      return Row(
        children: [
          Expanded(child: buttons[0]),
          SizedBox(width: effectiveSpacing),
          Expanded(child: buttons[1]),
        ],
      );
    } else {
      // Layout vertical para móviles o más de 2 botones
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: buttons.asMap().entries.map((entry) {
          final index = entry.key;
          final button = entry.value;
          return Column(
            children: [
              button,
              if (index < buttons.length - 1) SizedBox(height: effectiveSpacing),
            ],
          );
        }).toList(),
      );
    }
  }
  
  /// Obtiene el layout de botones en wrap para múltiples botones
  static Widget getButtonWrapLayout({
    required double width,
    required List<Widget> buttons,
    double? spacing,
  }) {
    final effectiveSpacing = spacing ?? getSpacing(width);
    
    return Wrap(
      spacing: effectiveSpacing,
      runSpacing: effectiveSpacing * 0.5,
      alignment: WrapAlignment.center,
      children: buttons,
    );
  }

  // ========================================
  // 🎯 UTILIDADES DE SCROLL
  // ========================================
  
  /// Determina si necesita scroll basado en la altura disponible
  static bool needsScroll(double availableHeight, double contentHeight) {
    return availableHeight < contentHeight + 100; // 100px de margen
  }
  
  /// Obtiene el widget de scroll apropiado
  static Widget getScrollableContent({
    required double availableHeight,
    required double contentHeight,
    required Widget child,
  }) {
    if (needsScroll(availableHeight, contentHeight)) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: child,
      );
    }
    return child;
  }

  // ========================================
  // 🏪 MÉTODOS ESPECÍFICOS PARA APARCÍMETRO
  // ========================================
  
  /// Obtiene el estilo de botón optimizado para aparcímetro
  static ButtonStyle getKioskButtonStyle({
    required Color backgroundColor,
    required Color foregroundColor,
    bool isPrimary = true,
    bool isEnabled = true,
  }) {
    return ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return backgroundColor.withOpacity(0.3);
        }
        return backgroundColor;
      }),
      foregroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return foregroundColor.withOpacity(0.5);
        }
        return foregroundColor;
      }),
      minimumSize: MaterialStatePropertyAll(
        Size(double.infinity, isPrimary ? kioskPrimaryButtonHeight : kioskSecondaryButtonHeight)
      ),
      padding: MaterialStatePropertyAll(
        EdgeInsets.symmetric(horizontal: paddingXL, vertical: paddingL)
      ),
      shape: MaterialStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusXXL),
        ),
      ),
      textStyle: MaterialStatePropertyAll(
        TextStyle(
          fontSize: kioskBodyFontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevation: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return 0;
        }
        return 3;
      }),
    );
  }
  
  /// Obtiene el layout optimizado para aparcímetro (botones centrados y grandes)
  static Widget getKioskLayout({
    required List<Widget> buttons,
    double? spacing,
  }) {
    final effectiveSpacing = spacing ?? spacingXXL;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: buttons.asMap().entries.map((entry) {
        final index = entry.key;
        final button = entry.value;
        return Column(
          children: [
            button,
            if (index < buttons.length - 1) SizedBox(height: effectiveSpacing),
          ],
        );
      }).toList(),
    );
  }
  
  /// Obtiene el ancho de contenido específico para aparcímetro
  static double getKioskContentWidth(double availableWidth) {
    if (availableWidth > kioskMaxContentWidth) return kioskMaxContentWidth;
    if (availableWidth < minContentWidth) return minContentWidth;
    return availableWidth;
  }
}

