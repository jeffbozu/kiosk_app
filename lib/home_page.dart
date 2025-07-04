// lib/home_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _firestore = FirebaseFirestore.instance;
  final _user      = FirebaseAuth.instance.currentUser;
  bool _loading    = true;
  bool _saving     = false;

  List<DropdownMenuItem<String>> _zoneItems     = [];
  List<DropdownMenuItem<int>>    _durationItems = [];
  String? _selectedZoneId;
  int?    _selectedDuration;
  final _plateCtrl = TextEditingController();

  String? _ticketId;
  DateTime? _paidUntil;

  Timer? _backTimer;
  int _backSeconds = 5;

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  @override
  void dispose() {
    _backTimer?.cancel();
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
    _durationItems = snap.docs.map((doc) {
      final data = doc.data();
      return DropdownMenuItem(
        value: data['duration'] as int,
        child: Text('${data['duration']} min – €${data['basePrice']}'),
      );
    }).toList();
    setState(() {});
  }

  Future<void> _confirmAndPay() async {
    if (_selectedZoneId == null ||
        _selectedDuration == null ||
        _plateCtrl.text.trim().isEmpty) return;

    // 1. Confirmar matrícula
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

    // 2. Crear ticket
    setState(() {
      _saving = true;
      _ticketId = null;
    });
    final now = DateTime.now();
    final paidUntil = now.add(Duration(minutes: _selectedDuration!));
    final doc = await _firestore.collection('tickets').add({
      'userId': _user?.email,
      'zoneId': _selectedZoneId,
      'plate': matricula,
      'paidUntil': Timestamp.fromDate(paidUntil),
      'status': 'paid',
    });
    _paidUntil = paidUntil;
    _ticketId = doc.id;
    setState(() => _saving = false);

    // 3. Envío por email
    final sendEmail = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Enviar ticket por email?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sí')),
        ],
      ),
    );
    if (sendEmail == true) {
      final email = await _askForEmail();
      if (email != null) await _launchEmail(email);
    }

    // 4. Iniciar temporizador de regreso
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
      query: Uri.encodeFull('subject=Tu ticket&body=ID: $_ticketId\nVálido hasta: $_paidUntil'),
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
          MaterialPageRoute(builder: (_) => const LoginPage()), 
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
    final allReady = !_saving
      && _selectedZoneId != null
      && _selectedDuration != null
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
                // Zona
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Zona'),
                  items: _zoneItems,
                  value: _selectedZoneId,
                  onChanged: (v) {
                    setState(() {
                      _selectedZoneId = v;
                      _selectedDuration = null;
                      _durationItems = [];
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

                // Duración
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Duración'),
                  items: _durationItems,
                  value: _selectedDuration,
                  onChanged: (v) => setState(() => _selectedDuration = v),
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
                        width: 24, height: 24,
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
