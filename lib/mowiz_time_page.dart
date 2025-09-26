import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import 'config_service.dart';
import 'l10n/app_localizations.dart';
import 'mowiz_page.dart';
import 'mowiz_pay_page.dart';
import 'mowiz_summary_page.dart';
import 'mowiz/mowiz_scaffold.dart';
import 'styles/mowiz_buttons.dart';
import 'styles/mowiz_design_system.dart';
import 'sound_helper.dart';
import 'services/unified_service.dart';

/// Helper function to format price with correct decimal separator based on locale
String formatPrice(double price, String locale) {
  if (locale.startsWith('es') || locale.startsWith('ca')) {
    // Use comma as decimal separator for Spanish and Catalan
    return '${price.toStringAsFixed(2).replaceAll('.', ',')} €';
  } else {
    // Use dot as decimal separator for English and others
    return '${price.toStringAsFixed(2)} €';
  }
}

class MowizTimePage extends StatefulWidget {
  final String zone;
  final String plate;
  final String? selectedCompany;
  const MowizTimePage({
    super.key,
    required this.zone,
    required this.plate,
    this.selectedCompany,
  });

  @override
  State<MowizTimePage> createState() => _MowizTimePageState();
}

class _MowizTimePageState extends State<MowizTimePage> {
  late DateTime _now;
  Timer? _clock;

  /// mapa minutos → céntimos
  final Map<int, int> _steps = {};
  List<int> _blocks = [];

  int? _maxDurationSec;
  bool _loaded = false;

  int _currentTimeIndex = 0;
  int _totalSec = 0;
  int _totalCents = 0;
  double _discountEurosApplied = 0.0;

  /* ───────────────  HELPERS  ─────────────── */

  String _fmtMin(int m) {
    if (m % 60 == 0) return '${m ~/ 60}h';
    if (m > 60) return '${m ~/ 60}h ${m % 60}min';
    return '$m min';
  }

  /* ─────────────  LOAD TARIFF  ───────────── */

