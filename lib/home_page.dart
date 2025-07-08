// lib/home_page.dart

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
  bool _loading = true;
  bool _saving = false;

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
  double _basePrice = 0.0; // precio para los primeros 5 minutos
  double _increment = 0.0; // incremento por cada bloque extra

  DateTime _currentTime = DateTime.now();
  Timer? _clockTimer;
  bool _intlReady = false; // para saber si Intl está inicializado

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'es_ES';
    // Carga datos de localización para fechas y monedas
    initializeDateFormatting('es_ES', null).then((_) {
      setState(() => _intlReady = true);
    });
    _loadZones();
    _updatePrice();
    _paidUntil = DateTime.now().add(Duration(minutes: _selectedDuration));
    // Actualiza la hora actual cada segundo
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
    if (snap.docs.isNotEmpty) {
      final first = snap.docs.first.data();
      _basePrice = (first['basePrice'] as num).toDouble();
      _increment = (first['increment'] as num).toDouble();
    }
    _durationItems = snap.docs.map((doc) {
      final data = doc.data();
      return DropdownMenuItem(
        value: data['duration'] as int,
        child: Text('${data['duration']} min'),
      );
    }).toList();

    // Si la duración actual no está en la lista, reiniciamos a 10
    if (!_durationItems.any((item) => item.value == _selectedDuration)) {
      _selectedDuration = 10;
    }

    _updatePrice();
    _paidUntil = DateTime.now().add(Duration(minutes: _selectedDuration));
    setState(() {});
  }

  void _updatePrice() {
    final blocks = (_selectedDuration / 5).round();
    _price = _basePrice + _increment * (blocks - 1);
  }

  void _increaseDuration() {
    setState(() {
      _selectedDuration += 5;
      _updatePrice();
      _paidUntil = DateTime.now().add(Duration(minutes: _selectedDuration));
    });
  }

  void _decreaseDuration() {
    if (_selectedDuration > 10) {
      setState(() {
        _selectedDuration -= 5;
        _updatePrice();
        _paidUntil = DateTime.now().add(Duration(minutes: _selectedDuration));
      });
    }
  }

  String get _paidUntilFormatted {
    if (_paidUntil == null) return '--:--';
    return '${_paidUntil!.hour.toString().padLeft(2, '0')}:${_paidUntil!.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmAndPay() async {
    if (_selectedZoneId == null ||
        _selectedDuration == null ||
        _plateCtrl.text.trim().isEmpty) return;

    final matricula = _plateCtrl.text.trim();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Es correcta la matrícula?'),
        content: Text(matricula),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF7F7F7F),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'No',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sí',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;

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

    final sendEmail = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Enviar ticket por email?'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF7F7F7F),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'No',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE62144),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sí',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (sendEmail == true) {
      final email = await _askForEmail();
      if (email != null) await _launchEmail(email);
    }

    _startBackTimer();
  }

  Future<String?> _askForEmail() async {
    return showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final ctrl = TextEditingController();
        String? error;
        return StatefulBuilder(builder: (ctx2, setState2) {
          return AlertDialog(
            title: const Text('Email de destino'),
            content: TextField(
              controller: ctrl,
              decoration: InputDecoration(labelText: 'Email', errorText: error),
              keyboardType: TextInputType.emailAddress,
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx2, null), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  final e = ctrl.text.trim();
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(e)) {
                    setState2(() => error = 'Formato incorrecto');
                    return;
                  }
                  Navigator.pop(ctx2, e);
                },
                child: const Text('Enviar'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: Uri.encodeFull('subject=Tu ticket&body=ID: $_ticketId\nVálido hasta: $_paidUntil\nPrecio: $_price €\nDuración: $_selectedDuration min'),
    );
    await launchUrl(uri);
  }

  void _startBackTimer() {
    _backTimer?.cancel();
    _backSeconds = 5;
    _backTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_backSeconds == 0) {
        t.cancel();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      } else {
        setState(() => _backSeconds--);
      }
    });
    setState(() {}); // refresca para mostrar contador
  }

  @override
  Widget build(BuildContext context) {
    final allReady = !_saving &&
        _selectedZoneId != null &&
        _selectedDuration != null &&
        _plateCtrl.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Kiosk App')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hora y fecha actuales
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFFE62144)),
                      const SizedBox(width: 8),
                      Text(
                        _intlReady
                            ? DateFormat('EEEE, d MMM y • HH:mm:ss')
                                .format(_currentTime)
                            : '',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Zona
                  _selectedZoneId == null
                      ? const Text(
                          'Escoge zona…',
                          style: TextStyle(color: Colors.grey),
                        )
                      : DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Zona'),
                          items: _zoneItems,
                          value: _selectedZoneId,
                          onChanged: (v) {
                            setState(() {
                              _selectedZoneId = v;
                              _selectedDuration = 10;
                              _durationItems = [];
                              _updatePrice();
                            });
                            if (v != null) _loadDurations(v);
                          },
                        ),
                  const SizedBox(height: 16),

                  // Matrícula
                  TextField(
                    controller: _plateCtrl,
                    decoration: const InputDecoration(labelText: 'Matrícula'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // Botones duración y duración actual en el centro
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

                  // Precio actualizado y hora final pagada
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Precio: ' +
                            (_intlReady
                                ? NumberFormat.currency(
                                        symbol: '€', locale: 'es_ES', decimalDigits: 2)
                                    .format(_price)
                                : _price.toStringAsFixed(2) + ' €'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Hasta: $_paidUntilFormatted',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Mostrar ticket + QR si existe
                  if (_ticketId != null) ...[
                    const Text(
                      'Ticket generado correctamente.',
                      style: TextStyle(color: Colors.green),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: QrImageView(
                        data: _ticketId!,
                        version: QrVersions.auto,
                        size: 200,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Regresando en $_backSeconds s…', textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                  ],

                  // Botón Pagar
                  ElevatedButton(
                    onPressed: allReady ? _confirmAndPay : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: allReady ? const Color(0xFFE62144) : Colors.grey,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Pagar',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

