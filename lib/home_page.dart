import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
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

  int _selectedDuration = 0; // inicial 0 min hasta seleccionar zona
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

  // Para escuchar cambios de tarifa en tiempo real
  StreamSubscription<DocumentSnapshot>? _tariffSubscription;

  // Campos para horario
  late DateTime _startTime;
  late DateTime _endTime;

  @override
  void initState() {
    super.initState();
    _loadZones();

    // Timer para actualizar reloj UI cada segundo
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

  // Escucha tarifa en tiempo real para la zona seleccionada
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

        // Parsear startTime y endTime strings a DateTime relativos a hoy
        _startTime = _parseTime(data['startTime'] ?? '00:00');
        _endTime = _parseTime(data['endTime'] ?? '23:59');

        // Resetea duración y precio a valores base
        _selectedDuration = _minDuration > 0 ? _minDuration : 0;
        _updatePrice();

        // Actualiza hora pagada
        _paidUntil = _calculatePaidUntil();
      });
    });
  }

  DateTime _parseTime(String time) {
    final now = DateTime.now();
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  DateTime _calculatePaidUntil() {
    final now = DateTime.now();

    // Si ahora es antes del horario de inicio, la hora pagada comienza en startTime
    if (now.isBefore(_startTime)) {
      return _startTime.add(Duration(minutes: _selectedDuration));
    }

    // Si ahora es después de endTime, la hora pagada comienza startTime del día siguiente
    if (now.isAfter(_endTime)) {
      final nextDayStart = _startTime.add(const Duration(days: 1));
      return nextDayStart.add(Duration(minutes: _selectedDuration));
    }

    // Si estamos dentro del horario permitido, sumamos duración a la hora actual
    final paidUntil = now.add(Duration(minutes: _selectedDuration));

    // Si la suma pasa de endTime, limitar a endTime
    if (paidUntil.isAfter(_endTime)) {
      return _endTime;
    }

    return paidUntil;
  }

  void _updatePrice() {
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

  void _increaseDuration() {
    int nextDuration = _selectedDuration + _increment;

    // Limitar a maxDuration
    if (nextDuration > _maxDuration) nextDuration = _maxDuration;

    setState(() {
      _selectedDuration = nextDuration;
      _updatePrice();
      _paidUntil = _calculatePaidUntil();
    });
  }

  void _decreaseDuration() {
    int prevDuration = _selectedDuration - _increment;

    // Limitar a minDuration
    if (prevDuration < _minDuration) prevDuration = _minDuration;

    setState(() {
      _selectedDuration = prevDuration;
      _updatePrice();
      _paidUntil = _calculatePaidUntil();
    });
  }

  String get _paidUntilFormatted {
    if (_paidUntil == null) return '--:--';
    return '${_paidUntil!.hour.toString().padLeft(2, '0')}:${_paidUntil!.minute.toString().padLeft(2, '0')}';
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
    });

    _subscribeTariff(zoneId);
  }

  Future<void> _confirmAndPay() async {
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
        _selectedDuration >= _minDuration &&
        _selectedDuration <= _maxDuration;

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _decreaseDuration,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE62144),
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
                        onPressed: _increaseDuration,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE62144),
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