  Future<void> _load() async {
    setState(() {
      _steps.clear();
      _blocks.clear();
      _currentTimeIndex = 0;
      _totalSec = _totalCents = 0;
      _loaded = false;
    });

    // 🎯 Determinar URL según la empresa seleccionada
    String apiUrl;
    if (widget.selectedCompany == 'MOWIZ') {
      // MOWIZ usa la rama tariff2 con tarifas diferentes
      apiUrl =
          'https://tariff2.onrender.com/v1/onstreet-service/product/by-zone/${widget.zone}&plate=${widget.plate}';
    } else {
      // EYPSA usa la rama main (por defecto)
      apiUrl =
          '${ConfigService.apiBaseUrl}/v1/onstreet-service/product/by-zone/${widget.zone}&plate=${widget.plate}';
    }

    try {
      final res = await http.get(Uri.parse(apiUrl));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as List;
        if (body.isNotEmpty) {
          final rate = body.first['rateSteps'] as Map<String, dynamic>;
          for (final s in List<Map<String, dynamic>>.from(
            rate['steps'] ?? [],
          )) {
            final min = (s['timeInSeconds'] as int) ~/ 60;
            _steps[min] = s['priceInCents'] as int;
          }
          _blocks = _steps.keys.toList()..sort();
          _maxDurationSec = rate['maxDurationSeconds'] as int?;

          // Inicializar con el tiempo mínimo del servidor
          if (_blocks.isNotEmpty) {
            _currentTimeIndex = 0;
            _totalSec = _blocks[0] * 60;
            _totalCents = _steps[_blocks[0]]!;
          }
        }
      }
    } catch (e) {
      debugPrint('Load tariff error: $e');
    }
    setState(() => _loaded = true);
  }

  /* ───────────────  TIME NAVIGATION  ────────────── */

  void _incrementTime() {
    if (_currentTimeIndex < _blocks.length - 1) {
      setState(() {
        _currentTimeIndex++;
        _totalSec = _blocks[_currentTimeIndex] * 60;
        _totalCents = _steps[_blocks[_currentTimeIndex]]!;
      });
    }
  }

  void _decrementTime() {
    if (_currentTimeIndex > 0) {
      setState(() {
        _currentTimeIndex--;
        _totalSec = _blocks[_currentTimeIndex] * 60;
        _totalCents = _steps[_blocks[_currentTimeIndex]]!;
      });
    }
  }

  void _clear() => setState(() {
    if (_blocks.isNotEmpty) {
      _currentTimeIndex = 0;
      _totalSec = _blocks[0] * 60;
      _totalCents = _steps[_blocks[0]]!;
    }
    _discountEurosApplied = 0.0;
  });

  /* ───────────  TIMEZONE HELPERS  ─────────── */

  /// Detecta si estamos en horario de verano en España
  bool _isDaylightSavingTime(DateTime date) {
    // En España, el horario de verano va del último domingo de marzo al último domingo de octubre
    final year = date.year;

    // Último domingo de marzo
    final marchLastSunday = _getLastSundayOfMonth(year, 3);
    final marchLastSundayDate = DateTime(year, 3, marchLastSunday, 2, 0, 0);

    // Último domingo de octubre
    final octoberLastSunday = _getLastSundayOfMonth(year, 10);
    final octoberLastSundayDate = DateTime(
      year,
      10,
      octoberLastSunday,
      3,
      0,
      0,
    );

    // Para septiembre 2025, estamos en horario de verano (UTC+2)
    if (date.month == 9 && date.year == 2025) {
      return true;
    }

    return date.isAfter(marchLastSundayDate) &&
        date.isBefore(octoberLastSundayDate);
  }

  /// Obtiene el último domingo de un mes
  int _getLastSundayOfMonth(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0).day; // Último día del mes
    for (int day = lastDay; day >= 1; day--) {
      final date = DateTime(year, month, day);
      if (date.weekday == DateTime.sunday) {
        return day;
      }
    }
    return 1; // Fallback
  }

  /// Obtiene la hora actual de España (Madrid)
  DateTime _getSpainTime() {
    // El sistema ya está configurado en la zona horaria de España (UTC+2 en verano)
    // Por lo tanto, DateTime.now() ya devuelve la hora correcta de Madrid
    return DateTime.now();
  }

  /* ───────────  LIFE-CYCLE  ─────────── */

  @override
  void initState() {
    super.initState();
    _now = _getSpainTime();
    _clock = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _now = _getSpainTime()),
    );
    _load();
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  /* ────────────────  UI  ──────────────── */

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final locale = Intl.getCurrentLocale();

    final minutes = _totalSec ~/ 60;
    final finish = _now.add(Duration(seconds: _totalSec));
    final effectivePrice = ((_totalCents / 100) - _discountEurosApplied).clamp(
      0,
      double.infinity,
    );
    final priceStr = formatPrice(effectivePrice.toDouble(), locale);

    /* ---- time navigation buttons ---- */

    Widget timeNavigationButton(
      String text,
      VoidCallback? onPressed,
      double width,
    ) => ElevatedButton(
      style: MowizDesignSystem.getSmartWidthButtonStyle(
        width: width,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        text: text,
        isPrimary: false,
        isEnabled: onPressed != null,
      ),
      onPressed: onPressed != null
          ? () {
              SoundHelper.playTap();
              onPressed();
            }
          : null,
      child: AutoSizeText(text, maxLines: 1),
    );

    return MowizScaffold(
      title: 'MeyPark - ${t('selectDuration')}',
      body: LayoutBuilder(
        builder: (context, c) {
          final width = c.maxWidth;
          final height = c.maxHeight;

          // 🎨 Usar sistema de diseño homogéneo
          final contentWidth = MowizDesignSystem.getContentWidth(width);
          final horizontalPadding = MowizDesignSystem.getHorizontalPadding(
            contentWidth,
          );
          final spacing = MowizDesignSystem.getSpacing(width);
          final titleFontSize = MowizDesignSystem.getTitleFontSize(width);
          final bodyFontSize = MowizDesignSystem.getBodyFontSize(width);
          final labelFontSize = MowizDesignSystem.getSubtitleFontSize(width);

          return MowizDesignSystem.getScrollableContent(
            availableHeight: height,
            contentHeight: 800,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MowizDesignSystem.getContentWidth(width),
                  minWidth: MowizDesignSystem.minContentWidth,
                  minHeight: height,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AutoSizeText(
                        DateFormat(
                          'EEE, d MMM yyyy - HH:mm',
                          locale,
                        ).format(_now),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: labelFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: spacing),

                      if (!_loaded)
                        const Center(child: CircularProgressIndicator())
                      else
                        Column(
                          children: [
                            // Layout vertical para aparcímetro - más compacto
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: spacing * 2,
                                vertical: MowizDesignSystem.paddingXL,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(
                                  MowizDesignSystem.borderRadiusXL,
                                ),
                              ),
                              child: AutoSizeText(
                                _blocks.isNotEmpty
                                    ? _fmtMin(_blocks[_currentTimeIndex])
                                    : '0 min',
                                style: TextStyle(
                                  fontSize:
                                      bodyFontSize + 8, // Texto más grande
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: spacing * 0.5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                timeNavigationButton(
                                  '-',
                                  _currentTimeIndex > 0 ? _decrementTime : null,
                                  width,
                                ),
                                SizedBox(width: spacing * 3),
                                timeNavigationButton(
                                  '+',
                                  _currentTimeIndex < _blocks.length - 1
                                      ? _incrementTime
                                      : null,
                                  width,
                                ),
                              ],
                            ),
                          ],
                        ),

                      SizedBox(height: spacing),
                      FilledButton(
                        onPressed: _blocks.isNotEmpty ? _clear : null,
                        style: MowizDesignSystem.getSmartWidthButtonStyle(
                          width: width,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onSecondary,
                          text: t('clear'),
                          isPrimary: false,
                          isEnabled: _blocks.isNotEmpty,
                        ),
                        child: AutoSizeText(t('clear'), maxLines: 1),
                      ),
                      SizedBox(height: spacing * 1.5),

                      AutoSizeText(
                        '${minutes ~/ 60}h ${minutes % 60}m',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: MowizDesignSystem.spacingS),
                      AutoSizeText(
                        '${t('price')}: $priceStr',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: labelFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: MowizDesignSystem.spacingS),
                      AutoSizeText(
                        '${t('until')}: ${DateFormat('HH:mm', locale).format(finish)}',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: labelFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: spacing),

                      if (_loaded) ...[
                        SizedBox(height: MowizDesignSystem.spacingS),
                        Column(
                          children: (() {
                            final sorted = _steps.entries.toList()
                              ..sort((a, b) => a.key.compareTo(b.key));
                            return sorted
                                .map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: AutoSizeText(
                                      '${_fmtMin(e.key)} - ${formatPrice((e.value / 100).toDouble(), locale)}',
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: bodyFontSize - 4,
                                      ),
                                    ),
                                  ),
                                )
                                .toList();
                          })(),
                        ),
                      ],

                      SizedBox(height: spacing * 1.5),
                      FilledButton(
                        onPressed: _totalSec > 0
                            ? () {
                                SoundHelper.playTap();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MowizSummaryPage(
                                      plate: widget.plate,
                                      zone: widget.zone,
                                      start: _now,
                                      minutes: minutes,
                                      price: effectivePrice.toDouble(),
                                      selectedCompany: widget.selectedCompany,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        style: MowizDesignSystem.getSmartWidthButtonStyle(
                          width: width,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          text: t('continue'),
                          isPrimary: true,
                          isEnabled: _totalSec > 0,
                        ),
                        child: AutoSizeText(t('continue'), maxLines: 1),
                      ),
                      SizedBox(height: spacing),
                      FilledButton(
                        onPressed: () {
                          SoundHelper.playTap();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => MowizPayPage(
                                selectedCompany: widget.selectedCompany,
                              ),
                            ),
                            (_) => false,
                          );
                        },
                        style: MowizDesignSystem.getSmartWidthButtonStyle(
                          width: width,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onSecondary,
                          text: t('back'),
                          isPrimary: false,
                          isEnabled: true,
                        ),
                        child: AutoSizeText(t('back'), maxLines: 1),
                      ),
                      SizedBox(height: spacing),
                      FilledButton(
                        onPressed: () async {
                          SoundHelper.playTap();

                          try {
                            // Verificar si el escáner está conectado
                            final isConnected =
                                await UnifiedService.isScannerConnected();

                            if (!isConnected) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Escáner QR no disponible'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // Mostrar indicador de escaneo
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Escaneando código QR...'),
                                duration: Duration(seconds: 2),
                              ),
                            );

                            // Escanear código QR
                            final discount = await UnifiedService.scanQrCode(
                              context: context,
                              timeout: 30,
                            );

                            if (discount != null) {
                              // Aplicar descuento
                              setState(() {
                                _discountEurosApplied =
                                    -discount; // Convertir a valor positivo para restar
                              });

                              final finalPrice =
                                  ((_totalCents / 100) - _discountEurosApplied)
                                      .clamp(0, double.infinity)
                                      .toDouble();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Descuento aplicado: ${formatPrice(_discountEurosApplied, locale)} - Precio final: ${formatPrice(finalPrice, locale)}',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'No se escaneó ningún código QR válido',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al escanear: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: MowizDesignSystem.getSmartWidthButtonStyle(
                          width: width,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onSecondary,
                          text: t('scanQrButton'),
                          isPrimary: false,
                          isEnabled: true,
                        ),
                        child: AutoSizeText(t('scanQrButton'), maxLines: 1),
                      ),
                      SizedBox(height: spacing),
                      FilledButton(
                        onPressed: () => _showManualCodeDialog(),
                        style: MowizDesignSystem.getSmartWidthButtonStyle(
                          width: width,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.tertiary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onTertiary,
                          text: 'Introducir código manualmente',
                          isPrimary: false,
                          isEnabled: true,
                        ),
                        child: AutoSizeText(
                          'Introducir código manualmente',
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /* ---- manual code dialog ---- */

  void _showManualCodeDialog() {
    final TextEditingController codeController = TextEditingController();
    final t = AppLocalizations.of(context).t;
    final locale = Intl.getCurrentLocale();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Introducir código de descuento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Introduce el código de descuento:'),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  hintText: 'Ej: -5.50, -5,50, FREE',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 8),
              const Text(
                'Formatos válidos:\n• -5.50 o -5,50 (descuento en euros)\n• FREE (descuento total)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final code = codeController.text.trim().toUpperCase();
                Navigator.of(context).pop();
                _processManualCode(code, locale);
              },
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }

  void _processManualCode(String code, String locale) {
    double discount;

    if (code == 'FREE') {
      discount = -99999.0; // Descuento total
    } else if (code.startsWith('-')) {
      // Procesar descuento numérico
      final cleanCode = code.substring(1).replaceAll(',', '.');
      final parsedDiscount = double.tryParse(cleanCode);
      if (parsedDiscount != null) {
        discount = -parsedDiscount; // Hacer negativo
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código no válido. Usa formato: -5.50, -5,50 o FREE'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código no válido. Usa formato: -5.50, -5,50 o FREE'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Aplicar el descuento usando la misma lógica que el QR
    setState(() {
      _discountEurosApplied =
          -discount; // Convertir a valor positivo para restar
    });

    final finalPrice = ((_totalCents / 100) - _discountEurosApplied)
        .clamp(0, double.infinity)
        .toDouble();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Descuento aplicado: ${formatPrice(_discountEurosApplied, locale)} - Precio final: ${formatPrice(finalPrice, locale)}',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
}
