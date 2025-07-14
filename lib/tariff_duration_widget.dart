import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'l10n/app_localizations.dart';

/// Widget que permite seleccionar la duración de aparcamiento
/// gestionando los límites de horario y días válidos.
class TariffDurationWidget extends StatefulWidget {
  const TariffDurationWidget({
    super.key,
    required this.minDuration,
    required this.maxDuration,
    required this.increment,
    required this.basePrice,
    required this.extraBlockPrice,
    required this.startTime,
    required this.endTime,
    required this.validDays,
    required this.emergencyActive,
    required this.emergencyReasonKey,
  });

  /// Duración mínima permitida en minutos.
  final int minDuration;

  /// Duración máxima permitida en minutos.
  final int maxDuration;

  /// Incremento de minutos al pulsar el botón "+".
  final int increment;

  /// Precio base a partir de [minDuration].
  final double basePrice;

  /// Precio extra por cada bloque adicional según [increment].
  final double extraBlockPrice;

  /// Hora de inicio de la tarifa en formato HH:mm.
  final String startTime;

  /// Hora de fin de la tarifa en formato HH:mm.
  final String endTime;

  /// Días de la semana hábiles (1=lunes .. 7=domingo).
  final List<int> validDays;

  /// Indica si la tarifa está en modo emergencia.
  final bool emergencyActive;

  /// Clave de localización para el motivo de la emergencia.
  final String emergencyReasonKey;

  @override
  State<TariffDurationWidget> createState() => _TariffDurationWidgetState();
}

class _TariffDurationWidgetState extends State<TariffDurationWidget> {
  late DateTime _startTime;
  late DateTime _endTime;

  int _selectedDuration = 0;
  double _price = 0;
  DateTime? _paidUntil;

  bool _dialogShown = false;
  Timer? _countdownTimer;
  int _countdown = 5;

