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
  const MowizTimePage({super.key, required this.zone, required this.plate, this.selectedCompany});

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
      apiUrl = 'https://tariff2.onrender.com/v1/onstreet-service/product/by-zone/${widget.zone}&plate=${widget.plate}';
    } else {
      // EYPSA usa la rama main (por defecto)
      apiUrl = '${ConfigService.apiBaseUrl}/v1/onstreet-service/product/by-zone/${widget.zone}&plate=${widget.plate}';
    }

    try {
      final res = await http.get(Uri.parse(apiUrl));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as List;
        if (body.isNotEmpty) {
          final rate = body.first['rateSteps'] as Map<String, dynamic>;
          for (final s in List<Map<String, dynamic>>.from(rate['steps'] ?? [])) {
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

  /* ───────────  LIFE-CYCLE  ─────────── */

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clock = Timer.periodic(const Duration(seconds: 1),
        (_) => setState(() => _now = DateTime.now()));
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
    final t      = AppLocalizations.of(context).t;
    final locale = Intl.getCurrentLocale();

    final minutes  = _totalSec ~/ 60;
    final finish   = _now.add(Duration(seconds: _totalSec));
    final effectivePrice = ((_totalCents / 100) + _discountEurosApplied).clamp(0, double.infinity);
    final priceStr = formatPrice(effectivePrice.toDouble(), locale);

    /* ---- time navigation buttons ---- */
    
    Widget timeNavigationButton(String text, VoidCallback? onPressed, double fs) => SizedBox(
          width: 80,
          height: 60,
          child: ElevatedButton(
            style: kMowizFilledButtonStyle.copyWith(
              minimumSize: const MaterialStatePropertyAll(Size(80, 60)),
              textStyle  : MaterialStatePropertyAll(TextStyle(fontSize: fs + 4)),
            ),
            onPressed: onPressed != null ? () {
              SoundHelper.playTap();
              onPressed();
            } : null,
            child: AutoSizeText(text, maxLines: 1),
          ),
        );

    return MowizScaffold(
      title: 'MeyPark - ${t('selectDuration')}',
      body : LayoutBuilder(
        builder: (context, c) {
          final width   = c.maxWidth;
          const gap     = 18.0;
          final fontSz  = width >= 600 ? 24.0 : 19.0;
          final labelSz = fontSz - 2;

          return Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: 550),
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AutoSizeText(
                      DateFormat('EEE, d MMM yyyy - HH:mm', locale)
                          .format(_now),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: labelSz,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 22),

                    if (!_loaded)
                      const Center(child: CircularProgressIndicator())
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          timeNavigationButton(
                            '-',
                            _currentTimeIndex > 0 ? _decrementTime : null,
                            fontSz,
                          ),
                          const SizedBox(width: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).colorScheme.outline),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: AutoSizeText(
                              _blocks.isNotEmpty ? _fmtMin(_blocks[_currentTimeIndex]) : '0 min',
                              style: TextStyle(
                                fontSize: fontSz + 2,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 20),
                          timeNavigationButton(
                            '+',
                            _currentTimeIndex < _blocks.length - 1 ? _incrementTime : null,
                            fontSz,
                          ),
                        ],
                      ),

                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: _blocks.isNotEmpty ? _clear : null,
                      style: kMowizFilledButtonStyle.copyWith(
                        backgroundColor: MaterialStatePropertyAll(
                            Theme.of(context).colorScheme.secondary),
                        foregroundColor: MaterialStatePropertyAll(
                            Theme.of(context).colorScheme.onSecondary),
                        minimumSize:
                            const MaterialStatePropertyAll(Size(150, 44)),
                      ),
                      child: AutoSizeText(t('clear'), maxLines: 1),
                    ),
                    const SizedBox(height: 26),

                    AutoSizeText('${minutes ~/ 60}h ${minutes % 60}m',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                            fontSize: fontSz + 10,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    AutoSizeText('${t('price')}: $priceStr',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                            fontSize: labelSz,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    AutoSizeText(
                        '${t('until')}: ${DateFormat('HH:mm', locale).format(finish)}',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                            fontSize: labelSz,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    if (_loaded) ...[
                      const SizedBox(height: 4),
                      Column(
                        children: (() {
                          final sorted = _steps.entries.toList()
                            ..sort((a, b) => a.key.compareTo(b.key));
                          return sorted
                              .map((e) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 2),
                                    child: AutoSizeText(
                                      '${_fmtMin(e.key)} - ${formatPrice((e.value / 100).toDouble(), locale)}',
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: fontSz - 4),
                                    ),
                                  ))
                              .toList();
                        })(),
                      ),
                    ],

                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _totalSec > 0
                          ? () {
                              SoundHelper.playTap();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => MowizSummaryPage(
                                    plate   : widget.plate,
                                    zone    : widget.zone,
                                    start   : _now,
                                    minutes : minutes,
                                    price   : _totalCents / 100,
                                    selectedCompany: widget.selectedCompany,
                                  ),
                                ),
                              );
                            }
                          : null,
                      style: kMowizFilledButtonStyle.copyWith(
                        minimumSize: const MaterialStatePropertyAll(
                            Size(double.infinity, 50)),
                        textStyle:
                            MaterialStatePropertyAll(TextStyle(fontSize: fontSz)),
                      ),
                      child: AutoSizeText(t('continue'), maxLines: 1),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        SoundHelper.playTap();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const MowizPayPage()),
                          (_) => false,
                        );
                      },
                      style: kMowizFilledButtonStyle.copyWith(
                        minimumSize: const MaterialStatePropertyAll(
                            Size(double.infinity, 46)),
                        backgroundColor: MaterialStatePropertyAll(
                            Theme.of(context).colorScheme.secondary),
                      ),
                      child: AutoSizeText(t('back'), maxLines: 1),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () async {
                        SoundHelper.playTap();
                        
                        try {
                          // Verificar si el escáner está conectado
                          final isConnected = await UnifiedService.isScannerConnected();
                          
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
                          final discount = await UnifiedService.scanQrCode(context: context, timeout: 30);
                          
                          if (discount != null) {
                            // Verificar si es un QR FREE (descuento total)
                            if (discount <= -99999.0) {
                              // QR FREE: precio final 0.00€
                              final originalPrice = _totalCents / 100;
                              print('DEBUG FREE: originalPrice=$originalPrice, _totalCents=$_totalCents');
                              setState(() {
                                _totalCents = 0;
                                _discountEurosApplied = originalPrice;
                              });
                              print('DEBUG FREE after setState: _totalCents=$_totalCents, _discountEurosApplied=$_discountEurosApplied');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Descuento FREE aplicado: ${formatPrice(originalPrice.toDouble(), locale)} - Precio final: ${formatPrice(0.0, locale)}'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              // Descuento normal
                              final newTotal = (_totalCents / 100) + discount;
                              final newTotalCents = (newTotal * 100).round();
                              
                              // Asegurar que el precio no sea negativo
                              if (newTotalCents < 0) {
                                setState(() {
                                  _totalCents = 0;
                                  _discountEurosApplied = discount;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Descuento aplicado: ${formatPrice(discount.toDouble(), locale)} - Precio final: ${formatPrice(0.0, locale)}'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                setState(() {
                                  _totalCents = newTotalCents;
                                  _discountEurosApplied = discount;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Descuento aplicado: ${formatPrice(discount.toDouble(), locale)} - Precio final: ${formatPrice((newTotalCents / 100).toDouble(), locale)}'),
                                    backgroundColor: Colors.green,
                                  ),
                              );
                              }
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No se escaneó ningún código QR válido'),
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
                      style: kMowizFilledButtonStyle.copyWith(
                        minimumSize: const MaterialStatePropertyAll(
                            Size(double.infinity, 46)),
                        backgroundColor: MaterialStatePropertyAll(
                            Theme.of(context).colorScheme.secondary),
                      ),
                      child: AutoSizeText(t('scanQrButton'), maxLines: 1),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => _showManualCodeDialog(),
                      style: kMowizFilledButtonStyle.copyWith(
                        minimumSize: const MaterialStatePropertyAll(
                            Size(double.infinity, 46)),
                        backgroundColor: MaterialStatePropertyAll(
                            Theme.of(context).colorScheme.tertiary),
                      ),
                      child: AutoSizeText('Introducir código manualmente', maxLines: 1),
                    ),
                  ],
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
    double? discount;
    
    if (code == 'FREE') {
      discount = -99999.0; // Descuento total
    } else if (code.startsWith('-')) {
      // Procesar descuento numérico
      final cleanCode = code.substring(1).replaceAll(',', '.');
      discount = double.tryParse(cleanCode);
      if (discount != null) {
        discount = -discount; // Hacer negativo
      }
    }
    
    if (discount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código no válido. Usa formato: -5.50, -5,50 o FREE'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Aplicar el descuento usando la misma lógica que el QR
    if (discount <= -99999.0) {
      // Código FREE: precio final 0.00€
      final originalPrice = _totalCents / 100;
      print('DEBUG MANUAL FREE: originalPrice=$originalPrice, _totalCents=$_totalCents');
      setState(() {
        _totalCents = 0;
        _discountEurosApplied = originalPrice;
      });
      print('DEBUG MANUAL FREE after setState: _totalCents=$_totalCents, _discountEurosApplied=$_discountEurosApplied');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Descuento FREE aplicado: ${formatPrice(originalPrice.toDouble(), locale)} - Precio final: ${formatPrice(0.0, locale)}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Descuento normal
      final newTotal = (_totalCents / 100) + discount;
      final newTotalCents = (newTotal * 100).round();
      
      setState(() {
        if (newTotal <= 0) {
          _totalCents = 0;
          _discountEurosApplied = (_totalCents / 100) - discount;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Descuento aplicado: ${formatPrice(discount.toDouble(), locale)} - Precio final: ${formatPrice(0.0, locale)}'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _totalCents = newTotalCents;
          _discountEurosApplied = discount;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Descuento aplicado: ${formatPrice(discount.toDouble(), locale)} - Precio final: ${formatPrice((newTotalCents / 100).toDouble(), locale)}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    }
  }
}
