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
  /* ────────────────────────────  ESTADO BÁSICO  ──────────────────────────── */
  final _firestore = FirebaseFirestore.instance;
  bool _loading = true, _saving = false;
  List<DropdownMenuItem<String>> _zoneItems = [];
  String? _selectedZoneId;
  final _plateCtrl = TextEditingController();

  /* ─────────────────────────────  DATOS TARIFA  ───────────────────────────── */
  int _selectedDuration = 0, _minDuration = 0, _maxDuration = 0, _increment = 0;
  double _price = 0.0, _basePrice = 0.0, _extraBlockPrice = 0.0;
  DateTime? _startTime;
  DateTime? _endTime;
  List<int> _validDays = [];
  bool _emergencyActive = false;
  String _emergencyReason = '';

  /* ─────────────────────────────   OTROS   ───────────────────────────── */
  DateTime? _paidUntil;
  DateTime _now = DateTime.now();
  Timer? _clockTimer;
  bool _intlReady = false;
  StreamSubscription<DocumentSnapshot>? _tariffSub;

  /* ═══════════════════════   INIT / DISPOSE   ═══════════════════════ */
  @override
  void initState() {
    super.initState();
    _loadZones();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Provider.of<LocaleProvider>(context).locale;
    final locName = switch (locale.languageCode) {
      'es' => 'es_ES',
      'ca' => 'ca_ES',
      _ => 'en_GB',
    };
    if (Intl.defaultLocale != locName) {
      Intl.defaultLocale = locName;
      initializeDateFormatting(locName, null).then((_) {
        if (mounted) setState(() => _intlReady = true);
      });
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _tariffSub?.cancel();
    _plateCtrl.dispose();
    super.dispose();
  }

  /* ═══════════════════════   FIRESTORE   ═══════════════════════ */

  Future<void> _loadZones() async {
    final snap = await _firestore.collection('tariffs').get();
    _zoneItems = snap.docs
        .map((d) =>
            DropdownMenuItem(value: d.id, child: Text(d.data()['zoneId'] ?? d.id)))
        .toList();
    setState(() => _loading = false);
  }

  void _subscribeTariff(String docId) {
    _tariffSub?.cancel();
    _tariffSub = _firestore.collection('tariffs').doc(docId).snapshots().listen(
      (doc) {
        if (!doc.exists) return;
        final d = doc.data()!;

        _basePrice = (d['basePrice'] ?? 0).toDouble();
        _extraBlockPrice = (d['extraBlockPrice'] ?? 0).toDouble();
        _minDuration = d['minDuration'] ?? 0;
        _maxDuration = d['maxDuration'] ?? 0;
        _increment = d['increment'] ?? 1;
        _validDays = List<int>.from(d['validDays'] ?? []);
        _emergencyActive = d['emergencyActive'] ?? false;
        _emergencyReason = d['emergencyReason'] ?? '';

        _startTime = _parseTime(d['startTime'] ?? '00:00');
        _endTime = _parseEndTime(d['endTime'] ?? '23:59', _startTime!);

        _selectedDuration = _minDuration > 0 ? _minDuration : 0;
        _updatePrice();
        _paidUntil = _calcPaidUntil();

        setState(() {});

        if (_emergencyActive) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _showEmergency());
        }
      },
    );
  }

  /* ═══════════════════════   HORARIO HELPERS   ═══════════════════════ */

  DateTime _parseTime(String hhmm) {
    final p = hhmm.split(':');
    final h = int.tryParse(p[0]) ?? 0;
    final m = int.tryParse(p.length > 1 ? p[1] : '0') ?? 0;
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day, h, m);
  }

  DateTime _parseEndTime(String hhmm, DateTime start) {
    final endSame = _parseTime(hhmm);
    return endSame.isAfter(start) ? endSame : endSame.add(const Duration(days: 1));
  }

  bool get _isWithinHours {
    if (_startTime == null || _endTime == null) return false;
    if (_emergencyActive) return false;
    if (_validDays.isEmpty || !_validDays.contains(_now.weekday)) return false;

    final s = _startTime!;
    final e = _endTime!;
    if (e.isAfter(s)) {
      return _now.isAfter(s) && _now.isBefore(e);
    } else {
      return _now.isAfter(s) || _now.isBefore(e);
    }
  }

  /* ═══════════════════════   PRECIO & UNTIL   ═══════════════════════ */

  void _updatePrice() {
    if (_emergencyActive || _selectedDuration < _minDuration) {
      _price = 0;
      return;
    }
    final extraBlocks =
        ((_selectedDuration - _minDuration) / _increment).ceil();
    _price =
        _basePrice + (_extraBlockPrice * (extraBlocks > 0 ? extraBlocks : 0));
  }

  DateTime _calcPaidUntil() {
    if (_startTime == null || _endTime == null) return _now;
    var base = _now;
    final s = _startTime!;
    final e = _endTime!;
    if (!_isWithinHours) base = s.isAfter(_now) ? s : s.add(const Duration(days: 1));
    var until = base.add(Duration(minutes: _selectedDuration));
    if (until.isAfter(e)) until = e;
    return until;
  }

  /* ═══════════════════════   FORMATEOS TEXTO   ═══════════════════════ */

  String _validDaysStr() {
    if (_validDays.isEmpty) return '';
    const names = ['', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
    return _validDays.map((d) => names[d]).join(', ');
  }

  /* ═══════════════════════   MODAL EMERGENCIA   ═══════════════════════ */

  void _showEmergency() {
    int count = 5;
    Timer? t;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        t = Timer.periodic(const Duration(seconds: 1), (_) {
          if (count == 0) {
            t?.cancel();
            if (Navigator.canPop(ctx)) Navigator.pop(ctx);
          } else {
            setState(() => count--);
          }
        });

        return StatefulBuilder(
          builder: (_, setStateDialog) => AlertDialog(
            title: const Text('Emergencia'),
            content: Text('$_emergencyReason\n\nCerrando en $count s…'),
            actions: [
              TextButton(
                onPressed: () {
                  t?.cancel();
                  Navigator.pop(ctx);
                },
                child: const Text('Cerrar'),
              )
            ],
          ),
        );
      },
    ).then((_) => t?.cancel());
  }

  /* ═══════════════════════   ACCIONES USER   ═══════════════════════ */

  void _changeZone(String? id) {
    if (id == null) return;
    setState(() {
      _selectedZoneId = id;
      _plateCtrl.clear();
      _price = 0;
      _selectedDuration = 0;
    });
    _subscribeTariff(id);
  }

  void _inc() {
    if (!_isWithinHours || _emergencyActive) return;
    _selectedDuration =
        (_selectedDuration + _increment).clamp(_minDuration, _maxDuration);
    _updatePrice();
    _paidUntil = _calcPaidUntil();
    setState(() {});
  }

  void _dec() {
    if (!_isWithinHours || _emergencyActive) return;
    _selectedDuration =
        (_selectedDuration - _increment).clamp(_minDuration, _maxDuration);
    _updatePrice();
    _paidUntil = _calcPaidUntil();
    setState(() {});
  }

  Future<void> _pay() async {
    if (!_isWithinHours ||
        _emergencyActive ||
        _plateCtrl.text.trim().isEmpty ||
        _selectedZoneId == null) return;

    final plate = _plateCtrl.text.trim().toUpperCase();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Matrícula correcta?'),
        content: Text(plate),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí')),
        ],
      ),
    );

    if (ok != true) return;

    // Simulación pago
    setState(() => _saving = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _saving = false);

    // Guardar ticket
    final doc = await _firestore.collection('tickets').add({
      'zoneId': _selectedZoneId,
      'plate': plate,
      'paidUntil': Timestamp.fromDate(_paidUntil!),
      'price': _price,
      'duration': _selectedDuration,
    });

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TicketSuccessPage(ticketId: doc.id)),
    );

    // reset UI
    setState(() {
      _plateCtrl.clear();
      _selectedDuration = _minDuration;
      _paidUntil = _calcPaidUntil();
      _updatePrice();
    });
  }

  /* ═══════════════════════   BUILD   ═══════════════════════ */

  @override
  Widget build(BuildContext context) {
    final priceTxt = _intlReady
        ? NumberFormat.currency(symbol: '€', locale: Intl.defaultLocale, decimalDigits: 2)
            .format(_price)
        : '${_price.toStringAsFixed(2)} €';

    final untilTxt = _paidUntil != null
        ? '${_paidUntil!.hour.toString().padLeft(2, '0')}:${_paidUntil!.minute.toString().padLeft(2, '0')}'
        : '--:--';

    final tariffInactive = !_isWithinHours && !_emergencyActive;
    final canPay = !_saving &&
        !tariffInactive &&
        !_emergencyActive &&
        _selectedZoneId != null &&
        _plateCtrl.text.trim().isNotEmpty;

    final startStr = _startTime != null ? DateFormat.Hm().format(_startTime!) : '--:--';
    final endStr = _endTime != null ? DateFormat.Hm().format(_endTime!) : '--:--';

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
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFFE62144)),
                      const SizedBox(width: 8),
                      Text(
                        _intlReady
                            ? DateFormat('EEEE, d MMM y • HH:mm:ss', Intl.defaultLocale).format(_now)
                            : '',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration:
                        InputDecoration(labelText: AppLocalizations.of(context).t('zone')),
                    items: _zoneItems,
                    value: _selectedZoneId,
                    hint: Text(AppLocalizations.of(context).t('chooseZone')),
                    onChanged: _changeZone,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _plateCtrl,
                    decoration:
                        InputDecoration(labelText: AppLocalizations.of(context).t('plate')),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  /* ─── Banner emergencia ─── */
                  if (_emergencyActive)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Colors.red.shade300,
                      child: Text(
                        _emergencyReason,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),

                  /* ─── Banner fuera de horario / día (modelo 3) ─── */
                  if (tariffInactive)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade200,
                        border: Border.all(color: Colors.orange.shade700),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Tarifa activa solo los días: ${_validDaysStr()}, de $startStr a $endStr.',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),

                  /* ─── Botones duración ─── */
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: (tariffInactive || _emergencyActive) ? null : _dec,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (tariffInactive || _emergencyActive)
                              ? Colors.grey
                              : const Color(0xFFE62144),
                          minimumSize: const Size(40, 40),
                        ),
                        child: const Icon(Icons.remove, color: Colors.white),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _selectedDuration > 0 ? '$_selectedDuration min' : '-- min',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: (tariffInactive || _emergencyActive) ? null : _inc,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (tariffInactive || _emergencyActive)
                              ? Colors.grey
                              : const Color(0xFFE62144),
                          minimumSize: const Size(40, 40),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  /* ─── Precio / Hasta ─── */
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${AppLocalizations.of(context).t('price')}: $priceTxt',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${AppLocalizations.of(context).t('until')}: $untilTxt',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  /* ─── Botón Pagar ─── */
                  ElevatedButton(
                    onPressed: canPay ? _pay : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canPay ? const Color(0xFFE62144) : Colors.grey,
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
                        : Text(AppLocalizations.of(context).t('pay')),
                  ),
                ],
              ),
            ),
    );
  }
}
