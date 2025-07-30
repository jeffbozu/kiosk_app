import 'dart:async';
import 'dart:convert';

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

// Base URL configuration for API calls
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

  // Datos que llegan del backend
  Map<int, int> _stepsMap = {};        // minutos → precio céntimos
  int? _maxDuration;                   // segundos
  bool _tariffLoaded = false;

  // Estado de la selección
  final Map<int, int> _bloques = {3: 0, 5: 0, 15: 0};
  int _totalSec = 0;
  int _totalCents = 0;

  /* ─────────────────────────  PETICIÓN  ───────────────────────── */
  Future<void> _loadTariff() async {
    // limpiar todo
    setState(() {
      _stepsMap.clear();
      _maxDuration = null;
      _bloques.updateAll((k, v) => 0);
      _totalSec = 0;
      _totalCents = 0;
      _tariffLoaded = false;
    });

    // Build the request URL using the base constant
    final url =
        '$apiBaseUrl/v1/onstreet-service/product/by-zone/${widget.zone}&plate=${widget.plate}';
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        if (list.isNotEmpty) {
          final rate = list.first['rateSteps'] as Map<String, dynamic>;
          final steps = List<Map<String, dynamic>>.from(rate['steps'] ?? []);
          _stepsMap = {
            for (final s in steps)
              (s['timeInSeconds'] as int) ~/ 60: s['priceInCents'] as int
          };
          _maxDuration = rate['maxDurationSeconds'] as int?;
        }
        setState(() => _tariffLoaded = true);
      } else {
        debugPrint('HTTP ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  /* ───────────────────────  SUMAR / RESTAR  ───────────────────── */
  void _change(int minutos) {
    if (!_tariffLoaded || !_stepsMap.containsKey(minutos.abs())) return;

    final cents = _stepsMap[minutos.abs()]!;
    final nextSec = _totalSec + minutos * 60;
    final nextCents = _totalCents + (minutos > 0 ? cents : -cents);

    // no permitir negativos
    if (nextSec < 0 || nextCents < 0) return;

    // comprobar duración máxima
    if (_maxDuration != null && nextSec > _maxDuration!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duración máxima alcanzada')),
      );
      return;
    }

    setState(() {
      _totalSec = nextSec;
      _totalCents = nextCents;
      _bloques[minutos.abs()] = _bloques[minutos.abs()]! + (minutos > 0 ? 1 : -1);
    });
  }

  /* ─────────────────────────  CICLO DE VIDA  ──────────────────── */
  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
    _loadTariff();
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  /* ───────────────────────────  BUILD  ────────────────────────── */
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final locale = Intl.systemLocale.startsWith('es')
        ? 'es_ES'
        : Intl.systemLocale.startsWith('ca')
            ? 'ca_ES'
            : 'en_GB';

    final minutes = _totalSec ~/ 60;
    final finish = _now.add(Duration(seconds: _totalSec));
    final priceStr =
        NumberFormat.currency(symbol: '€', locale: 'es_ES').format(_totalCents / 100);

    Widget btn(String label, int min, double font) => Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, minHeight: 48),
            child: FilledButton(
              style: kMowizFilledButtonStyle.copyWith(
                textStyle: MaterialStatePropertyAll(TextStyle(fontSize: font)),
              ),
              onPressed: () {
                SoundHelper.playTap();
                _change(min);
              },
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label),
              ),
            ),
          ),
        );

    return MowizScaffold(
      title: 'MeyPark - ${t('selectDuration')}',
      // SafeArea ya aplicada en MowizScaffold
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final padding = EdgeInsets.all(height * 0.05);
          final double gap = height * 0.05;
          final double titleFont = max(16, width * 0.05);
          final double valueFont = max(16, width * 0.06);

          Widget localBtn(String label, int min) => btn(label, min, valueFont);

          return Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    DateFormat('EEE, d MMM yyyy - HH:mm', locale).format(_now),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: titleFont, fontWeight: FontWeight.bold),
                  ),
                ),
                Row(children: [localBtn('+3', 3), SizedBox(width: gap / 2), localBtn('+5', 5), SizedBox(width: gap / 2), localBtn('+15', 15)]),
                Row(children: [localBtn('-3', -3), SizedBox(width: gap / 2), localBtn('-5', -5), SizedBox(width: gap / 2), localBtn('-15', -15)]),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('${minutes ~/ 60}h ${minutes % 60}m',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: valueFont + 4, fontWeight: FontWeight.bold)),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('${t('price')}: $priceStr',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: titleFont, fontWeight: FontWeight.bold)),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('${t('until')}: ${DateFormat('HH:mm', locale).format(finish)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: titleFont, fontWeight: FontWeight.bold)),
                ),
                if (_tariffLoaded)
                  Expanded(
                    child: _TariffList(_stepsMap, font: titleFont),
                  )
                else
                  const CircularProgressIndicator(),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400, minHeight: 48),
                  child: FilledButton(
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
                                  price: _totalCents / 100,
                                ),
                              ),
                            );
                          }
                        : null,
                    style: kMowizFilledButtonStyle.copyWith(
                      textStyle: MaterialStatePropertyAll(TextStyle(fontSize: titleFont)),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(t('continue')),
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400, minHeight: 48),
                  child: FilledButton(
                    onPressed: () {
                      SoundHelper.playTap();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const MowizPayPage()),
                        (route) => false,
                      );
                    },
                    style: kMowizFilledButtonStyle.copyWith(
                      backgroundColor: MaterialStatePropertyAll(
                        Theme.of(context).colorScheme.secondary,
                      ),
                      textStyle: MaterialStatePropertyAll(TextStyle(fontSize: titleFont)),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(t('back')),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/* ───────────────  Widget para mostrar la lista de bloques  ─────────────── */
class _TariffList extends StatelessWidget {
  const _TariffList(this.map, {required this.font});
  final Map<int, int> map;
  final double font;

  @override
  Widget build(BuildContext context) {
    final entries = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return Column(
      children: entries
          .map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${e.key} min - ${(e.value / 100).toStringAsFixed(2)} €',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: font),
                  ),
                ),
              ))
          .toList(),
    );
  }
}
