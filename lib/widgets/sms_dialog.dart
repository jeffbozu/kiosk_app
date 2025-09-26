import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/sms_service.dart';

/// Diálogo de SMS con estados (input, sending, success, error)
class SMSDialogWithStates extends StatefulWidget {
  final String plate;
  final String zone;
  final DateTime start;
  final int minutes;
  final double price;
  final String method;
  final double? discount;
  final VoidCallback? onClose;

  const SMSDialogWithStates({
    required this.plate,
    required this.zone,
    required this.start,
    required this.minutes,
    required this.price,
    required this.method,
    this.discount,
    this.onClose,
    super.key,
  });

  @override
  State<SMSDialogWithStates> createState() => _SMSDialogWithStatesState();
}

class _SMSDialogWithStatesState extends State<SMSDialogWithStates> {
  DialogState _state = DialogState.input;
  String _phone = '';
  String? _errorMessage;

  Future<void> _sendSMS() async {
    setState(() => _state = DialogState.sending);

    try {
      final endTime = widget.start.add(Duration(minutes: widget.minutes));

      // Formatear número de teléfono
      String formattedPhone = _phone.trim();
      if (!formattedPhone.startsWith('+')) {
        // Si no tiene +, agregar +34
        String cleanPhone = formattedPhone.replaceAll(RegExp(r'[^\d]'), '');
        if (cleanPhone.startsWith('34')) {
          formattedPhone = '+$cleanPhone';
        } else if (cleanPhone.startsWith(RegExp(r'[6789]')) &&
            cleanPhone.length == 9) {
          formattedPhone = '+34$cleanPhone';
        } else if (cleanPhone.length == 9) {
          formattedPhone = '+34$cleanPhone';
        } else {
          formattedPhone = '+34$cleanPhone';
        }
      }

      print('📱 SMS Dialog - Número original: ${_phone.trim()}');
      print('📱 SMS Dialog - Número formateado: $formattedPhone');

      bool success = await SMSService.sendTicketSMS(
        phone: formattedPhone,
        plate: widget.plate,
        zone: widget.zone,
        start: widget.start,
        end: endTime,
        price: widget.price,
        method: widget.method,
        discount: widget.discount,
        localeCode: AppLocalizations.of(context).locale.toString(),
      );

      if (success) {
        setState(() => _state = DialogState.success);
        // Reanudar temporizador después de 2 segundos
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop(); // Cerrar el diálogo
            widget.onClose?.call();
          }
        });
      } else {
        setState(() {
          _state = DialogState.error;
          _errorMessage = 'Error al enviar el SMS';
        });
        // Reanudar temporizador después de 2 segundos
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop(); // Cerrar el diálogo
            widget.onClose?.call();
          }
        });
      }
    } catch (e) {
      setState(() {
        _state = DialogState.error;
        _errorMessage = e.toString();
      });
      // Reanudar temporizador después de 2 segundos
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop(); // Cerrar el diálogo
          widget.onClose?.call();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return AlertDialog(
      title: Text('📱 Enviar por SMS'),
      content: _buildContent(l),
      actions: _buildActions(l),
    );
  }

  Widget _buildContent(AppLocalizations l) {
    switch (_state) {
      case DialogState.input:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Introduce tu número de teléfono para recibir el ticket por SMS:',
            ),
            SizedBox(height: 16),
            TextField(
              onChanged: (value) => setState(() => _phone = value),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Número de teléfono',
                hintText: '678395045',
                border: OutlineInputBorder(),
              ),
            ),
            if (_errorMessage != null) ...[
              SizedBox(height: 8),
              Text(_errorMessage!, style: TextStyle(color: Colors.red)),
            ],
          ],
        );

      case DialogState.sending:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Enviando SMS...'),
          ],
        );

      case DialogState.success:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 48),
            SizedBox(height: 16),
            Text('¡SMS enviado exitosamente!'),
          ],
        );

      case DialogState.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text('Error al enviar SMS'),
            if (_errorMessage != null) ...[
              SizedBox(height: 8),
              Text(_errorMessage!, style: TextStyle(color: Colors.red)),
            ],
          ],
        );
    }
  }

  List<Widget> _buildActions(AppLocalizations l) {
    switch (_state) {
      case DialogState.input:
        return [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.t('cancel')),
          ),
          ElevatedButton(
            onPressed: _phone.trim().isNotEmpty ? _sendSMS : null,
            child: Text(l.t('send')),
          ),
        ];

      case DialogState.sending:
        return [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.t('cancel')),
          ),
        ];

      case DialogState.success:
        return [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.t('close')),
          ),
        ];

      case DialogState.error:
        return [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _state = DialogState.input);
            },
            child: Text(l.t('retry')),
          ),
        ];
    }
  }
}

/// Estados del diálogo
enum DialogState { input, sending, success, error }
