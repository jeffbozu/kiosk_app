import 'package:flutter/material.dart';

/// Sistema de diseño homogéneo para todas las páginas MOWIZ
/// Garantiza consistencia visual y responsive design
class MowizDesignSystem {
  // Evitar instanciación
  MowizDesignSystem._();

  // ========================================
  // 📱 BREAKPOINTS RESPONSIVE
  // ========================================
  static const double mobileBreakpoint = 500;
  static const double tabletBreakpoint = 700;
  static const double desktopBreakpoint = 900;
  static const double largeDesktopBreakpoint = 1200;

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
  // 🔘 ALTURAS DE BOTONES CONSISTENTES
  // ========================================
  static const double primaryButtonHeight = 60.0;
  static const double secondaryButtonHeight = 48.0;
  static const double smallButtonHeight = 40.0;
  static const double largeButtonHeight = 80.0;

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
  static const double maxContentWidth = 500.0;
  static const double minContentWidth = 260.0;

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
  
  /// Determina si es tablet basado en el ancho
  static bool isTablet(double width) => width >= mobileBreakpoint && width < desktopBreakpoint;
  
  /// Determina si es desktop basado en el ancho
  static bool isDesktop(double width) => width >= desktopBreakpoint;
  
  /// Determina si es pantalla ancha basado en el ancho
  static bool isWide(double width) => width >= tabletBreakpoint;

  // ========================================
  // 🎨 OBTENER TAMAÑOS RESPONSIVE
  // ========================================
  
  /// Obtiene el tamaño de fuente del título según el ancho
  static double getTitleFontSize(double width) {
    if (isMobile(width)) return titleFontSize * 0.8;
    if (isTablet(width)) return titleFontSize * 0.9;
    return titleFontSize;
  }
  
  /// Obtiene el tamaño de fuente del subtítulo según el ancho
  static double getSubtitleFontSize(double width) {
    if (isMobile(width)) return subtitleFontSize * 0.8;
    if (isTablet(width)) return subtitleFontSize * 0.9;
    return subtitleFontSize;
  }
  
  /// Obtiene el tamaño de fuente del cuerpo según el ancho
  static double getBodyFontSize(double width) {
    if (isMobile(width)) return bodyFontSize * 0.85;
    if (isTablet(width)) return bodyFontSize * 0.9;
    return bodyFontSize;
  }
  
  /// Obtiene la altura del botón principal según el ancho
  static double getPrimaryButtonHeight(double width) {
    if (isMobile(width)) return primaryButtonHeight * 0.8;
    if (isTablet(width)) return primaryButtonHeight * 0.9;
    return primaryButtonHeight;
  }
  
  /// Obtiene la altura del botón secundario según el ancho
  static double getSecondaryButtonHeight(double width) {
    if (isMobile(width)) return secondaryButtonHeight * 0.8;
    if (isTablet(width)) return secondaryButtonHeight * 0.9;
    return secondaryButtonHeight;
  }
  
  /// Obtiene el espaciado según el ancho
  static double getSpacing(double width) {
    if (isMobile(width)) return spacingM;
    if (isTablet(width)) return spacingL;
    return spacingXL;
  }
  
  /// Obtiene el padding según el ancho
  static double getPadding(double width) {
    if (isMobile(width)) return paddingM;
    if (isTablet(width)) return paddingL;
    return paddingXL;
  }

  // ========================================
  // 📐 OBTENER DIMENSIONES DE CONTENIDO
  // ========================================
  
  /// Obtiene el ancho del contenido según el ancho disponible
  static double getContentWidth(double availableWidth) {
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
  }) {
    return ButtonStyle(
      backgroundColor: MaterialStatePropertyAll(backgroundColor),
      foregroundColor: MaterialStatePropertyAll(foregroundColor),
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
      elevation: MaterialStatePropertyAll(2),
    );
  }
  
  /// Obtiene el estilo base para botones secundarios
  static ButtonStyle getSecondaryButtonStyle({
    required double width,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return ButtonStyle(
      backgroundColor: MaterialStatePropertyAll(backgroundColor),
      foregroundColor: MaterialStatePropertyAll(foregroundColor),
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
      elevation: MaterialStatePropertyAll(1),
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
}

