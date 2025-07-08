import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'login_page.dart';

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
  final _plateCtrl = TextEditingController();

  String? _ticketId;
  DateTime? _paidUntil;

  Timer? _backTimer;
  int _backSeconds = 5;

  double _price = 0.0;
  double _basePrice = 0.0;    // precio base (primer bloque)
  double _increment = 0.0;    // incremento por bloque extra
  final Map<int, double> _durationPrices = {}; // precio por duración

  DateTime _currentTime = DateTime.now();
  Timer? _clockTimer;
  bool _intlReady = false;     // para saber si Intl ya cargó

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'es_ES';
    initializeDateFormatting('es_ES', null).then((_) {
      setState(() => _intlReady = true);
    });

    _loadZones();
    _updatePrice();
    _paidUntil = DateTime.now().add(Duration(minutes: _selectedDuration));

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _currentTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    _backTimer?.cancel();
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
    final snap = await _firestore
        .collection('tariffs')
        .where('zoneId', isEqualTo: zoneId)
        .get();

    final items = <DropdownMenuItem<int>>[];
    double? basePrice;
    double? multiplier;

    for (final doc in snap.docs) {
      final d = doc.data();
      final dur = d['duration'] as int;
      items.add(DropdownMenuItem(value: dur, child: Text('$dur min')));
      if (basePrice == null && d.containsKey('basePrice')) {
        basePrice = (d['basePrice'] as num).toDouble();
      }
      if (multiplier == null && d.containsKey('multiplier')) {
        multiplier = (d['multiplier'] as num).toDouble();
      }
    }

    items.sort((a, b) => a.value!.compareTo(b.value!));
    int newSelectedDuration = _selectedDuration;
    if (!items.any((i) => i.value == newSelectedDuration)) {
      newSelectedDuration = items.isNotEmpty ? items.first.value! : 10;
    }

    setState(() {
      _durationItems = items;
      _basePrice = basePrice ?? 0.0;
      _increment = multiplier ?? 0.0;
      _selectedDuration = newSelectedDuration;
      _updatePrice();
      _paidUntil = DateTime.now().add(Duration(minutes: _selectedDuration));
    });
  }

  void _updatePrice() {
    final blocks = (_selectedDuration / 5).ceil();
    _price = _basePrice * _increment * blocks;
  }

  void _increaseDuration() {
    int? next;
    if (_durationItems.isNotEmpty) {
      final durations = _durationItems.map((e) => e.value!).toList()..sort();
      for (final d in durations) {
        if (d > _selectedDuration) {
          next = d;
          break;
        }
      }
    }
    next ??= _selectedDuration + 5;
    setState(() {
      _selectedDuration = next!;
      _updatePrice();
      _paidUntil = DateTime.now().add(Duration(minutes: _selectedDuration));
    });
  }

  void _decreaseDuration() {
    int? prev;
    if (_durationItems.isNotEmpty) {
      final durations = _durationItems.map((e) => e.value!).toList()..sort();
      for (final d in durations.reversed) {
        if (d < _selectedDuration) {
          prev = d;
          break;
        }
      }
    }
    prev ??= _selectedDuration - 5;
    if (prev < 10) return;
    setState(() {
      _selectedDuration = prev!;
      _updatePrice();
      _paidUntil = DateTime.now().add(Duration(minutes: _selectedDuration));
    });
  }

  String get _paidUntilFormatted {
    if (_paidUntil == null) return '--:--';
    return '${_paidUntil!.hour.toString().padLeft(2, '0')}:${_paidUntil!.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmAndPay() async {
    if (_selectedZoneId == null || _plateCtrl.text.trim().isEmpty) return;

    final matricula = _plateCtrl.text.trim();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Es correcta la matrícula?'),
        content: Text(matricula),
        actions: [
          TextButton(
            style: TextButton.styleFrom(backgroundColor: const Color(0xFF7F7F7F)),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() { _saving = true; _ticketId = null; });

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

    final send = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Enviar ticket por email?'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(backgroundColor: const Color(0xFF7F7F7F)),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE62144)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (send == true) {
      final email = await _askForEmail();
      if (email != null) await _launchEmail(email);
    }

    setState(() {
      _ticketId = doc.id;
      _backSeconds = 5;
    });
    _backTimer?.cancel();
    _backTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_backSeconds > 1) {
        setState(() => _backSeconds--);
      } else {
        t.cancel();
        setState(() {
          _ticketId = null;
          _plateCtrl.clear();
          _selectedDuration = 10;
          _paidUntil = DateTime.now().add(Duration(minutes: _selectedDuration));
        });
      }
    });
  }

  Future<String?> _askForEmail() async {
    String email = '';
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Introduce tu email'),
        content: TextField(
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'correo@ejemplo.com'),
          onChanged: (v) => email = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email)) {
                Navigator.pop(ctx, email);
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Ticket Kiosk&body=Tu ticket: $_ticketId',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allReady = !_saving
      && _selectedZoneId != null
      && _plateCtrl.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Kiosk App')),
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
                          ? DateFormat('EEEE, d MMM y • HH:mm:ss').format(_currentTime)
                          : '',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Zona'),
                    items: _zoneItems,
                    value: _selectedZoneId,
                    hint: const Text('Escoge zona…'),
                    onChanged: (v) {
                      setState(() {
                        _selectedZoneId = v;
                        _selectedDuration = 10;
                        _durationItems = [];
                        _durationPrices.clear();
                        _basePrice = 0.0;
                        _increment = 0.0;
                        _updatePrice();
                      });
                      if (v != null) _loadDurations(v);
                    },
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _plateCtrl,
                    decoration: const InputDecoration(labelText: 'Matrícula'),
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
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                        'Precio: ${_intlReady ? NumberFormat.currency(
                          symbol: '€', locale: 'es_ES', decimalDigits: 2
                        ).format(_price) : _price.toStringAsFixed(2) + ' €'}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Hasta: $_paidUntilFormatted',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (_ticketId != null) ...[
                    const Text('Ticket generado correctamente.',
                      style: TextStyle(color: Colors.green)),
                    const SizedBox(height: 8),
                    Center(
                      child: QrImageView(
                        data: _ticketId!,
                        version: QrVersions.auto,
                        size: 200,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Regresando en $_backSeconds s…',
                      textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                  ],

                  ElevatedButton(
                    onPressed: allReady ? _confirmAndPay : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: allReady
                        ? const Color(0xFFE62144) 
                        : Colors.grey,
                    ),
                    child: _saving
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Pagar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          )),
                  ),
                ],
              ),
            ),
    );
  }
}
