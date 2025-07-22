import 'package:flutter/material.dart';
import 'language_selector.dart';
import 'theme_mode_button.dart';

class MowizPage extends StatelessWidget {
  const MowizPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulador MOWIZ'),
        actions: const [
          LanguageSelector(),
          SizedBox(width: 8),
          ThemeModeButton(),
        ],
      ),
      body: const SizedBox.shrink(),
    );
  }
}
