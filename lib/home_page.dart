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

  late DateTime _startTime;
  late DateTime _endTime;
  late bool   _endTimeNextDay;

  bool _emergencyActive = false;
  String _emergKey  = '';
  String _emergText = '';

  List<int> _validDays = [];

  bool _emergencyDialogVisible = false;
  int  _countdownSeconds       = 5;
  Timer? _countdownTimer;

  // ────────────────────────────────────────────────────────────  INIT  ──
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
    final localeName = switch (locale.languageCode) {
      'es' => 'es_ES',
      'ca' => 'ca_ES',
      _    => 'en_GB'
    };
    if (Intl.defaultLocale != localeName) {
      Intl.defaultLocale = localeName;
      initializeDateFormatting(localeName, null)
          .then((_) => mounted ? setState(() => _intlReady = true) : null);
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

  // ───────────────────────────────  FIREBASE  ──
  Future<void> _loadZones() async {
    final snap = await _firestore.collection('tariffs').get();
    _zoneItems = snap.docs
        .map((d) => DropdownMenuItem(value: d.id, child: Text(d['zoneId'] ?? d.id)))
        .toList();
    setState(() => _loading = false);
  }

  void _subscribeTariff(String docId) {
    _tariffSubscription?.cancel();
    _tariffSubscription = _firestore
        .collection('tariffs')
        .doc(docId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;
      final d = doc.data()!;
      setState(() {
        _basePrice       = (d['basePrice']        ?? 0).toDouble();
        _extraBlockPrice = (d['extraBlockPrice']  ?? 0).toDouble();
        _minDuration     = (d['minDuration']      ?? 0) as int;
        _maxDuration     = (d['maxDuration']      ?? 0) as int;
        _increment       = (d['increment']        ?? 1) as int;

        _startTime       = _parseTime(d['startTime'] ?? '00:00');
        _endTime         = _parseTime(d['endTime']   ?? '23:59', endTime: true);
        _endTimeNextDay  = _endTime.day != _startTime.day;

        _emergencyActive = (d['emergencyActive'] ?? false) as bool;
        _emergKey        = (d['emergencyReasonKey'] ?? '').toString();
        _emergText       = (d['emergencyReason']    ?? '').toString();

        _validDays       = List<int>.from(d['validDays'] ?? []);

        _selectedDuration = _minDuration > 0 ? _minDuration : 0;
        _updatePrice();
        _paidUntil = _calculatePaidUntil();

        if (_emergencyActive && !_emergencyDialogVisible) _showEmergencyDialog();
      });
    });
  }

  // ──────────────────────  HELPERS  ──
  String _translatedEmerg(BuildContext ctx) {
    final loc = AppLocalizations.of(ctx).t(_emergKey);
    if (loc != _emergKey && loc.isNotEmpty) return loc; // se encontró la clave
    return _emergText;                                   // fallback texto libre
  }

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

  // ...  ───  (resto de métodos _getBaseTime, _endTimeForDate, _calculatePaidUntil,
  //            _updatePrice, _increaseDuration, _decreaseDuration, etc. NO CAMBIAN)  ───

  // ───────────────────  DIÁLOGO DE EMERGENCIA  ──
  void _showEmergencyDialog() {
    _countdownSeconds      = 5;
    _emergencyDialogVisible = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setStateDialog) {
          _countdownTimer ??=
              Timer.periodic(const Duration(seconds: 1), (timer) {
            if (_countdownSeconds > 0) {
              setState(() => _countdownSeconds--);
              setStateDialog(() {});
            } else {
              timer.cancel();
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

  // ──────────────────────  UI  ──
  @override
  Widget build(BuildContext context) {
    // ... (todo el código de build sin cambios salvo el recuadro rojo)
    // Dentro del Column, reemplaza sólo el bloque de recuadro rojo:

    /*
      if (_emergencyActive) ...[
        Container(
          padding: const EdgeInsets.all(12),
          margin:  const EdgeInsets.only(bottom: 12),
          color: Colors.red.shade300,
          child: Text(
            _translatedEmerg(context),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    */

    // Todo lo demás permanece igual.
  }
}
