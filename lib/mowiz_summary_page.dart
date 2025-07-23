import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';

class MowizSummaryPage extends StatelessWidget {
  const MowizSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    return Scaffold(
      appBar: AppBar(title: Text(t('summaryPay'))),
      body: const Center(child: Text('TODO')),
    );
  }
}
