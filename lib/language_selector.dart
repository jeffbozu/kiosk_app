import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'locale_provider.dart';
import 'flag_images.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<LocaleProvider>(context);
    return Row(
      children: [
        _flagButton(context, 'es', flagEs),
        const SizedBox(width: 8),
        _flagButton(context, 'ca', flagCt),
        const SizedBox(width: 8),
        _flagButton(context, 'en', flagUk),
      ],
    );
  }

  Widget _flagButton(BuildContext context, String code, Uint8List bytes) {
    final prov = Provider.of<LocaleProvider>(context, listen: false);
    return GestureDetector(
      onTap: () => prov.setLocale(Locale(code)),
      child: Image.memory(bytes, width: 32, height: 24),
    );
  }
}
