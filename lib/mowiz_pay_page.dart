import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';

class MowizPayPage extends StatelessWidget {
  const MowizPayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    return Scaffold(
      appBar: AppBar(title: Text(t('payTicket'))),
      body: const SizedBox.shrink(),
    );
  }
}
