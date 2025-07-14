import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

import 'l10n/app_localizations.dart';
import 'language_selector.dart';
import 'theme_mode_button.dart';

class Design1Page extends StatelessWidget {
  const Design1Page({super.key});

  static const Map<String, dynamic> _fallback = {
    'title': 'Estacionamiento',
    'fields': ['Seleccionar Zona', 'Matrícula', 'Duración'],
    'dynamic_labels': ['Hora Actual', 'Hora de Finalización'],
    'button': 'Pagar'
  };

  Future<Map<String, dynamic>> _loadData() async {
    try {
      final jsonStr =
          await rootBundle.loadString('assets/design1/unnamed_metadata.json');
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return _fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadData(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? _fallback;
        final fields = List<String>.from(data['fields'] ?? []);
        final dyn = List<String>.from(data['dynamic_labels'] ?? []);

        final now = DateTime.now();
        final end = now.add(const Duration(hours: 1));

        return Scaffold(
          appBar: AppBar(
            title: Text(l.t('design1Title')),
            leading: BackButton(onPressed: () => Navigator.pop(context)),
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
                if (dyn.isNotEmpty)
                  Text(
                    '${l.t('currentTime')}: ${DateFormat.Hms().format(now)}',
                  ),
                const SizedBox(height: 8),
                if (fields.isNotEmpty)
                  TextField(
                    decoration:
                        InputDecoration(labelText: l.t('design1SelectZone')),
                  ),
                const SizedBox(height: 8),
                if (fields.length > 1)
                  TextField(
                    decoration: InputDecoration(labelText: l.t('plate')),
                  ),
                const SizedBox(height: 8),
                if (fields.length > 2)
                  TextField(
                    decoration: InputDecoration(labelText: l.t('duration')),
                  ),
                const SizedBox(height: 16),
                if (dyn.length > 1)
                  Text(
                    '${l.t('finishTime')}: ${DateFormat.Hms().format(end)}',
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {},
                  child: Text(l.t('pay')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
