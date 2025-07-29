import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import 'l10n/app_localizations.dart';
import 'mowiz_page.dart';
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
  Timer? _timer;
  // TODO: max duration will come from backend

  List<dynamic>? _tariffData;
  // TODO: added state variables for dynamic pricing and duration
  Map<int, int> _stepsMap = {}; // minutes -> price in cents
  int? _maxDurationSeconds;
  int totalSeconds = 0;
  int totalPriceCents = 0;
  // TODO: end added state variables

  Future<void> _fetchTariff() async {
    final url =
        'http://localhost:3000/v1/onstreet-service/product/by-zone/${widget.zone}&plate=${widget.plate}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        debugPrint('Tariff response: $data');
        // TODO: map steps and max duration from backend response
        if (data.isNotEmpty) {
          final first = data.first as Map<String, dynamic>;
          final rate = first['rateSteps'] as Map<String, dynamic>?;
          final steps = rate?['steps'] as List<dynamic>? ?? [];
          _stepsMap = {
            for (final s in steps)
              ((s['timeInSeconds'] as int? ?? 0) ~/ 60):
                  (s['priceInCents'] as int? ?? 0)
          };
          _maxDurationSeconds = rate?['maxDurationSeconds'] as int?;
        }
        setState(() => _tariffData = data);
        // TODO: end map steps and max duration
      } else {
        debugPrint('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching tariff: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
    _fetchTariff();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _modifyMinutes(int delta) {
    // TODO: handle increment/decrement of selected time and price
    final deltaSeconds = delta * 60;
    final priceBlock = _stepsMap[delta.abs()] ?? 0;
    final newSeconds = totalSeconds + deltaSeconds;

    if (_maxDurationSeconds != null && newSeconds > _maxDurationSeconds!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duración máxima alcanzada')),
      );
      return;
    }

    setState(() {
      totalSeconds = newSeconds.clamp(0, _maxDurationSeconds ?? newSeconds);
      final newPrice = totalPriceCents + (delta.isNegative ? -priceBlock : priceBlock);
      totalPriceCents = newPrice < 0 ? 0 : newPrice;
    });
    // TODO: end handle increment/decrement
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final locale = AppLocalizations.of(context).locale.languageCode == 'es'
        ? 'es_ES'
        : AppLocalizations.of(context).locale.languageCode == 'ca'
            ? 'ca_ES'
            : 'en_GB';

    // TODO: calculate finish time, duration and formatted price from totals
    final minutes = totalSeconds ~/ 60;
    final finish = _now.add(Duration(seconds: totalSeconds));
    final durationStr = '${minutes ~/ 60}h ${minutes % 60}m';
    final priceStr = NumberFormat.currency(locale: 'es_ES', symbol: '€')
        .format(totalPriceCents / 100);
    // TODO: end calculate finish time, duration and formatted price

    return MowizScaffold(
      title: t('selectDuration'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isLargeTablet = width >= 900;
          final isTablet = width >= 600 && width < 900;
          final padding = EdgeInsets.all(width * 0.05);
          final double gap = width * 0.04;
          final double titleFont = isLargeTablet
              ? 32
              : isTablet
                  ? 28
                  : 24;
          final double bigFont = isLargeTablet
              ? 40
              : isTablet
                  ? 36
                  : 32;
          final double btnFont = isLargeTablet
              ? 28
              : isTablet
                  ? 24
                  : 20;

          final ButtonStyle timeButtonStyle = ElevatedButton.styleFrom(
            textStyle: TextStyle(fontSize: btnFont),
          ).copyWith(
            overlayColor: MaterialStateProperty.resolveWith(
              (states) => states.contains(MaterialState.pressed)
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                  : null,
            ),
          );

          Widget timeBtn(String text, int delta) => Expanded(
                child: ElevatedButton(
                  style: timeButtonStyle,
                  onPressed: () {
                    SoundHelper.playTap();
                    _modifyMinutes(delta);
                  },
                  child: AutoSizeText(text, maxLines: 1),
                ),
              );

          return Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AutoSizeText(
                  DateFormat('EEE, d MMM yyyy - HH:mm', locale).format(_now),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: titleFont, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: gap),
                Row(
                  children: [
                    timeBtn('+3', 3),
                    SizedBox(width: gap),
                    timeBtn('+5', 5),
                    SizedBox(width: gap),
                    timeBtn('+15', 15),
                  ],
                ),
                SizedBox(height: gap),
                Row(
                  children: [
                    timeBtn('-3', -3),
                    SizedBox(width: gap),
                    timeBtn('-5', -5),
                    SizedBox(width: gap),
                    timeBtn('-15', -15),
                  ],
                ),
                SizedBox(height: gap),
                AutoSizeText(
                  durationStr,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: bigFont, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: gap / 2),
                AutoSizeText(
                  '${t('price')}: $priceStr',
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: titleFont, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: gap / 2),
                AutoSizeText(
                  '${t('until')}: ${DateFormat('HH:mm', locale).format(finish)}',
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: titleFont, fontWeight: FontWeight.bold),
                ),
                if (_tariffData != null) ...[
                  SizedBox(height: gap),
                  _RateStepsList(_tariffData!, titleFont: titleFont),
                ],
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    SoundHelper.playTap();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MowizSummaryPage(
                          plate: widget.plate,
                          zone: widget.zone,
                          start: _now,
                          minutes: minutes,
                          price: totalPriceCents / 100,
                        ),
                      ),
                    );
                  },
                  style: kMowizFilledButtonStyle.copyWith(
                    textStyle:
                        MaterialStatePropertyAll(TextStyle(fontSize: titleFont)),
                  ),
                  child: AutoSizeText(t('continue'), maxLines: 1),
                ),
                SizedBox(height: gap),
                FilledButton(
                  onPressed: () {
                    SoundHelper.playTap();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const MowizPage()),
                      (route) => false,
                    );
                  },
                  style: kMowizFilledButtonStyle.copyWith(
                    backgroundColor: MaterialStatePropertyAll(
                      Theme.of(context).colorScheme.secondary,
                    ),
                    textStyle:
                        MaterialStatePropertyAll(TextStyle(fontSize: titleFont)),
                  ),
                  child: AutoSizeText(t('cancel'), maxLines: 1),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RateStepsList extends StatelessWidget {
  const _RateStepsList(this.data, {required this.titleFont});

  final List<dynamic> data;
  final double titleFont;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final steps = (data.first['rateSteps']?['steps'] as List<dynamic>? ?? []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: steps.map((step) {
        final seconds = step['timeInSeconds'] as int? ?? 0;
        final price = step['priceInCents'] as int? ?? 0;
        final mins = (seconds / 60).round();
        final euros = (price / 100).toStringAsFixed(2);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: AutoSizeText(
            '$mins min - $euros €',
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: titleFont),
          ),
        );
      }).toList(),
    );
  }
}
