import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'language_selector.dart';
import 'theme_mode_button.dart';
import 'payment_method_page.dart';
import 'ticket_success_page.dart';
import 'mowiz_model.dart';

/// Flow with three simple screens to simulate the MOWIZ process.
class MowizPage extends StatefulWidget {
  const MowizPage({super.key});

  @override
  State<MowizPage> createState() => _MowizPageState();
}

enum _Step { main, zone, time }

class _MowizPageState extends State<MowizPage> {
  final MowizModel _model = MowizModel();
  _Step _step = _Step.main;

  void _reset() {
    _model.reset();
    setState(() => _step = _Step.main);
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _model,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Simulador MOWIZ'),
          leading: _step != _Step.main
              ? BackButton(onPressed: _reset)
              : null,
          actions: const [
            LanguageSelector(),
            SizedBox(width: 8),
            ThemeModeButton(),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildStep(),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _Step.main:
        return _MainScreen(
          onPay: () => setState(() => _step = _Step.zone),
          onCancel: _reset,
        );
      case _Step.zone:
        return _ZoneScreen(
          onConfirm: () => setState(() => _step = _Step.time),
          onCancel: _reset,
        );
      case _Step.time:
        return _TimeScreen(onCancel: _reset);
    }
  }
}

class _MainScreen extends StatelessWidget {
  final VoidCallback onPay;
  final VoidCallback onCancel;
  const _MainScreen({required this.onPay, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: onPay,
          child: const Text('Pagar ticket'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {},
          child: const Text('Anular denúncia'),
        ),
        const SizedBox(height: 32),
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

class _ZoneScreen extends StatefulWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  const _ZoneScreen({required this.onConfirm, required this.onCancel});

  @override
  State<_ZoneScreen> createState() => _ZoneScreenState();
}

class _ZoneScreenState extends State<_ZoneScreen> {
  final _plateCtrl = TextEditingController();

  @override
  void dispose() {
    _plateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<MowizModel>();
    final zone = model.zone;
    final canConfirm = zone != null && _plateCtrl.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Selecciona zona',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => model.selectZone('azul'),
          style: ElevatedButton.styleFrom(
            backgroundColor: zone == 'azul'
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.secondary,
          ),
          child: const Text('Zona azul'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => model.selectZone('verde'),
          style: ElevatedButton.styleFrom(
            backgroundColor: zone == 'verde'
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.secondary,
          ),
          child: const Text('Zona verde'),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _plateCtrl,
          enabled: zone != null,
          decoration: const InputDecoration(hintText: 'Inserte matrícula'),
          onChanged: (_) => setState(() {}),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: canConfirm
              ? () {
                  model.setPlate(_plateCtrl.text.trim());
                  widget.onConfirm();
                }
              : null,
          child: const Text('Confirmar'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

class _TimeScreen extends StatelessWidget {
  final VoidCallback onCancel;
  const _TimeScreen({required this.onCancel});

  Future<void> _pay(BuildContext context) async {
    final model = context.read<MowizModel>();
    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaymentMethodPage(
          zoneId: model.zone!,
          plate: model.plate,
          duration: model.minutes,
          price: model.price,
        ),
      ),
    );
    if (paid == true && context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const TicketSuccessPage(ticketId: 'demo'),
        ),
      );
      onCancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<MowizModel>();
    final now = DateTime.now();
    final finish = model.finishTime;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          DateFormat('dd/MM/yyyy').format(now),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          DateFormat('HH:mm').format(now),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () => model.changeMinutes(1),
              child: const Text('+1'),
            ),
            ElevatedButton(
              onPressed: () => model.changeMinutes(15),
              child: const Text('+15'),
            ),
            ElevatedButton(
              onPressed: () => model.changeMinutes(-15),
              child: const Text('-15'),
            ),
            ElevatedButton(
              onPressed: () => model.changeMinutes(-1),
              child: const Text('-1'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          '${model.minutes ~/ 60}h ${model.minutes % 60}m',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          '${model.price.toStringAsFixed(2)} €',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          'Fin: ${DateFormat('dd/MM/yyyy HH:mm').format(finish)}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: () => _pay(context),
          child: const Text('Pagar'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
