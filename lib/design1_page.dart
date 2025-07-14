import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'l10n/app_localizations.dart';
import 'language_selector.dart';
import 'theme_mode_button.dart';

class Design1Page extends StatefulWidget {
  const Design1Page({super.key});

  @override
  State<Design1Page> createState() => _Design1PageState();
}

class _Design1PageState extends State<Design1Page> {
  int _minutes = 1;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final until = now.add(Duration(minutes: _minutes));
    final dateFmt = DateFormat('EEE, d MMM, yyyy HH:mm', Intl.defaultLocale);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('design1Title')),
        actions: const [
          LanguageSelector(),
          SizedBox(width: 8),
          ThemeModeButton(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.t('selectZone'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            TextField(
              decoration: InputDecoration(
                labelText: l.t('zoneNumber'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.t('plate'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            TextField(
              decoration: InputDecoration(
                labelText: l.t('plateNumber'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.t('duration'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: CupertinoPicker(
                scrollController:
                    FixedExtentScrollController(initialItem: _minutes - 1),
                itemExtent: 32,
                selectionOverlay: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade200.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onSelectedItemChanged: (index) {
                  setState(() => _minutes = index + 1);
                },
                children: [
                  for (var i = 1; i <= 30; i++)
                    Center(child: Text('$i min')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.t('currentTime')),
                Text(dateFmt.format(now)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.t('finishTime')),
                Text(dateFmt.format(until)),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.t('payTapped'))),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text(l.t('pay')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
