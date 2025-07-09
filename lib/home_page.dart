import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'login_page.dart';
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
  final _user = FirebaseAuth.instance.currentUser;
  bool _loading = true, _saving = false;

  List<DropdownMenuItem<String>> _zoneItems = [];
  List<DropdownMenuItem<int>> _durationItems = [];
  String? _selectedZoneId;
  int _selectedDuration = 10; // empieza en 10 minutos
  int _minDuration = 10;
  int _maxDuration = 120;
  int _increment = 10;
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

  Future<void> _loadDurations(String zoneId) async {
    final query = await _firestore
        .collection('tariffs')
        .where('zoneId', isEqualTo: zoneId)
        .get();

    final items = <DropdownMenuItem<int>>[];

    double zoneBasePrice = 1.0; // default
    for (final doc in query.docs) {
      final d = doc.data();
      final dur = d['duration'] as int;
      items.add(DropdownMenuItem(value: dur, child: Text('$dur min')));
      if (d.containsKey('basePrice')) {
        zoneBasePrice = (d['basePrice'] as num).toDouble();
      }
    }

    items.sort((a, b) => a.value!.compareTo(b.value!));
    if (items.isNotEmpty) {
      _minDuration = items.first.value!;
      _maxDuration = items.last.value!;
      if (items.length > 1) {
        _increment = items[1].value! - items.first.value!;
      }
    }
    int newSelectedDuration = _selectedDuration;
    if (!items.any((i) => i.value == newSelectedDuration)) {
      newSelectedDuration = items.isNotEmpty ? items.first.value! : _minDuration;
    }

    setState(() {
      _durationItems = items;
      _basePrice = zoneBasePrice;
      _selectedDuration = newSelectedDuration;
      _updatePrice();
      _paidUntil = DateTime.now().add(Duration(minutes: _selectedDuration));
    });
  }

  void _updatePrice() {
    final blocks = (_selectedDuration / 10).ceil();

    double extraBlockPrice = 0.25; // por defecto

    if (_selectedZoneId == 'centro') {
      extraBlockPrice = 0.20;
    } else if (_selectedZoneId == 'ensanche') {
      extraBlockPrice = 0.25;
    } else if (_selectedZoneId == 'playa-norte') {
      extraBlockPrice = 0.30;
    }

    if (blocks <= 1) {
      _price = _basePrice;
    } else {
      _price = _basePrice + extraBlockPrice * (blocks - 1);
    }
  }

  void _increaseDuration() {
    final next = _selectedDuration + _increment;
    setState(() {
      _selectedDuration = next > _maxDuration ? _maxDuration : next;
      _updatePrice();
      _paidUntil = DateTime.now().add(Duration(minutes: _selectedDuration));
    });
  }

  void _decreaseDuration() {
    final prev = _selectedDuration - _increment;
    if (prev < _minDuration) return;
    setState(() {
      _selectedDuration = prev;
      _updatePrice();
      _paidUntil = DateTime.now().add(Duration(minutes: _selectedDuration));
    });
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
    final paidUntil = now.add(Duration(minutes: _selectedDuration));
    final doc = await _firestore.collection('tickets').add({
      'userId': _user?.email,
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
                      if (v != null) _loadDurations(v);
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
