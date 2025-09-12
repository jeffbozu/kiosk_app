import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'widgets/success_check_animation.dart';

import 'l10n/app_localizations.dart';
import 'mowiz_page.dart';
import 'mowiz/mowiz_scaffold.dart';
// Estilo de botones grandes reutilizable para toda la app
import 'styles/mowiz_buttons.dart';
import 'sound_helper.dart';
import 'services/unified_service.dart';
import 'services/email_service.dart';
import 'services/whatsapp_service.dart';

/// Helper function to format price with correct decimal separator based on locale
String formatPrice(double price, String locale) {
  if (locale.startsWith('es') || locale.startsWith('ca')) {
    // Use comma as decimal separator for Spanish and Catalan
    return '${price.toStringAsFixed(2).replaceAll('.', ',')} €';
  } else {
    // Use dot as decimal separator for English and others
    return '${price.toStringAsFixed(2)} €';
  }
}

class MowizSuccessPage extends StatefulWidget {
  final String plate;
  final String zone;
  final DateTime start;
  final int minutes;
  final double price;
  final String method;
  final double? discount;

  const MowizSuccessPage({
    super.key,
    required this.plate,
    required this.zone,
    required this.start,
    required this.minutes,
    required this.price,
    required this.method,
    this.discount,
  });

  @override
  State<MowizSuccessPage> createState() => _MowizSuccessPageState();
}

