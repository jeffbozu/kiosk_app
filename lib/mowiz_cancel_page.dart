import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';

class MowizCancelPage extends StatelessWidget {
  const MowizCancelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    return Scaffold(
      appBar: AppBar(title: Text(t('cancelDenuncia'))),
      body: const SizedBox.shrink(),
    );
  }
}
