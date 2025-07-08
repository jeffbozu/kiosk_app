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
  double _basePrice = 0.0;     // precio base (primer bloque)
  double _increment = 0.0;     // incremento por bloque extra
  final Map<int, double> _durationPrices = {}; // precio por duración

  DateTime _currentTime = DateTime.now();
  Timer? _clockTimer;
  bool _intlReady = false;     // para saber si Intl ya cargó

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'es_ES';
    // Inicializa símbolos de fecha y moneda
    initializeDateFormatting('es_ES', null).then((_) {
      setState(() => _intlReady = true);
    });

    _loadZones();
    _updatePrice();
    _paidUntil = DateTime.now().add(Duration(minutes: _selectedDuration));

    // Reloj en pantalla
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

    // Usamos variables locales para preparar los nuevos datos
    final items = <DropdownMenuItem<int>>[];
    final prices = <int, double>{};
    double newBasePrice = 0.0;
    double newIncrement = 0.0;

    for (final doc in snap.docs) {
      final d = doc.data();
      final dur = d['duration'] as int;
      items.add(DropdownMenuItem(value: dur, child: Text('$dur min')));
      if (d.containsKey('price')) {
        prices[dur] = (d['price'] as num).toDouble();
      }
      if (d.containsKey('basePrice')) {
        newBasePrice = (d['basePrice'] as num).toDouble();
      }
      if (d.containsKey('increment')) {
        newIncrement = (d['increment'] as num).toDouble();
      }
    }

    // Ordenamos las duraciones para que los botones +/- funcionen correctamente
    items.sort((a, b) => a.value!.compareTo(b.value!));
    
    // Si la duración seleccionada previamente no existe en la nueva zona,
    // seleccionamos la primera disponible.
    int newSelectedDuration = _selectedDuration;
    if (!items.any((i) => i.value == newSelectedDuration)) {
      newSelectedDuration = items.isNotEmpty ? items.first.value! : 10;
    }

    setState(() {
      _durationItems = items;
      _durationPrices
        ..clear()
        ..addAll(prices);
      _basePrice = newBasePrice;
      _increment = newIncrement;
      _selectedDuration = newSelectedDuration;
      
      _updatePrice();
      _paidUntil = DateTime.now().add(Duration(minutes: _selectedDuration));
    });
  }

  void _updatePrice() {
    // Primero intenta usar la tarifa específica para la duración
    if (_durationPrices.containsKey(_selectedDuration)) {
      _price = _durationPrices[_selectedDuration]!;
      return;
    }
    // Si no hay precio específico, usa base e incremento por bloques de 5 min
    final blocks = (_selectedDuration / 5).round();
    _price = _basePrice + _increment * (blocks - 1);
  }

  void _increaseDuration() {
    int? next;
    // Buscamos la duración actual en la lista y seleccionamos la siguiente
    final idx = _durationItems.indexWhere((i) => i.value == _selectedDuration);
    if (idx !=