  @override
  void initState() {
    super.initState();
    _startTime = _parseTime(widget.startTime);
    _endTime = _parseTime(widget.endTime, endTime: true);
    _selectedDuration = widget.minDuration;
    _updateValues();

    if (widget.emergencyActive) {
      // Mostrar el diálogo después de construir para evitar errores de contexto.
      WidgetsBinding.instance.addPostFrameCallback((_) => _showEmergencyDialog());
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Parsea una hora en formato "HH:mm" y la ajusta al día actual.
  DateTime _parseTime(String time, {bool endTime = false}) {
    final now = DateTime.now();
    final parts = time.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    DateTime result = DateTime(now.year, now.month, now.day, h, m);
    if (endTime && result.isBefore(_startTime)) {
      // Si la hora de fin es menor que la de inicio, pertenece al siguiente día.
      result = result.add(const Duration(days: 1));
    }
    return result;
  }

  /// Devuelve la hora de fin de sesión para el día de [base].
  DateTime _sessionEndFor(DateTime base) {
    DateTime end = DateTime(base.year, base.month, base.day, _endTime.hour, _endTime.minute);
    DateTime start = DateTime(base.year, base.month, base.day, _startTime.hour, _startTime.minute);
    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }
    return end;
  }

  /// Calcula la hora de inicio válida más próxima según la configuración.
  DateTime _calculateBaseStart() {
    final now = DateTime.now();
    if (widget.emergencyActive) return now;

    // Buscar día válido si hoy no lo es.
    if (!widget.validDays.contains(now.weekday)) {
      int days = 1;
      while (!widget.validDays.contains(now.add(Duration(days: days)).weekday)) {
        days++;
      }
      final next = now.add(Duration(days: days));
      return DateTime(next.year, next.month, next.day, _startTime.hour, _startTime.minute);
    }

    // Si estamos antes del horario de inicio, comenzar a esa hora.
    if (now.isBefore(_startTime)) {
      return DateTime(now.year, now.month, now.day, _startTime.hour, _startTime.minute);
    }

    // Si ya se pasó el horario de fin, saltar al siguiente día válido.
    if (now.isAfter(_endTime)) {
      int days = 1;
      while (!widget.validDays.contains(now.add(Duration(days: days)).weekday)) {
        days++;
      }
      final next = now.add(Duration(days: days));
      return DateTime(next.year, next.month, next.day, _startTime.hour, _startTime.minute);
    }

    return now;
  }

  /// Calcula la fecha y hora hasta la que se pagará tras [duration] minutos.
  DateTime _calculatePaidUntil(int duration) {
    final base = _calculateBaseStart();
    final sessionEnd = _sessionEndFor(base);
    final candidate = base.add(Duration(minutes: duration));
    if (candidate.isAfter(sessionEnd)) {
      // Si se supera el fin de sesión, avanzar al próximo día válido a la hora de inicio.
      DateTime nextDay = base.add(const Duration(days: 1));
      while (!widget.validDays.contains(nextDay.weekday)) {
        nextDay = nextDay.add(const Duration(days: 1));
      }
      return DateTime(nextDay.year, nextDay.month, nextDay.day, _startTime.hour, _startTime.minute);
    }
    return candidate;
  }

  /// Indica si es posible incrementar la duración sin sobrepasar límites.
  bool _canIncrease() {
    final nextDuration = _selectedDuration + widget.increment;
    if (nextDuration > widget.maxDuration) return false;
    final base = _calculateBaseStart();
    final sessionEnd = _sessionEndFor(base);
    final candidate = base.add(Duration(minutes: nextDuration));
    return !candidate.isAfter(sessionEnd);
  }

  /// Indica si es posible reducir la duración respetando el mínimo.
  bool _canDecrease() {
    return _selectedDuration - widget.increment >= widget.minDuration;
  }

  /// Actualiza precio y fecha al modificar la duración.
  void _updateValues() {
    _paidUntil = _calculatePaidUntil(_selectedDuration);

    if (widget.emergencyActive || _selectedDuration < widget.minDuration) {
      _price = 0;
      return;
    }

    final extraBlocks = ((_selectedDuration - widget.minDuration) / widget.increment).ceil();
    _price = widget.basePrice + (extraBlocks > 0 ? extraBlocks * widget.extraBlockPrice : 0);
  }

  void _increase() {
    if (!_canIncrease()) return;
    setState(() {
      _selectedDuration += widget.increment;
      _updateValues();
    });
  }

  void _decrease() {
    if (!_canDecrease()) return;
    setState(() {
      _selectedDuration -= widget.increment;
      _updateValues();
    });
  }

  void _showEmergencyDialog() {
    if (_dialogShown) return;
    _dialogShown = true;
    _countdown = 5;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        if (Navigator.canPop(context)) Navigator.pop(context);
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        final l = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l.t('emergencyTitle')),
          content: Text(l.t(widget.emergencyReasonKey)),
          actions: [
            TextButton(
              onPressed: () {
                _countdownTimer?.cancel();
                Navigator.pop(context);
              },
              child: Text(l.t('close')),
            ),
          ],
        );
      },
    ).then((_) {
      _countdownTimer?.cancel();
      _countdownTimer = null;
      _dialogShown = false;
    });
  }

  String _formatPaidUntil() {
    if (_paidUntil == null) return '--:--';
    return DateFormat('dd/MM/yyyy HH:mm').format(_paidUntil!);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final canAdd = _canIncrease();
    final canSub = _canDecrease();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.emergencyActive)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.redAccent,
            child: Text(
              l.t(widget.emergencyReasonKey),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: canSub ? _decrease : null,
              icon: const Icon(Icons.remove),
            ),
            Text('$_selectedDuration min', style: const TextStyle(fontSize: 16)),
            IconButton(
              onPressed: canAdd ? _increase : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('${l.t('price')}: ${_price.toStringAsFixed(2)} €'),
        Text('${l.t('until')}: ${_formatPaidUntil()}'),
      ],
    );
  }
}
