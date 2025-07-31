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

  Map<int, int> _stepsMap = {};
  List<int> _blocks = [];
  int? _maxDuration;
  bool _tariffLoaded = false;

  Map<int, int> _bloques = {};
  int _totalSec = 0;
  int _totalCents = 0;

  Future<void> _loadTariff() async {
    setState(() {
      _stepsMap.clear();
      _blocks = [];
      _maxDuration = null;
      _bloques.clear();
      _totalSec = 0;
      _totalCents = 0;
      _tariffLoaded = false;
    });

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
          _blocks = _stepsMap.keys.toList()..sort();
          _bloques = {for (final b in _blocks) b: 0};
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

  void _add(int minutos) {
    if (!_tariffLoaded || !_stepsMap.containsKey(minutos)) return;

    final cents = _stepsMap[minutos]!;
    final nextSec = _totalSec + minutos * 60;
    final nextCents = _totalCents + cents;

    if (_maxDuration != null && nextSec > _maxDuration!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duración máxima alcanzada')),
      );
      return;
    }

    setState(() {
      _totalSec = nextSec;
      _totalCents = nextCents;
      _bloques[minutos] = (_bloques[minutos] ?? 0) + 1;
    });
  }

  void _reset() {
    setState(() {
      _totalSec = 0;
      _totalCents = 0;
      _bloques = {for (final b in _blocks) b: 0};
    });
  }

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

  String _formatMin(int min) {
    if (min % 60 == 0 && min >= 60) {
      final h = min ~/ 60;
      return "$h${h == 1 ? 'h' : 'h'}";
    }
    return "$min min";
  }

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

    Widget btn(String label, int min, double fontSize, double btnHeight) => SizedBox(
          width: double.infinity,
          height: btnHeight,
          child: ElevatedButton(
            style: kMowizFilledButtonStyle.copyWith(
              textStyle: MaterialStatePropertyAll(TextStyle(fontSize: fontSize)),
            ),
            onPressed: () {
              SoundHelper.playTap();
              _add(min);
            },
            child: AutoSizeText(label, maxLines: 1, minFontSize: 13),
          ),
        );

    return MowizScaffold(
      title: 'MeyPark - ${t('selectDuration')}',
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            const double maxContentWidth = 500;
            final double contentWidth = width > maxContentWidth ? maxContentWidth : width;

            final double gap = 16;
            final double fontSz = 18;
            final double labelSz = 16;
            final double mainValueSz = 26;
            final double btnHeight = 46;

            // Centrar contenido siempre
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxContentWidth,
                  minWidth: 260,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: contentWidth * 0.05, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AutoSizeText(
                        DateFormat('EEE, d MMM yyyy - HH:mm', locale).format(_now),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(fontSize: labelSz, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: gap),
                      if (_tariffLoaded) ...[
                        // Botones de suma dinámicos
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: gap,
                          runSpacing: gap,
                          children: _blocks
                              .map((b) => SizedBox(
                                    width: 120,
                                    child: btn("+${_formatMin(b)}", b, fontSz, btnHeight),
                                  ))
                              .toList(),
                        ),
                        SizedBox(height: gap),
                        // Botón borrar
                        Center(
                          child: SizedBox(
                            width: 150,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.delete_outline),
                              label: AutoSizeText(
                                t('clear') ?? 'Borrar',
                                maxLines: 1,
                                minFontSize: 13,
                              ),
                              style: kMowizFilledButtonStyle.copyWith(
                                backgroundColor: MaterialStatePropertyAll(Colors.grey.shade400),
                                textStyle: MaterialStatePropertyAll(TextStyle(fontSize: fontSz)),
                              ),
                              onPressed: _totalSec > 0 ? () {
                                SoundHelper.playTap();
                                _reset();
                              } : null,
                            ),
                          ),
                        ),
                      ]
                      else
                        const Center(child: CircularProgressIndicator()),
                      SizedBox(height: gap * 1.1),
                      AutoSizeText(
                        '${minutes ~/ 60}h ${minutes % 60}m',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(fontSize: mainValueSz, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 6),
                      AutoSizeText(
                        '${t('price')}: $priceStr',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(fontSize: labelSz, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 6),
                      AutoSizeText(
                        '${t('until')}: ${DateFormat('HH:mm', locale).format(finish)}',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(fontSize: labelSz, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      if (_tariffLoaded)
                        _TariffList(_stepsMap, fontSz, formatMin: _formatMin)
                      else
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      SizedBox(height: 16),
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
                        style: kMowizFilledButtonStyle.copyWith(
                          minimumSize: MaterialStatePropertyAll(Size(double.infinity, btnHeight + 10)),
                          textStyle: MaterialStatePropertyAll(TextStyle(fontSize: fontSz)),
                        ),
                        child: AutoSizeText(t('continue'), maxLines: 1, minFontSize: 14),
                      ),
                      SizedBox(height: 10),
                      FilledButton(
                        onPressed: () {
                          SoundHelper.playTap();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const MowizPayPage()),
                            (route) => false,
                          );
                        },
                        style: kMowizFilledButtonStyle.copyWith(
                          minimumSize: MaterialStatePropertyAll(Size(double.infinity, btnHeight + 4)),
                          backgroundColor: MaterialStatePropertyAll(
                            Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        child: AutoSizeText(t('back'), maxLines: 1, minFontSize: 14),
                      ),
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
}

// Tarifa lista con formato en h/min
class _TariffList extends StatelessWidget {
  const _TariffList(this.map, this.fontSz, {required this.formatMin});
  final Map<int, int> map;
  final double fontSz;
  final String Function(int) formatMin;

  @override
  Widget build(BuildContext context) {
    final entries = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return Column(
      children: entries
          .map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: AutoSizeText(
                  '${formatMin(e.key)} - ${(e.value / 100).toStringAsFixed(2)} €',
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: fontSz - 3),
                ),
              ))
          .toList(),
    );
  }
}
