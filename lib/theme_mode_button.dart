import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<ThemeProvider>(context);
    final isDark = prov.mode == ThemeMode.dark;
    return IconButton(
      iconSize: 32,
      color: Theme.of(context).colorScheme.primary,
      icon: Icon(isDark ? CupertinoIcons.sun_max_fill : CupertinoIcons.moon_fill),
      onPressed: prov.toggle,
    );
  }
}
