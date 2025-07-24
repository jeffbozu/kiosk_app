import 'package:flutter/material.dart';

/// Global MOWIZ theme using Material 3.
/// On Android 12+ you can integrate [dynamic_color]
/// to obtain a seed from the system palette.
ThemeData mowizTheme(BuildContext context) {
  const seed = Color(0xFF0066CC); // corporate color
  final light =
      ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
  final dark =
      ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);
  return ThemeData(
    useMaterial3: true,
    colorScheme: MediaQuery.of(context).platformBrightness == Brightness.dark
        ? dark
        : light,
    textTheme: Theme.of(context).textTheme.apply(fontSizeFactor: 1.2),
    visualDensity: VisualDensity.standard,
  );
}