class _MowizSuccessPageState extends State<MowizSuccessPage> {
  int _seconds = 30;
  Timer? _timer;
  bool _showSuccessAnimation = true;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  /// Obtiene el nombre de la zona según el ID
  String _getZoneName(String zoneId, Function t) {
    switch (zoneId) {
      case 'green':
        return t('zoneGreen');
      case 'blue':
        return t('zoneBlue');
      case 'playa':
        return t('zonePlaya');
      case 'costa':
        return t('zoneCosta');
      case 'parque':
        return t('zoneParque');
      default:
        return zoneId; // Fallback al ID si no se reconoce
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds > 1) {
        setState(() => _seconds--);
      } else {
        t.cancel();
        _goHome();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MowizPage()),
      (route) => false,
    );
  }

  /// Imprime el ticket usando la impresora térmica conectada
  Future<void> _printTicket() async {
    try {
      // Pausar el temporizador mientras se imprime
      _pauseTimer();
      
      // Mostrar indicador de impresión
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imprimiendo ticket...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Calcular fecha de fin basada en los minutos
      final endTime = widget.start.add(Duration(minutes: widget.minutes));
      
      // Generar datos QR para el ticket
      final qrData = jsonEncode({
        'plate': widget.plate,
        'zone': widget.zone,
        'start': widget.start.toIso8601String(),
        'end': endTime.toIso8601String(),
        'price': widget.price,
        'method': widget.method,
        if (widget.discount != null && widget.discount != 0) 'discount': widget.discount,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Imprimir ticket usando el servicio unificado
      final success = await UnifiedService.printTicket(
        plate: widget.plate,
        zone: widget.zone,
        start: widget.start,
        end: endTime,
        price: widget.price,
        method: widget.method,
        qrData: qrData,
        discount: widget.discount,
        locale: AppLocalizations.of(context).locale.languageCode,
      );
      
      if (success) {
        // Ticket impreso exitosamente
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Ticket impreso correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // Error al imprimir
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error al imprimir el ticket'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      // Error inesperado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      // Reanudar el temporizador
      _startTimer();
    }
  }

  Future<void> _showEmailDialog() async {
    _pauseTimer();
    final email = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EmailDialogWithStates(
        plate: widget.plate,
        zone: widget.zone,
        start: widget.start,
        minutes: widget.minutes,
        price: widget.price,
        method: widget.method,
        discount: widget.discount,
      ),
    );
    if (!mounted) return;
    if (email != null) {
      // Enviar email usando el servicio
      await _sendTicketEmail(email);
    } else {
      _startTimer();
    }
  }

  /// Muestra el diálogo de WhatsApp con estados
  void _showWhatsAppDialogWithStates() {
    _pauseTimer();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _WhatsAppDialogWithStates(
        plate: widget.plate,
        zone: widget.zone,
        start: widget.start,
        minutes: widget.minutes,
        price: widget.price,
        method: widget.method,
        discount: widget.discount,
      ),
    );
  }
  
  /// Envía el ticket por email
  Future<void> _sendTicketEmail(String email) async {
    try {
      // Mostrar indicador de envío más rápido
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📧 Enviando email...'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.blue,
        ),
      );
      
      // Calcular fecha de fin
      final endTime = widget.start.add(Duration(minutes: widget.minutes));
      
      // Generar datos QR para el ticket
      final qrData = jsonEncode({
        'plate': widget.plate,
        'zone': widget.zone,
        'start': widget.start.toIso8601String(),
        'end': endTime.toIso8601String(),
        'price': widget.price,
        'method': widget.method,
        if (widget.discount != null && widget.discount != 0) 'discount': widget.discount,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Enviar email
      final success = await EmailService.sendTicketEmail(
        recipientEmail: email,
        plate: widget.plate,
        zone: widget.zone,
        start: widget.start,
        end: endTime,
        price: widget.price,
        method: widget.method,
        qrData: qrData,
        locale: Localizations.localeOf(context).languageCode,
        customSubject: 'Tu Ticket de Estacionamiento - ${widget.plate}',
        customMessage: 'Hemos procesado tu pago exitosamente. Adjunto encontrarás tu ticket de estacionamiento.',
      );
      
      if (success) {
        // Email enviado exitosamente
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => _EmailSentDialog(onClose: _startTimer),
        );
      } else {
        // Error al enviar email
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error al enviar el email'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        _startTimer();
      }
      
    } catch (e) {
      // Error inesperado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      _startTimer();
    }
  }

  Future<void> _showSmsDialog() async {
    _pauseTimer();
    final phone = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SmsDialog(),
    );
    if (!mounted) return;
    if (phone != null) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📱 Enviando WhatsApp...'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );

        final endTime = widget.start.add(Duration(minutes: widget.minutes));
        
        // Enviar solo usando el servicio API de WhatsApp
        bool success = await WhatsAppService.sendTicketWhatsApp(
          phone: phone,
          plate: widget.plate,
          zone: widget.zone,
          start: widget.start,
          end: endTime,
          price: widget.price,
          method: widget.method,
          discount: widget.discount,
          qrData:
              'ticket|plate:${widget.plate}|zone:${widget.zone}|start:${widget.start.toIso8601String()}|end:${endTime.toIso8601String()}|price:${widget.price}${widget.discount != null && widget.discount != 0 ? '|discount:${widget.discount}' : ''}',
          localeCode: AppLocalizations.of(context).locale.toString(),
        );

        if (success) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => _SmsSentDialog(onClose: _startTimer),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error al enviar por WhatsApp'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          _startTimer();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        _startTimer();
      }
    } else {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = l.t;
    final finish = widget.start.add(Duration(minutes: widget.minutes));
    final localeCode = l.locale.languageCode == 'es'
        ? 'es_ES'
        : l.locale.languageCode == 'ca'
            ? 'ca_ES'
            : 'en_US';
    final timeFormat = l.locale.languageCode == 'en'
        ? DateFormat('MMM d, yyyy – HH:mm', localeCode)
        : DateFormat('d MMM yyyy – HH:mm', localeCode);
    // Use our custom formatPrice function instead of NumberFormat
    final methodMap = {
      'card': t('card'),
      'qr': t('qrPay'),
      'mobile': t('mobilePay'),
      'cash': l.locale.languageCode == 'es'
          ? 'Efectivo'
          : l.locale.languageCode == 'ca'
              ? 'Efectiu'
              : 'Cash',
      'bizum': 'Bizum',
    };
    final ticketJson =
        'ticket|plate:${widget.plate}|zone:${widget.zone}|start:${widget.start.toIso8601String()}|end:${finish.toIso8601String()}|price:${widget.price}${widget.discount != null && widget.discount != 0 ? '|discount:${widget.discount}' : ''}';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Contenido principal, centralizado y con ancho máx fijo
    Widget mainContent(double width, double height) {
      final isMobile = width < 500;
      final safeWidth = width > 550 ? 500.0 : width * 0.97;
      final qrSize = safeWidth * (isMobile ? 0.6 : 0.38);
      final titleFont = safeWidth * (isMobile ? 0.065 : 0.055);
      final subFont = safeWidth * (isMobile ? 0.055 : 0.038);
      final gap = safeWidth * (isMobile ? 0.03 : 0.035);

      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: safeWidth,
            minWidth: 220,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/success.json',
                height: qrSize * 0.5,
                repeat: false,
              ),
              SizedBox(height: gap / 2),
              AutoSizeText(
                t('paymentSuccess'),
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: titleFont,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: gap / 2),
              Center(
                child: QrImageView(
                  data: ticketJson,
                  size: qrSize,
                  foregroundColor: isDark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: gap),
              // Tarjeta resumen
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(gap * 0.9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AutoSizeText(
                        t('ticketSummary'),
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: subFont,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AutoSizeText(
                        "${t('plate')}: ${widget.plate}",
                        maxLines: 1,
                        style: TextStyle(fontSize: subFont - 2),
                      ),
                      AutoSizeText(
                        "${t('zone')}: ${_getZoneName(widget.zone, t)}",
                        maxLines: 1,
                        style: TextStyle(fontSize: subFont - 3),
                      ),
                      AutoSizeText(
                        "${t('startTime')}: ${timeFormat.format(widget.start)}",
                        maxLines: 1,
                        style: TextStyle(fontSize: subFont - 4),
                      ),
                      AutoSizeText(
                        "${t('endTime')}: ${timeFormat.format(finish)}",
                        maxLines: 1,
                        style: TextStyle(fontSize: subFont - 4),
                      ),
                      AutoSizeText(
                        "${t('totalPrice')}: ${formatPrice(widget.price, localeCode)}",
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: subFont - 3,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if ((widget.discount ?? 0) != 0) ...[
                        AutoSizeText(
                          "${t('discount')}: ${formatPrice(widget.discount!, localeCode)}",
                          maxLines: 1,
                          style: TextStyle(fontSize: subFont - 3, color: Colors.green),
                        ),
                      ],
                      AutoSizeText(
                        "${t('paymentMethod')}: ${methodMap[widget.method] ?? widget.method}",
                        maxLines: 1,
                        style: TextStyle(fontSize: subFont - 3),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: gap),
              // Botones de acción
              Wrap(
                spacing: gap,
                runSpacing: gap / 2,
                alignment: WrapAlignment.center,
                children: [
                  SizedBox(
                    width: (safeWidth - gap * 1.5) / 2,
                    child: FilledButton(
                      onPressed: () async {
                        SoundHelper.playTap();
                        await _printTicket();
                      },
                      style: kMowizFilledButtonStyle.copyWith(
                        textStyle: MaterialStatePropertyAll(
                          TextStyle(fontSize: subFont - 5),
                        ),
                      ),
                      child: AutoSizeText(t('printTicket'), maxLines: 1),
                    ),
                  ),
                  SizedBox(
                    width: (safeWidth - gap * 1.5) / 2,
                    child: FilledButton(
                      onPressed: () {
                        SoundHelper.playTap();
                        _showWhatsAppDialogWithStates();
                      },
                      style: kMowizFilledButtonStyle.copyWith(
                        textStyle: MaterialStatePropertyAll(
                          TextStyle(fontSize: subFont - 5),
                        ),
                      ),
                      child: AutoSizeText(t('sendBySms'), maxLines: 1),
                    ),
                  ),
                  SizedBox(
                    width: (safeWidth - gap * 1.5) / 2,
                    child: FilledButton(
                      onPressed: () {
                        SoundHelper.playTap();
                        _showEmailDialog();
                      },
                      style: kMowizFilledButtonStyle.copyWith(
                        textStyle: MaterialStatePropertyAll(
                          TextStyle(fontSize: subFont - 5),
                        ),
                      ),
                      child: AutoSizeText(t('sendByEmail'), maxLines: 1),
                    ),
                  ),
                  SizedBox(
                    width: (safeWidth - gap * 1.5) / 2,
                    child: FilledButton(
                      onPressed: () {
                        SoundHelper.playTap();
                        _goHome();
                      },
                      style: kMowizFilledButtonStyle.copyWith(
                        textStyle: MaterialStatePropertyAll(
                          TextStyle(fontSize: subFont - 5),
                        ),
                      ),
                      child: AutoSizeText(t('home'), maxLines: 1),
                    ),
                  ),
                ],
              ),
              SizedBox(height: gap * 1.2),
              // Temporizador de retorno
              AutoSizeText(
                t('returningIn', params: {'seconds': '$_seconds'}),
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: subFont - 3),
              ),
            ],
          ),
        ),
      );
    }

    return MowizScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          // Detecta si necesita scroll: si el contenido es mayor que la ventana
          final main = mainContent(width, height);
          // Estimamos la altura mínima que requiere el contenido principal
          final minMainHeight = 800.0; // puedes ajustar este valor a tu caso
          final needsScroll = height < minMainHeight;

          return Stack(
            children: [
              // Animación de éxito elegante
              if (_showSuccessAnimation)
                Positioned(
                  top: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SuccessCheckAnimation(
                      size: 150,
                      color: Colors.green,
                      animationDuration: const Duration(milliseconds: 4000),
                      onAnimationComplete: () {
                        setState(() {
                          _showSuccessAnimation = false;
                        });
                      },
                    ),
                  ),
                ),
              if (needsScroll)
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: main,
                  ),
                )
              else
                main,
            ],
          );
        },
      ),
    );
  }
}

