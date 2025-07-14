import 'package:fluent_ui/fluent_ui.dart';
import 'l10n/app_localizations.dart';

class DesignWinPage extends StatelessWidget {
  const DesignWinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      content: const DesignWinBody(),
    );
  }
}

class DesignWinBody extends StatefulWidget {
  const DesignWinBody({super.key});

  @override
  State<DesignWinBody> createState() => _DesignWinBodyState();
}

class _DesignWinBodyState extends State<DesignWinBody> {
  final List<int> durations = const [5, 10, 15, 20, 25, 30, 45, 60];
  late int _minutes = durations.first;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ScaffoldPage(
      header: PageHeader(title: Text(l.t('designWin'))),
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TimePicker(
            header: Text(l.t('duration')),
            startHour: 0,
            endHour: 0,
            minuteInterval: 5,
            selected: TimeOfDay(hour: 0, minute: _minutes),
            onChanged: (t) {
              setState(() => _minutes = t.minute);
            },
          ),
          const SizedBox(height: 16),
          Text('${_minutes} ${l.t('min')}'),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: ListWheelScrollView.useDelegate(
              itemExtent: 40,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (i) =>
                  setState(() => _minutes = durations[i]),
              childDelegate: ListWheelChildLoopingListDelegate(
                children: durations
                    .map((m) => Center(child: Text('$m ${l.t('min')}')))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
