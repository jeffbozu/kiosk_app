import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'l10n/app_localizations.dart';
import 'mowiz_page.dart';
import 'mowiz_pay_page.dart';
import 'mowiz_summary_page.dart';
import 'mowiz/mowiz_scaffold.dart';
import 'styles/mowiz_buttons.dart';
import 'sound_helper.dart';

class MowizTimePage extends StatefulWidget {
  final String zone;
  final String plate;
  const MowizTimePage({super.key, required this.zone, required this.plate});

  @override
  State<MowizTimePage> createState() => _MowizTimePageState();
}

class _MowizTimePageState extends State<MowizTimePage> {
  late DateTime _now;
  Timer? _clock;

  /// minutos → céntimos
  Map<int, int> _steps = {};
  /// lista ordenada de bloques
  late List<int> _blocks = [];

  int? _maxDuration;        // en segundos
  bool _loaded = false;

  /// estado actual
  final Map<int, int> _units = {};   // bloque → nº veces sumado
  int _totalSec = 0;
  int _totalCents = 0;

  /* ─────────────────────  UTILIDADES  ───────────────────── */

  /// Ej: 60 → "1 h", 90 → "1 h 30 min", 15 → "15 min"
  String _fmtMin(int m) {
    if (m % 60 == 0) return '${m ~/ 60}h';
    if (m > 60)  return '${m ~/ 60}h ${m % 60}min';
    return '$m min';
  }

  /* ───────────────────  CARGA DE TARIFA  ────────────────── */
  Future<void> _load() async {
    setState(() {
      _steps.clear();
      _blocks = [];
      _units.clear();
      _totalSec = 0;
      _totalCents = 0;
      _loaded = false;
    });

    final url = '$apiBaseUrl/v1/onstreet-service/product/by-zone/'
               '${widget.zone}&plate=${widget.plate}';
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as List;
        if (body.isNotEmpty) {
          final rate = body.first['rateSteps'] as Map<String, dynamic>;
          for (final s
              in List<Map<String, dynamic>>.from(rate['steps'] ?? [])) {
            final min = (s['timeInSeconds'] as int) ~/ 60;
            _steps[min] = s['priceInCents'] as int;
            _units[min] = 0;
          }
          _blocks = _steps.keys.toList()..sort();
          _maxDuration = rate['maxDurationSeconds'] as int?;
        }
      }
    } catch (e) {
      debugPrint('Tarifa error: $e');
    }
    setState(() => _loaded = true);
  }

  /* ────────────────────────  SUMAR  ─────────────────────── */
  void _add(int minutes) {
    if (!_steps.containsKey(minutes)) return;

    final nextSec   = _totalSec   + minutes * 60;
    final nextCents = _totalCents + _steps[minutes]!;

    if (_maxDuration != null && nextSec > _maxDuration!) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Duración máxima')));
      return;
    }

    setState(() {
      _totalSec   = nextSec;
      _totalCents = nextCents;
      _units[minutes] = (_units[minutes] ?? 0) + 1;
    });
  }

  /* ────────────────────────  CLEAR  ─────────────────────── */
  void _clear() {
    setState(() {
      _units.updateAll((_, __) => 0);
      _totalSec = 0;
      _totalCents = 0;
    });
  }

  /* ─────────────────────  CICLO VIDA  ───────────────────── */
  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clock = Timer.periodic(
      const Duration(seconds: 1), (_) => setState(() => _now = DateTime.now()),
    );
    _load();
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  /* ────────────────────────── UI ────────────────────────── */
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final locale = Intl.getCurrentLocale();
    final minutes = _totalSec ~/ 60;
    final finish  = _now.add(Duration(seconds: _totalSec));
    final priceStr =
        NumberFormat.currency(symbol: '€', locale: locale).format(_totalCents / 100);

    /// Botón rojo de bloque (solo suma)
    Widget blockButton(int min, double fSize) => ElevatedButton(
          style: kMowizFilledButtonStyle.copyWith(
            minimumSize: const MaterialStatePropertyAll(Size(100, 48)),
            textStyle : MaterialStatePropertyAll(TextStyle(fontSize: fSize)),
          ),
          onPressed: () {
            SoundHelper.playTap();
            _add(min);
          },
          child: AutoSizeText('+${_fmtMin(min)}', maxLines: 1),
        );

    return MowizScaffold(
      title: 'MeyPark - ${t('selectDuration')}',
      body: LayoutBuilder(
        builder: (context, c) {
          final width   = c.maxWidth;
          final gap     = 16.0;
          final fontSz  = width >= 500 ? 24.0 : 18.0;
          final labelSz = fontSz - 2;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AutoSizeText(
                      DateFormat('EEE, d MMM yyyy - HH:mm', locale).format(_now),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(fontSize: labelSz, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    if (!_loaded)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      /// GRID dinámico (2 o 3 columnas)
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: gap,
                        runSpacing: gap,
                        children: _blocks
                            .map((m) => blockButton(m, fontSz))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _totalSec > 0 ? _clear : null,
                        style: kMowizFilledButtonStyle.copyWith(
                          backgroundColor: MaterialStatePropertyAll(
                            Theme.of(context).colorScheme.secondary,
                          ),
                          foregroundColor: MaterialStatePropertyAll(
                            Theme.of(context).colorScheme.onSecondary,
                          ),
                        ),
                        child: AutoSizeText(t('clear'), maxLines: 1),
                      ),
                    ],

                    const SizedBox(height: 24),
                    AutoSizeText(
                      '${minutes ~/ 60}h ${minutes % 60}m',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(fontSize: fontSz + 8, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    AutoSizeText('${t('price')}: $priceStr',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(fontSize: labelSz, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    AutoSizeText('${t('until')}: ${DateFormat('HH:mm', locale).format(finish)}',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(fontSize: labelSz, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    if (_loaded) _Tariff(map: _steps, fmt: _fmtMin, font: fontSz),

                    const SizedBox(height: 20),
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
                                  ),
                                ),
                              );
                            }
                          : null,
                      style: kMowizFilledButtonStyle.copyWith(
                        minimumSize: const MaterialStatePropertyAll(Size(double.infinity, 50)),
                        textStyle  : MaterialStatePropertyAll(TextStyle(fontSize: fontSz)),
                      ),
                      child: AutoSizeText(t('continue'), maxLines: 1),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: () {
                        SoundHelper.playTap();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const MowizPayPage()),
                          (_) => false,
                        );
                      },
                      style: kMowizFilledButtonStyle.copyWith(
                        minimumSize: const MaterialStatePropertyAll(Size(double.infinity, 46)),
                        backgroundColor: MaterialStatePropertyAll(
                          Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      child: AutoSizeText(t('back'), maxLines: 1),
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
}

/* ─────────  LISTA DE TARIFAS ───────── */
class _Tariff extends StatelessWidget {
  const _Tariff({
    required this.map,
    required this.fmt,
    required this.font,
  });

  final Map<int, int> map;
  final String Function(int) fmt;
  final double font;

  @override
  Widget build(BuildContext context) {
    final entries = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return Column(
      children: entries
          .map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: AutoSizeText(
                  '${fmt(e.key)} - ${(e.value / 100).toStringAsFixed(2)} €',
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: font - 4),
                ),
              ))
          .toList(),
    );
  }
}