// NUEVOS DIÁLOGOS CON ESTADOS

enum DialogState { input, sending, success, error }

// Diálogo mejorado para email con estados
class _EmailDialogWithStates extends StatefulWidget {
  final String plate;
  final String zone;
  final DateTime start;
  final int minutes;
  final double price;
  final String method;
  final double? discount;
  
  const _EmailDialogWithStates({
    required this.plate,
    required this.zone,
    required this.start,
    required this.minutes,
    required this.price,
    required this.method,
    this.discount,
  });

  @override
  State<_EmailDialogWithStates> createState() => _EmailDialogWithStatesState();
}

class _EmailDialogWithStatesState extends State<_EmailDialogWithStates> {
  DialogState _state = DialogState.input;
  String _email = '';
  String? _errorMessage;

  Future<void> _sendEmail() async {
    setState(() => _state = DialogState.sending);
    
    try {
      final endTime = widget.start.add(Duration(minutes: widget.minutes));
      
      bool success = await EmailService.sendTicketEmail(
        recipientEmail: _email.trim(),
        plate: widget.plate,
        zone: widget.zone,
        start: widget.start,
        end: endTime,
        price: widget.price,
        method: widget.method,
        qrData: 'ticket|plate:${widget.plate}|zone:${widget.zone}|start:${widget.start.toIso8601String()}|end:${endTime.toIso8601String()}|price:${widget.price}${widget.discount != null && widget.discount != 0 ? '|discount:${widget.discount}' : ''}',
        locale: AppLocalizations.of(context).locale.languageCode,
      );
      
      if (success) {
        setState(() => _state = DialogState.success);
      } else {
        setState(() {
          _state = DialogState.error;
          _errorMessage = 'Error al enviar el email';
        });
      }
    } catch (e) {
      setState(() {
        _state = DialogState.error;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    
    return AlertDialog(
      title: Text(l.t('enterEmail')),
      content: _buildContent(l),
      actions: _buildActions(l),
    );
  }

  Widget _buildContent(AppLocalizations l) {
    switch (_state) {
      case DialogState.input:
        return TextField(
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          onChanged: (v) => _email = v,
          decoration: InputDecoration(
            hintText: 'ejemplo@email.com',
            border: OutlineInputBorder(),
          ),
        );
        
      case DialogState.sending:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(l.t('sendingEmail')),
            SizedBox(height: 8),
            Text(l.t('pleaseWait'), style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        );
        
      case DialogState.success:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 48),
            SizedBox(height: 16),
            Text(l.t('sendSuccess')),
            SizedBox(height: 8),
            Text(l.t('emailSent')),
          ],
        );
        
      case DialogState.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(l.t('sendError')),
            SizedBox(height: 8),
            Text(_errorMessage ?? 'Error desconocido', style: TextStyle(fontSize: 12)),
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
            onPressed: _sendEmail, // ✅ CORREGIDO: Botón siempre habilitado
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

// Diálogo para ingresar el teléfono
class _SmsDialog extends StatefulWidget {
  const _SmsDialog();

  @override
  State<_SmsDialog> createState() => _SmsDialogState();
}

class _SmsDialogState extends State<_SmsDialog> {
  String _phone = '';

  String _formatPhoneNumber(String phone) {
    // Remover todos los caracteres no numéricos
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Si empieza con 34 (España), mantenerlo
    if (cleanPhone.startsWith('34')) {
      return '+$cleanPhone';
    }
    // Si empieza con 6, 7, 8, 9 (móviles españoles), agregar +34
    else if (cleanPhone.startsWith(RegExp(r'[6789]')) && cleanPhone.length == 9) {
      return '+34$cleanPhone';
    }
    // Si tiene 9 dígitos y no empieza con 34, agregar +34
    else if (cleanPhone.length == 9) {
      return '+34$cleanPhone';
    }
    // Si ya tiene el formato correcto, devolverlo
    else if (cleanPhone.startsWith('34') && cleanPhone.length == 11) {
      return '+$cleanPhone';
    }
    // En otros casos, devolver tal como está
    return cleanPhone;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.t('enterPhone')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            autofocus: true,
            keyboardType: TextInputType.phone,
            onChanged: (v) => _phone = v,
            decoration: const InputDecoration(
              hintText: 'Ej: 612345678 o +34612345678',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Formato detectado: ${_formatPhoneNumber(_phone)}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            SoundHelper.playTap();
            Navigator.pop(context);
          },
          child: Text(l.t('close')),
        ),
        ElevatedButton(
          onPressed: () {
            SoundHelper.playTap();
            final formattedPhone = _formatPhoneNumber(_phone.trim());
            print('📱 Número formateado: $formattedPhone');
            Navigator.pop(context, formattedPhone);
          },
          child: Text(l.t('send')),
        ),
      ],
    );
  }
}

