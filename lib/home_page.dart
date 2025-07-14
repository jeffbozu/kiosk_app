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
  // ──────────── ESTADO PRINCIPAL ────────────
  final _firestore = FirebaseFirestore.instance;

  bool _loading = true, _saving = false;
  List<DropdownMenuItem<String>> _zoneItems = [];
  String? _selectedZoneId;

  int _selectedDuration = 0;
  int _minDuration = 0;
  int _maxDuration = 0;
  int _increment   = 0;

  double _price = 0.0;
  double _basePrice = 0.0;
  double _extraBlockPrice = 0.0;

  final _plateCtrl = TextEditingController();

  String?  _ticketId;
  DateTime? _paidUntil;

  DateTime _currentTime = DateTime.now();
  Timer?   _clockTimer;
  bool     _intlReady = false;

  StreamSubscription<DocumentSnapshot>? _tariffSubscription;

  late DateTime _startTime;
  late DateTime _endTime;
  late bool     _endTimeNextDay;

  bool   _emergencyActive = false;
  String _emergKey  = '';   // clave para traducción
  String _emergText = '';   // texto libre firebase

  List<int> _validDays = [];

  bool _emergencyDialogVisible = false;
  int  _countdownSeconds       = 5;
  Timer? _countdownTimer;

  // ──────────── INIT / DISPOSE ────────────
  @override
  void initState() {
    super.initState();
    _loadZones();
    _clockTimer = Timer.periodic(const Duration(seconds: 1),
        (_) => setState(() => _currentTime = DateTime.now()));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Provider.of<LocaleProvider>(context).locale;
    final localeName = switch (locale.languageCode) {
      'es' => 'es_ES',
      'ca' => 'ca_ES',
      _    => 'en_GB'
    };
    if (Intl.defaultLocale != localeName) {
      Intl.defaultLocale = localeName;
      initializeDateFormatting(localeName).then((_) {
        if (mounted) setState(() => _intlReady = true);
      });
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _tariffSubscription?.cancel();
    _countdownTimer?.cancel();
    _plateCtrl.dispose();
    super.dispose();
  }

  // ──────────── CARGA DE ZONAS ────────────
  Future<void> _loadZones() async {
    final snap = await _firestore.collection('tariffs').get();
    _zoneItems = snap.docs
        .map((d) => DropdownMenuItem(value: d.id, child: Text(d['zoneId'] ?? d.id)))
        .toList();
    setState(() => _loading = false);
  }

  // ──────────── SUBSCRIPCIÓN TARIFA ────────────
  void _subscribeTariff(String docId) {
    _tariffSubscription?.cancel();
    _tariffSubscription =
        _firestore.collection('tariffs').doc(docId).snapshots().listen((doc) {
      if (!doc.exists) return;
      final d = doc.data()!;

      setState(() {
        _basePrice       = (d['basePrice']       ?? 0).toDouble();
        _extraBlockPrice = (d['extraBlockPrice'] ?? 0).toDouble();
        _minDuration     = (d['minDuration']     ?? 0) as int;
        _maxDuration     = (d['maxDuration']     ?? 0) as int;
        _increment       = (d['increment']       ?? 1) as int;

        _startTime = _parseTime(d['startTime'] ?? '00:00');
        _endTime   = _parseTime(d['endTime']   ?? '23:59', endTime: true);
        _endTimeNextDay = _endTime.day != _startTime.day;

        _emergencyActive = (d['emergencyActive'] ?? false) as bool;
        _emergKey  = (d['emergencyReasonKey'] ?? '').toString();
        _emergText = (d['emergencyReason']    ?? '').toString();

        _validDays = List<int>.from(d['validDays'] ?? []);

        _selectedDuration = _minDuration > 0 ? _minDuration : 0;
        _updatePrice();
        _paidUntil = _calculatePaidUntil();

        if (_emergencyActive && !_emergencyDialogVisible) {
          _showEmergencyDialog();
        }
      });
    });
  }

  // ──────────── UTILIDAD DE TRADUCCIÓN ────────────
  String _translatedEmerg(BuildContext ctx) {
    final loc = AppLocalizations.of(ctx).t(_emergKey);
    if (loc != _emergKey && loc.isNotEmpty) return loc; // clave traducida
    return _emergText;                                   // fallback
  }

  // ──────────── CÁLCULOS DE TIEMPO ────────────
  DateTime _parseTime(String t, {bool endTime = false}) {
    final now = DateTime.now();
    final p   = t.split(':');
    final h   = int.tryParse(p[0]) ?? 0;
    final m   = int.tryParse(p.length > 1 ? p[1] : '0') ?? 0;
    if (endTime && h < _startTime.hour) {
      return DateTime(now.year, now.month, now.day + 1, h, m);
    }
    return DateTime(now.year, now.month, now.day, h, m);
  }

  DateTime _getBaseTime() {
    final now = DateTime.now();
    DateTime base = now;

    if (!_validDays.contains(now.weekday)) {
      int add = 1;
      while (!_validDays.contains(now.add(Duration(days: add)).weekday)) add++;
      final nxt = now.add(Duration(days: add));
      base = DateTime(nxt.year, nxt.month, nxt.day, _startTime.hour, _startTime.minute);
    } else if (now.isBefore(_startTime)) {
      base = DateTime(now.year, now.month, now.day, _startTime.hour, _startTime.minute);
    } else if (now.isAfter(_endTime)) {
      int add = 1;
      while (!_validDays.contains(now.add(Duration(days: add)).weekday)) add++;
      final nxt = now.add(Duration(days: add));
      base = DateTime(nxt.year, nxt.month, nxt.day, _startTime.hour, _startTime.minute);
    }
    return base;
  }

  DateTime _endTimeForDate(DateTime date) {
    final base = DateTime(date.year, date.month, date.day, _endTime.hour, _endTime.minute);
    return _endTimeNextDay ? base.add(const Duration(days: 1)) : base;
  }

  DateTime _calculatePaidUntil([int? duration]) {
    if (_emergencyActive) return DateTime.now();

    final mins   = duration ?? _selectedDuration;
    final base   = _getBaseTime();
    final limit  = _endTimeForDate(base);
    final finish = base.add(Duration(minutes: mins));

    if (finish.isAfter(limit)) {
      DateTime next = finish.add(const Duration(days: 1));
      while (!_validDays.contains(next.weekday)) next = next.add(const Duration(days: 1));
      return DateTime(next.year, next.month, next.day, _startTime.hour, _startTime.minute);
    }
    return finish;
  }

  // ──────────── PRECIO Y DURACIÓN ────────────
  void _updatePrice() {
    if (_emergencyActive || _selectedDuration < _minDuration) {
      _price = 0;
      return;
    }
    final blocks = ((_selectedDuration - _minDuration) / _increment).ceil();
    _price = blocks <= 0
        ? _basePrice
        : _basePrice + _extraBlockPrice * blocks;
  }

  void _increaseDuration() {
    if (!_canIncreaseDuration) return;
    int next = _selectedDuration + _increment;
    if (next > _maxDuration) next = _maxDuration;
    setState(() {
      _selectedDuration = next;
      _updatePrice();
      _paidUntil = _calculatePaidUntil();
    });
  }

  void _decreaseDuration() {
    if (!_canDecreaseDuration) return;
    int prev = _selectedDuration - _increment;
    if (prev < _minDuration) prev = _minDuration;
    setState(() {
      _selectedDuration = prev;
      _updatePrice();
      _paidUntil = _calculatePaidUntil();
    });
  }

  bool get _canIncreaseDuration {
    if (_emergencyActive || _selectedDuration >= _maxDuration) return false;
    int next = _selectedDuration + _increment;
    if (next > _maxDuration) next = _maxDuration;
    return !_calculatePaidUntil(next).isAfter(_endTimeForDate(_getBaseTime()));
  }

  bool get _canDecreaseDuration =>
      !_emergencyActive && _selectedDuration > _minDuration;

  bool get _isPaymentAllowed =>
      !_emergencyActive &&
      _validDays.contains(DateTime.now().weekday) &&
      _selectedDuration >= _minDuration;

  // ──────────── DIÁLOGO EMERGENCIA ────────────
  void _showEmergencyDialog() {
    _countdownSeconds       = 5;
    _emergencyDialogVisible = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setStateDialog) {
          _countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (t) {
            if (_countdownSeconds > 0) {
              setState(() => _countdownSeconds--);
              setStateDialog(() {});
            } else {
              t.cancel();
              _emergencyDialogVisible = false;
              Navigator.of(ctx).pop();
            }
          });

          return AlertDialog(
            title: Center(
              child: Text(
                'ADVERTENCIA',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _translatedEmerg(ctx),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(ctx).t(
                    'autoCloseIn',
                    params: {'seconds': '$_countdownSeconds'},
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _countdownTimer?.cancel();
                  _emergencyDialogVisible = false;
                  Navigator.of(ctx).pop();
                },
                child: Text(AppLocalizations.of(ctx).t('close')),
              ),
            ],
          );
        });
      },
    ).then((_) {
      _emergencyDialogVisible = false;
      _countdownTimer?.cancel();
      _countdownTimer = null;
    });
  }

  // ──────────── INTERFAZ ────────────
  @override
  Widget build(BuildContext context) {
    final allReady = !_saving &&
        _selectedZoneId != null &&
        _plateCtrl.text.trim().isNotEmpty &&
        _isPaymentAllowed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiosk App'),
        actions: const [LanguageSelector(), SizedBox(width: 8), ThemeModeButton()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // FECHA/HORA
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

                  // ZONA
                  DropdownButtonFormField<String>(
                    decoration:
                        InputDecoration(labelText: AppLocalizations.of(context).t('zone')),
                    items: _zoneItems,
                    value: _selectedZoneId,
                    hint: Text(AppLocalizations.of(context).t('chooseZone')),
                    onChanged: _onZoneChanged,
                  ),
                  const SizedBox(height: 16),

                  // MATRÍCULA
                  TextField(
                    controller: _plateCtrl,
                    decoration:
                        InputDecoration(labelText: AppLocalizations.of(context).t('plate')),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // FRANJA ROJA EMERGENCIA
                  if (_emergencyActive)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin:  const EdgeInsets.only(bottom: 12),
                      color: Colors.red.shade300,
                      child: Text(
                        _translatedEmerg(context),
                        style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // BOTONES DURACIÓN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _canDecreaseDuration ? _decreaseDuration : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _canDecreaseDuration ? const Color(0xFFE62144) : Colors.grey,
                          minimumSize: const Size(40, 40),
                        ),
                        child: const Icon(Icons.remove, color: Colors.white),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _selectedDuration > 0 ? '$_selectedDuration min' : '-- min',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _canIncreaseDuration ? _increaseDuration : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _canIncreaseDuration ? const Color(0xFFE62144) : Colors.grey,
                          minimumSize: const Size(40, 40),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // PRECIO / HASTA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${AppLocalizations.of(context).t('price')}: '
                        '${_intlReady ? NumberFormat.currency(symbol: '€', decimalDigits: 2, locale: Intl.defaultLocale).format(_price) : _price.toStringAsFixed(2) + ' €'}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${AppLocalizations.of(context).t('until')}: $_paidUntilFormattedWithDate',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // BOTÓN PAGAR
                  ElevatedButton(
                    onPressed: allReady ? _confirmAndPay : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: allReady ? const Color(0xFFE62144) : Colors.grey,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                          )
                        : Text(AppLocalizations.of(context).t('pay')),
                  ),
                ],
              ),
            ),
    );
  }
}
