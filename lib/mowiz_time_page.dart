import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
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

    Widget btn(String label, int min) => Expanded(
          child: ElevatedButton(
            style: kMowizFilledButtonStyle,
            onPressed: () {
              SoundHelper.playTap();
              _change(min);
            },
            child: AutoSizeText(label, maxLines: 1),
          ),
        );

    return MowizScaffold(
      title: 'MeyPark - ${t('selectDuration')}',
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AutoSizeText(
              DateFormat('EEE, d MMM yyyy - HH:mm', locale).format(_now),
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(children: [btn('+3', 3), const SizedBox(width: 12), btn('+5', 5), const SizedBox(width: 12), btn('+15', 15)]),
            const SizedBox(height: 12),
            Row(children: [btn('-3', -3), const SizedBox(width: 12), btn('-5', -5), const SizedBox(width: 12), btn('-15', -15)]),
            const SizedBox(height: 24),
            AutoSizeText('${minutes ~/ 60}h ${minutes % 60}m',
                textAlign: TextAlign.center,
                maxLines: 1,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            AutoSizeText('${t('price')}: $priceStr',
                textAlign: TextAlign.center,
                maxLines: 1,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            AutoSizeText('${t('until')}: ${DateFormat('HH:mm', locale).format(finish)}',
                textAlign: TextAlign.center,
                maxLines: 1,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_tariffLoaded) _TariffList(_stepsMap) else const CircularProgressIndicator(),
            const Spacer(),
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
                            price: _totalCents / 100,
                          ),
                        ),
                      );
                    }
                  : null,
              style: kMowizFilledButtonStyle,
              child: AutoSizeText(t('continue'), maxLines: 1),
            ),
            const SizedBox(height: 12),
            FilledButton(
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
              ),
              child: AutoSizeText(t('back'), maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}

/* ───────────────  Widget para mostrar la lista de bloques  ─────────────── */
class _TariffList extends StatelessWidget {
  const _TariffList(this.map);
  final Map<int, int> map;

  @override
  Widget build(BuildContext context) {
    final entries = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return Column(
      children: entries
          .map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: AutoSizeText(
                  '${e.key} min - ${(e.value / 100).toStringAsFixed(2)} €',
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ))
          .toList(),
    );
  }
}