// Diálogo de confirmación de email enviado
class _EmailSentDialog extends StatefulWidget {
  final VoidCallback onClose;
  const _EmailSentDialog({required this.onClose});

  @override
  State<_EmailSentDialog> createState() => _EmailSentDialogState();
}

class _EmailSentDialogState extends State<_EmailSentDialog> {
  int _seconds = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds > 1) {
        setState(() => _seconds--);
      } else {
        t.cancel();
        if (mounted) {
          Navigator.of(context).pop();
          widget.onClose();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.t('emailSent')),
          const SizedBox(height: 8),
          Text(l.t('returningIn', params: {'seconds': '$_seconds'})),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            SoundHelper.playTap();
            Navigator.of(context).pop();
            widget.onClose();
          },
          child: Text(l.t('close')),
        ),
      ],
    );
  }
}

// Diálogo de confirmación de SMS enviado
class _SmsSentDialog extends StatefulWidget {
  final VoidCallback onClose;
  const _SmsSentDialog({required this.onClose});

  @override
  State<_SmsSentDialog> createState() => _SmsSentDialogState();
}

class _SmsSentDialogState extends State<_SmsSentDialog> {
  int _seconds = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds > 1) {
        setState(() => _seconds--);
      } else {
        t.cancel();
        if (mounted) {
          Navigator.of(context).pop();
          widget.onClose();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.t('smsSent')),
          const SizedBox(height: 8),
          Text(l.t('returningIn', params: {'seconds': '$_seconds'})),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            SoundHelper.playTap();
            Navigator.of(context).pop();
            widget.onClose();
          },
          child: Text(l.t('close')),
        ),
      ],
    );
  }
}

