import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'mowiz_page.dart';

class MowizSuccessPage extends StatelessWidget {
  const MowizSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    return Scaffold(
      appBar: AppBar(title: Text(t('paymentSuccess'))),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MowizPage()),
              (route) => false,
            );
          },
          child: Text(t('goHome')),
        ),
      ),
    );
  }
}
