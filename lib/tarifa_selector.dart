import 'package:flutter/material.dart';

class TarifaSelector extends StatefulWidget {
  final List<Map<String, dynamic>> rateSteps;
  final ValueChanged<Map<String, dynamic>> onSelected;

  const TarifaSelector({
    Key? key,
    required this.rateSteps,
    required this.onSelected,
  }) : super(key: key);

  @override
  State<TarifaSelector> createState() => _TarifaSelectorState();
}

class _TarifaSelectorState extends State<TarifaSelector> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(covariant TarifaSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rateSteps != widget.rateSteps) {
      _selectedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (int i = 0; i < widget.rateSteps.length; i++)
          _buildChip(i, widget.rateSteps[i]),
      ],
    );
  }

  Widget _buildChip(int index, Map<String, dynamic> step) {
    final durationSeconds = step['durationInSeconds'] as int? ?? 0;
    final priceCents = step['priceInCents'] as int? ?? 0;
    final endDateTimeStr = step['endDateTime'] as String? ?? '';
    final minutes = durationSeconds ~/ 60;
    final price = priceCents / 100.0;
    DateTime? endDateTime;
    try {
      endDateTime = DateTime.parse(endDateTimeStr);
    } catch (_) {}
    final formattedHour = endDateTime != null
        ? '${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}'
        : '--:--';
    final label = '$minutes min - ${price.toStringAsFixed(2)} € - Hasta $formattedHour';

    return ChoiceChip(
      label: Text(label),
      selected: _selectedIndex == index,
      onSelected: (_) {
        setState(() => _selectedIndex = index);
        widget.onSelected(step);
      },
    );
  }
}