// Diálogo mejorado para WhatsApp con estados
class _WhatsAppDialogWithStates extends StatefulWidget {
  final String plate;
  final String zone;
  final DateTime start;
  final int minutes;
  final double price;
  final String method;
  final double? discount;
  
  const _WhatsAppDialogWithStates({
    required this.plate,
    required this.zone,
    required this.start,
    required this.minutes,
    required this.price,
    required this.method,
    this.discount,
  });

  @override
  State<_WhatsAppDialogWithStates> createState() => _WhatsAppDialogWithStatesState();
}

class _WhatsAppDialogWithStatesState extends State<_WhatsAppDialogWithStates> {
  DialogState _state = DialogState.input;
  String _phone = '';
  String? _errorMessage;

  Future<void> _sendWhatsApp() async {
    setState(() => _state = DialogState.sending);
    
    try {
      final endTime = widget.start.add(Duration(minutes: widget.minutes));
      
      bool success = await WhatsAppService.sendTicketWhatsApp(
        phone: _phone.trim(),
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
      } else {
        setState(() {
          _state = DialogState.error;
          _errorMessage = 'Error al enviar el WhatsApp';
        });
      }
    } catch (e) {
      setState(() {
        _state = DialogState.error;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    
    return AlertDialog(
      title: Text(l.t('sendTicketSms')),
      content: _buildContent(l),
      actions: _buildActions(l),
    );
  }

  Widget _buildContent(AppLocalizations l) {
    switch (_state) {
      case DialogState.input:
        return TextField(
          autofocus: true,
          keyboardType: TextInputType.phone,
          onChanged: (v) => _phone = v,
          decoration: InputDecoration(
            hintText: '+34 123 456 789',
            border: OutlineInputBorder(),
          ),
        );
        
      case DialogState.sending:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(l.t('sendingWhatsApp')),
            SizedBox(height: 8),
            Text(l.t('pleaseWait'), style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        );
        
      case DialogState.success:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 48),
            SizedBox(height: 16),
            Text(l.t('sendSuccess')),
            SizedBox(height: 8),
            Text(l.t('whatsappSent')), // Traducción específica para WhatsApp
          ],
        );
        
      case DialogState.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(l.t('sendError')),
            SizedBox(height: 8),
            Text(_errorMessage ?? 'Error desconocido', style: TextStyle(fontSize: 12)),
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
            onPressed: _sendWhatsApp, // ✅ CORREGIDO: Botón siempre habilitado
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