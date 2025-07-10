import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'package:qr_flutter/qr_flutter.dart';
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
  List<DropdownMenuItem<int>> _durationItems = [];
  String? _selectedZoneId;
  int _selectedDuration = 10; // empieza en 10 minutos
  int _minDuration = 10;
  int _maxDuration = 120; // máximo configurable según zona
  int _increment = 10;
  double _extraBlockPrice = 0.25;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  List<int> _validDays = [1, 2, 3, 4, 5, 6, 7];
  bool _emergencyActive = false;
  String _emergencyReason = '';
  StreamSubscription<DocumentSnapshot>? _tariffSub;
  final _plateCtrl = TextEditingController();

  String? _ticketId;
  DateTime? _paidUntil;

  double _price = 0.0;
  double _basePrice = 1.0; // valor base variable según zona

  DateTime _currentTime = DateTime.now();
  Timer? _clockTimer;
  bool _intlReady = false; // para saber si Intl ya cargó

  @override
  void initState() {
    super.initState();
    _loadZones();
    _updatePrice();
    _paidUntil = DateTime.now().add(Duration(minutes: _selectedDuration));

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
    _tariffSub?.cancel();
    super.dispose();
  }

  Future<void> _loadZones() async {
    final snap = await _firestore.collection('zones').get();
    _zoneItems = snap.docs.map((doc) {
      final data = doc.data();
      return DropdownMenuItem(
        value: doc.id,
        child: Text(data['name'] as String),
      );
    }).toList();
    setState(() => _loading = false);
  }

  void _listenTariff(String zoneId) {
    _tariffSub?.cancel();
    _tariffSub = _firestore.collection('tariffs').doc(zoneId).snapshots().listen(
      (snap) {
        final data = snap.data();
        if (data == null) return;

        _basePrice = (data['basePrice'] as num?)?.toDouble() ?? 1.0;
        _minDuration = (data['minDuration'] as num?)?.toInt() ?? 10;
        _maxDuration = (data['maxDuration'] as num?)?.toInt() ?? 120;
        _increment = (data['increment'] as num?)?.toInt() ?? 10;
        _extraBlockPrice = (data['extraBlockPrice'] as num?)?.toDouble() ?? 0.25;
        _startTime = _parseTimeOfDay(data['startTime'] as String?);
        _endTime = _parseTimeOfDay(data['endTime'] as String?);
        _validDays = List<int>.from(data['validDays'] ?? [1, 2, 3, 4, 5, 6, 7]);
        _emergencyActive = data['emergencyActive'] as bool? ?? false;
        _emergencyReason = data['emergencyReason'] as String? ?? '';

        _durationItems = [];
        for (var dur = _minDuration; dur <= _maxDuration; dur += _increment) {
          _durationItems.add(
              DropdownMenuItem(value: dur, child: Text('$dur min')));
        }
        if (!_durationItems.any((d) => d.value == _selectedDuration)) {
          _selectedDuration = _minDuration;
        }
        _paidUntil = DateTime.now().add(Duration(minutes: _selectedDuration));
        _updatePrice();
        if (mounted) setState(() {});
      },
    );
  }

  void _updatePrice() {
    if (_emergencyActive) {
      _price = 0.0;
      return;
    }

    final additional = math.max(0, _selectedDuration - _minDuration);
    final blocks = (additional / _increment).ceil();
    _price = _basePrice + _extraBlockPrice * blocks;
  }

  void _increaseDuration() {
    final next = math.min(_selectedDuration + _increment, _maxDuration);
    setState(() {
      _selectedDuration = next;
      _updatePrice();
      _paidUntil = DateTime.now().add(Duration(minutes: _selectedDuration));
    });
  }

  void _decreaseDuration() {
    final prev = math.max(_selectedDuration - _increment, _minDuration);
    setState(() {
      _selectedDuration = prev;
      _updatePrice();
      _paidUntil = DateTime.now().add(Duration(minutes: _selectedDuration));
    });
  }

  TimeOfDay? _parseTimeOfDay(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  bool _isWithinSchedule(DateTime now) {
    if (!_validDays.contains(now.weekday)) return false;
    if (_startTime == null || _endTime == null) return true;
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    final nowMinutes = now.hour * 60 + now.minute;
    if (startMinutes <= endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }
  }

  String get _paidUntilFormatted {
    if (_paidUntil == null) return '--:--';
    return '${_paidUntil!.hour.toString().padLeft(2, '0')}:${_paidUntil!.minute.toString().padLeft(2, '0')}';
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

    // Opcional: quitar la validación estricta si no quieres formato
    /*
    if (!RegExp(r'^[0-9]{4}[A-Z]{3}$').hasMatch(matricula)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).t('invalidPlate'))),
      );
      return;
    }
    */

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

    if (!_isWithinSchedule(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).t('invalidSchedule'))),
      );
      return;
    }
    bool paid = true;
    if (_price > 0) {
      paid = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => PaymentMethodPage(
                zoneId: _selectedZoneId!,
                plate: matricula,
                duration: _selectedDuration,
                price: _price,
              ),
            ),
          ) ??
          false;
      if (!paid) return;
    }

    setState(() {
      _saving = true;
      _ticketId = null;
    });

    final now = DateTime.now();
    final paidUntil = now.add(Duration(minutes: _selectedDuration));
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
      _paidUntil = DateTime.now().add(Duration(minutes: _selectedDuration));
    });
  }

  @override
  Widget build(BuildContext context) {
    final allReady = !_saving &&
        _selectedZoneId != null &&
        _plateCtrl.text.trim().isNotEmpty;

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
                    onChanged: (v) {
                      setState(() {
                        _selectedZoneId = v;
                        _selectedDuration = _minDuration;
                        _durationItems = [];
                        _updatePrice();
                      });
                      if (v != null) _listenTariff(v);
                    },
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
                          '$_selectedDuration min',
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
                  if (_emergencyActive && _emergencyReason.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context).t('emergencyActive',
                          params: {'reason': _emergencyReason}),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
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
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('¡Gracias!')),
                      );
                    },
                    child: const Text('GRACIAS'),
                  ),
                ],
              ),
            ),
    );
  }
}
