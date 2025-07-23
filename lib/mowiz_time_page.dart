import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'l10n/app_localizations.dart';
import 'mowiz_page.dart';
import 'mowiz_summary_page.dart';

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
  int _minutes = 0;
  // TODO: define maxDuration from tariff or business logic
  final int _maxDuration = 24 * 60; // placeholder for max duration in minutes

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _modifyMinutes(int delta) {
    setState(() {
      _minutes += delta;
      if (_minutes < 0) _minutes = 0;
      if (_minutes > _maxDuration) _minutes = _maxDuration; // maxDuration limit
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final locale = AppLocalizations.of(context).locale.languageCode == 'es'
        ? 'es_ES'
        : AppLocalizations.of(context).locale.languageCode == 'ca'
            ? 'ca_ES'
            : 'en_GB';

    final finish = _now.add(Duration(minutes: _minutes));
    final durationStr = '${_minutes ~/ 60}h ${_minutes % 60}m';
    final price = 0.0; // TODO: calculate real price

    return Scaffold(
      appBar: AppBar(title: Text(t('selectDuration'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              DateFormat('EEE, d MMM yyyy - HH:mm', locale).format(_now),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _modifyMinutes(3),
                    child: const Text('+3'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _modifyMinutes(5),
                    child: const Text('+5'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _modifyMinutes(15),
                    child: const Text('+15'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _modifyMinutes(-3),
                    child: const Text('-3'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _modifyMinutes(-5),
                    child: const Text('-5'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _modifyMinutes(-15),
                    child: const Text('-15'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              durationStr,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              '${t('price')}: ${price.toStringAsFixed(2)} €',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              '${t('until')}: ${DateFormat('HH:mm', locale).format(finish)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // TODO: navigate to summary & payment page with selected data
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MowizSummaryPage(),
                  ),
                );
              },
              child: Text(t('continue')),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MowizPage()),
                  (route) => false,
                );
              },
              child: Text(t('cancel')),
            ),
          ],
        ),
      ),
    );
  }
}
