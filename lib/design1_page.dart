import 'dart:ui';

import 'package:flutter/cupertino.dart';

import 'l10n/app_localizations.dart';

class Design1Page extends StatefulWidget {
  const Design1Page({super.key});

  @override
  State<Design1Page> createState() => _Design1PageState();
}

class _Design1PageState extends State<Design1Page> {
  final List<int> durations = const [5, 10, 15, 20, 25, 30, 45, 60];
  late int _minutes = durations.first;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l.t('design1')),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 280,
                  height: 180,
                  color: CupertinoColors.systemGrey.withOpacity(0.25),
                  child: CupertinoPicker(
                    itemExtent: 40,
                    onSelectedItemChanged: (i) {
                      setState(() => _minutes = durations[i]);
                    },
                    children: durations
                        .map((m) => Center(child: Text('$m ${l.t("min")}')))
                        .toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('${l.t("selected")}: $_minutes'),
          ],
        ),
      ),
    );
  }
}
