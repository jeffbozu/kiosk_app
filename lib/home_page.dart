import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'payment_method_page.dart';
import 'language_selector.dart';
import 'locale_provider.dart';
import 'theme_mode_button.dart';
import 'ticket_success_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _firestore = FirebaseFirestore.instance;

  bool _loading = true, _saving = false;

  List<DropdownMenuItem<String>> _zoneItems = [];
  String? _selectedZoneId;

  int _selectedDuration = 0;
  int _minDuration = 0;
  int _maxDuration = 0;
  int _increment = 0;

  double _price = 0.0;
  double _basePrice = 0.0;
  double _extraBlockPrice = 0.0;

  final _plateCtrl = TextEditingController();

  String? _ticketId;
  DateTime? _paidUntil;

  DateTime _currentTime = DateTime.now();
  Timer? _clockTimer;
  bool _intlReady = false;

  StreamSubscription<DocumentSnapshot>? _tariffSubscription;

  late TimeOfDay _startTimeOfDay;
  late TimeOfDay _endTimeOfDay;

  bool _emergencyDialogVisible = false;

  bool _emergencyActive = false;
  String _emergencyReason = '';

  List<int> _validDays = [];

  @override
  void initState() {
    super.initState();
    _loadZones();

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _currentTime = DateTime.now());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Provider.of<LocaleProvider>(context).locale;
    final localeName = locale.languageCode == 'es'
        ? 'es_ES'
        : locale.languageCode == 'ca'
            ? 'ca_ES'
            : 'en_GB';
    if (Intl.defaultLocale != localeName) {
      Intl.defaultLocale = localeName;
      initializeDateFormatting(localeName, null).then((_) {
        if (mounted) setState(() => _intlReady = true);
      });
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _tariffSubscription?.cancel();
    _plateCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadZones() async {
    final snap = await _firestore.collection('tariffs').get();
    _zoneItems = snap.docs.map((doc) {
      final data = doc.data();
      return DropdownMenuItem(
        value: doc.id,
        child: Text(data['zoneId'] ?? doc.id),
      );
    }).toList();
    setState(() {
      _loading = false;
    });
  }

  void _subscribeTariff(String zoneDocId) {
    _tariffSubscription?.cancel();

    _tariffSubscription = _firestore
        .collection('tariffs')
        .doc(zoneDocId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;

      final data = doc.data()!;
      setState(() {
        _basePrice = (data['basePrice'] ?? 0).toDouble();
        _extraBlockPrice = (data['extraBlockPrice'] ?? 0).toDouble();
        _minDuration = (data['minDuration'] ?? 0) as int;
        _maxDuration = (data['maxDuration'] ?? 0) as int;
        _increment = (data['increment'] ?? 1) as int;

        _startTimeOfDay = _parseTimeOfDay(data['startTime'] ?? '00:00');
        _endTimeOfDay = _parseTimeOfDay(data['endTime'] ?? '23:59');

        _emergencyActive = (data['emergencyActive'] ?? false) as bool;
        _emergencyReason = (data['emergencyReason'] ?? '') as String;

        _validDays = List<int>.from(data['validDays'] ?? []);

        // Reset duration y precio base al cambiar tarifa
        _selectedDuration = _minDuration > 0 ? _minDuration : 0;
        _updatePrice();

        _paidUntil = _calculatePaidUntil();
      });
      if (_emergencyActive) {
        _showEmergencyDialog();
      }
    });
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  DateTime _todayAt(TimeOfDay tod, DateTime reference) {
    return DateTime(reference.year, reference.month, reference.day, tod.hour, tod.minute);
  }

  DateTimeRange _currentRange(DateTime now) {
    var start = _todayAt(_startTimeOfDay, now);
    var end = _todayAt(_endTimeOfDay, now);
    if (end.isBefore(start)) {
      if (now.isBefore(end)) {
        start = start.subtract(const Duration(days: 1));
      } else {
        end = end.add(const Duration(days: 1));
      }
    } else if (now.isBefore(start)) {
      start = start.subtract(const Duration(days: 1));
      end = _todayAt(_endTimeOfDay, start);
      if (end.isBefore(start)) end = end.add(const Duration(days: 1));
    }
    return DateTimeRange(start: start, end: end);
  }

  DateTime _calculatePaidUntil() {
    final now = DateTime.now();

    if (_emergencyActive) {
      // Emergencia activa, no permitir pagar
      return now;
    }

    // Validar si hoy está en validDays (lunes=1 .. domingo=7)
    // Firestore usa 1=lunes, 7=domingo. Dart usa weekday: 1=lunes ... 7=domingo
    final range = _currentRange(now);

    if (!_validDays.contains(range.start.weekday)) {
      return now;
    }

    if (now.isBefore(range.start)) {
      return range.start.add(Duration(minutes: _selectedDuration));
    }

    if (now.isAfter(range.end)) {
      final nextStart = range.start.add(const Duration(days: 1));
      return nextStart.add(Duration(minutes: _selectedDuration));
    }

    final paidUntil = now.add(Duration(minutes: _selectedDuration));
    if (paidUntil.isAfter(range.end)) {
      return range.end;
    }

    return paidUntil;
  }

  void _updatePrice() {
    if (_emergencyActive) {
      _price = 0.0;
      return;
    }
    if (_selectedDuration < _minDuration || _selectedDuration == 0) {
      _price = 0.0;
      return;
    }

    final blocks = ((_selectedDuration - _minDuration) / _increment).ceil();

    if (blocks <= 0) {
      _price = _basePrice;
    } else {
      _price = _basePrice + (_extraBlockPrice * blocks);
    }
  }

  bool get _isTariffActive {
    final now = DateTime.now();
    final range = _currentRange(now);
    return _validDays.contains(range.start.weekday) &&
        now.isAfter(range.start) &&
        now.isBefore(range.end);
  }

  void _increaseDuration() {
    if (_emergencyActive || !_isTariffActive) return;

    int nextDuration = _selectedDuration + _increment;
    if (nextDuration > _maxDuration) nextDuration = _maxDuration;

    setState(() {
      _selectedDuration = nextDuration;
      _updatePrice();
      _paidUntil = _calculatePaidUntil();
    });
  }

  void _decreaseDuration() {
    if (_emergencyActive || !_isTariffActive) return;

    int prevDuration = _selectedDuration - _increment;
    if (prevDuration < _minDuration) prevDuration = _minDuration;

    setState(() {
      _selectedDuration = prevDuration;
      _updatePrice();
      _paidUntil = _calculatePaidUntil();
    });
  }

  void _showEmergencyDialog() {
    if (_emergencyDialogVisible) return;
    _emergencyDialogVisible = true;
    int remaining = 5;
    Timer? timer;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
              if (remaining <= 1) {
                Navigator.of(ctx).pop();
              } else {
                setState(() => remaining--);
              }
            });
            return AlertDialog(
              title: const Text('Emergencia'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _emergencyReason,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text('Cerrando en \$remaining...'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      timer?.cancel();
      _emergencyDialogVisible = false;
    });
  }

  bool get _isPaymentAllowed {
    if (_emergencyActive) return false;
    if (!_isTariffActive) return false;
    if (_selectedDuration < _minDuration) return false;
    return true;
  }

  String get _paidUntilFormatted {
    if (_paidUntil == null) return '--:--';
    return '${_paidUntil!.hour.toString().padLeft(2, '0')}:${_paidUntil!.minute.toString().padLeft(2, '0')}';
  }

  String get _inactiveMessage {
    const names = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
    final days = _validDays.map((d) => names[d - 1]).join(', ');
    String fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return 'Esta tarifa solo está activa los días: $days, de ${fmt(_startTimeOfDay)} a ${fmt(_endTimeOfDay)}.';
  }

  Future<void> _onZoneChanged(String? zoneId) async {
    if (zoneId == null) return;

    setState(() {
      _selectedZoneId = zoneId;
      _price = 0.0;
      _selectedDuration = 0;
      _minDuration = 0;
      _maxDuration = 0;
      _increment = 0;
      _paidUntil = null;
      _plateCtrl.clear();
      _emergencyActive = false;
      _emergencyReason = '';
      _validDays = [];
      _startTimeOfDay = const TimeOfDay(hour: 0, minute: 0);
      _endTimeOfDay = const TimeOfDay(hour: 23, minute: 59);
    });

    _subscribeTariff(zoneId);
  }

  Future<void> _confirmAndPay() async {
    if (!_isPaymentAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).t('paymentNotAllowed'))),
      );
      return;
    }

    if (_selectedZoneId == null) return;

    final matricula = _plateCtrl.text.trim().toUpperCase();

    if (matricula.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).t('plateRequired'))),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).t('correctPlate')),
        content: Text(matricula),
        actions: [
          TextButton(
            style: TextButton.styleFrom(backgroundColor: const Color(0xFF7F7F7F)),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context).t('no')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context).t('yes')),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaymentMethodPage(
          zoneId: _selectedZoneId!,
          plate: matricula,
          duration: _selectedDuration,
          price: _price,
        ),
      ),
    );

    if (paid != true) return;

    setState(() {
      _saving = true;
      _ticketId = null;
    });

    final now = DateTime.now();
    final paidUntil = _paidUntil ?? now.add(Duration(minutes: _selectedDuration));
    final doc = await _firestore.collection('tickets').add({
      'zoneId': _selectedZoneId,
      'plate': matricula,
      'paidUntil': Timestamp.fromDate(paidUntil),
      'status': 'paid',
      'price': _price,
      'duration': _selectedDuration,
    });

    _paidUntil = paidUntil;
    _ticketId = doc.id;
    setState(() => _saving = false);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TicketSuccessPage(ticketId: _ticketId!),
      ),
    );

    setState(() {
      _ticketId = null;
      _plateCtrl.clear();
      _selectedDuration = _minDuration;
      _paidUntil = _calculatePaidUntil();
      _updatePrice();
    });
  }

  @override
  Widget build(BuildContext context) {
    final allReady = !_saving &&
        _selectedZoneId != null &&
        _plateCtrl.text.trim().isNotEmpty &&
        _isPaymentAllowed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiosk App'),
        actions: const [
          LanguageSelector(),
          SizedBox(width: 8),
          ThemeModeButton(),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFFE62144)),
                      const SizedBox(width: 8),
                      Text(
                        _intlReady
                            ? DateFormat('EEEE, d MMM y • HH:mm:ss', Intl.defaultLocale)
                                .format(_currentTime)
                            : '',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).t('zone')),
                    items: _zoneItems,
                    value: _selectedZoneId,
                    hint: Text(AppLocalizations.of(context).t('chooseZone')),
                    onChanged: _onZoneChanged,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _plateCtrl,
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).t('plate')),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  if (_emergencyActive) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Colors.red.shade300,
                      child: Text(
                        _emergencyReason,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ] else if (!_isTariffActive && _selectedZoneId != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4CC),
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _inactiveMessage,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _emergencyActive || !_isTariffActive ? null : _decreaseDuration,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _emergencyActive || !_isTariffActive
                              ? Colors.grey
                              : const Color(0xFFE62144),
                          minimumSize: const Size(40, 40),
                        ),
                        child: const Icon(Icons.remove, color: Colors.white),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _selectedDuration > 0
                              ? '$_selectedDuration min'
                              : '-- min',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _emergencyActive || !_isTariffActive ? null : _increaseDuration,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _emergencyActive || !_isTariffActive
                              ? Colors.grey
                              : const Color(0xFFE62144),
                          minimumSize: const Size(40, 40),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${AppLocalizations.of(context).t('price')}: ${_intlReady ? NumberFormat.currency(
                          symbol: '€', locale: Intl.defaultLocale, decimalDigits: 2
                        ).format(_price) : _price.toStringAsFixed(2) + ' €'}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${AppLocalizations.of(context).t('until')}: $_paidUntilFormatted',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: allReady ? _confirmAndPay : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          allReady ? const Color(0xFFE62144) : Colors.grey,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            AppLocalizations.of(context).t('pay'),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
