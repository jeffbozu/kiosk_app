import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:intl/intl.dart';
// import 'package:lottie/lottie.dart'; // Removido - ya no se usa
import 'package:qr_flutter/qr_flutter.dart';
// import 'widgets/success_check_animation.dart'; // Removido para mejorar diseño

import 'l10n/app_localizations.dart';
import 'mowiz_page.dart';
import 'mowiz/mowiz_scaffold.dart';
import 'styles/mowiz_design_system.dart';
import 'sound_helper.dart';
import 'services/unified_service.dart';
import 'services/email_service.dart';
import 'services/whatsapp_service.dart';
// import 'services/sms_service.dart'; // No se usa directamente
import 'widgets/sms_dialog.dart';

/// Helper function to format price with correct decimal separator based on locale
String formatPrice(double price, String locale) {
  if (locale.startsWith('es') || locale.startsWith('ca')) {
    // Use comma as decimal separator for Spanish and Catalan
    return '${price.toStringAsFixed(2).replaceAll('.', ',')} €';
  } else {
    // Use dot as decimal separator for English and others
    return '${price.toStringAsFixed(2)} €';
  }

  /// Genera datos QR con etiquetas traducidas según el idioma
  String _generateTranslatedQRData({
    required String plate,
    required String zone,
    required DateTime start,
    required DateTime end,
    required double price,
    required String method,
    double? discount,
    required String locale,
  }) {
    // Traducir etiquetas según el idioma
    String getLabel(String key) {
      switch (key) {
        case 'ticket':
          return 'Ticket';
        case 'plate':
          return 'Matrícula';
        case 'zone':
          return 'Zona';
        case 'start':
          return 'Hora de inicio';
        case 'end':
          return 'Hora de fin';
        case 'price':
          return 'Precio';
        case 'method':
          return 'Método de pago';
        case 'discount':
          return 'Descuento';
        case 'duration':
          return 'Duración';
        default:
          return key;
      }
    }

    // Formatear fechas según el idioma
    String formatDateTime(DateTime date) {
      final formatter = DateFormat('dd/MM/yyyy HH:mm', locale);
      return formatter.format(date);
    }

    // Formatear precio según el idioma
    String formatPrice(double price) {
      if (locale.startsWith('es') || locale.startsWith('ca')) {
        return '${price.toStringAsFixed(2).replaceAll('.', ',')} €';
      } else {
        return '${price.toStringAsFixed(2)} €';
      }
    }

    // Mapear zona
    String getZoneName(String zone) {
      switch (zone) {
        case 'coche':
          return 'Zona Coche';
        case 'moto':
          return 'Zona Moto';
        case 'camion':
          return 'Zona Camión';
        default:
          return zone;
      }
    }

    // Mapear método de pago
    String getMethodName(String method) {
      switch (method) {
        case 'qr':
          return 'QR';
        case 'card':
          return 'Tarjeta';
        case 'cash':
          return 'Efectivo';
        default:
          return method;
      }
    }

    // Generar datos QR traducidos
    final qrData = {
      getLabel('ticket'): 'Meypark',
      getLabel('plate'): plate,
      getLabel('zone'): getZoneName(zone),
      getLabel('start'): formatDateTime(start),
      getLabel('end'): formatDateTime(end),
      getLabel('price'): formatPrice(price),
      getLabel('method'): getMethodName(method),
      if (discount != null && discount != 0)
        getLabel('discount'): formatPrice(discount),
      'timestamp': DateTime.now().toIso8601String(),
    };

    return jsonEncode(qrData);
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
  // bool _showSuccessAnimation = true; // Removido para mejorar diseño

  @override
  void initState() {
    super.initState();
    print('🐛 DEBUG: MowizSuccessPage iniciado con zone: "${widget.zone}"');
    _startTimer();
  }

  /// Obtiene el nombre de la zona según el ID
  String _getZoneName(String zoneId, Function t) {
    print('🐛 DEBUG: Zone ID recibido en _getZoneName: "$zoneId"');
    print('🐛 DEBUG: Widget.zone en MowizSuccessPage: "${widget.zone}"');
    switch (zoneId) {
      case 'green':
        return t('zoneGreen');
      case 'blue':
        return t('zoneBlue');
      case 'coche':
        return t('zoneCoche');
      case 'moto':
        return t('zoneMoto');
      case 'camion':
        return t('zoneCamion');
      default:
        print(
          '🐛 DEBUG: Zone ID no reconocido: "$zoneId", devolviendo como fallback',
        );
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
    print('⏸️ Pausando timer - Segundos restantes: $_seconds');
    _timer?.cancel();
  }

  /// Reanuda el timer manteniendo el estado actual
  void _resumeTimer() {
    print('🔄 Reanudando timer - Segundos restantes: $_seconds');
    if (_seconds > 0) {
      _startTimer();
      print('✅ Timer reanudado correctamente');
    } else {
      print('⚠️ Timer no se puede reanudar - segundos: $_seconds');
    }
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

      // Generar QR con etiquetas traducidas
      final qrData = _generateTranslatedQRData(
        plate: widget.plate,
        zone: widget.zone,
        start: widget.start,
        end: endTime,
        price: widget.price,
        method: widget.method,
        discount: widget.discount,
        locale: AppLocalizations.of(context).locale.languageCode,
      );

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
      _resumeTimer();
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
        onClose: _resumeTimer,
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
        onClose: _resumeTimer,
      ),
    );
  }

  /// Muestra el diálogo de SMS con estados
  void _showSMSDialogWithStates() {
    _pauseTimer();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SMSDialogWithStates(
        plate: widget.plate,
        zone: widget.zone,
        start: widget.start,
        minutes: widget.minutes,
        price: widget.price,
        method: widget.method,
        discount: widget.discount,
        onClose: _resumeTimer,
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

      // Generar QR con etiquetas traducidas
      final qrData = _generateTranslatedQRData(
        plate: widget.plate,
        zone: widget.zone,
        start: widget.start,
        end: endTime,
        price: widget.price,
        method: widget.method,
        discount: widget.discount,
        locale: AppLocalizations.of(context).locale.languageCode,
      );

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
        customMessage:
            'Hemos procesado tu pago exitosamente. Adjunto encontrarás tu ticket de estacionamiento.',
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

        // Generar QR con etiquetas traducidas
        final qrData = _generateTranslatedQRData(
          plate: widget.plate,
          zone: widget.zone,
          start: widget.start,
          end: endTime,
          price: widget.price,
          method: widget.method,
          discount: widget.discount,
          locale: AppLocalizations.of(context).locale.languageCode,
        );

        // Enviar usando WhatsApp API
        bool success = await WhatsAppService.sendTicketWhatsApp(
          phone: phone,
          plate: widget.plate,
          zone: widget.zone,
          start: widget.start,
          end: endTime,
          price: widget.price,
          method: widget.method,
          discount: widget.discount,
          qrData: qrData,
          localeCode: AppLocalizations.of(context).locale.languageCode,
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

    // 🎨 Contenido principal usando sistema de diseño homogéneo
    Widget mainContent(double width, double height) {
      final contentWidth = MowizDesignSystem.getContentWidth(width);
      final horizontalPadding = MowizDesignSystem.getHorizontalPadding(
        contentWidth,
      );
      final spacing = MowizDesignSystem.getSpacing(width);
      final titleFontSize = MowizDesignSystem.getTitleFontSize(width);
      final bodyFontSize = MowizDesignSystem.getBodyFontSize(width);
      final labelFontSize = MowizDesignSystem.getSubtitleFontSize(width);

      // Tamaño del QR reducido en 30% para mejor diseño
      final qrSize =
          contentWidth * (MowizDesignSystem.isMobile(width) ? 0.30 : 0.20);

      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MowizDesignSystem.maxContentWidth,
            minWidth: MowizDesignSystem.minContentWidth,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Título con check al lado
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: titleFontSize + 10,
                    ),
                    SizedBox(width: spacing / 2),
                    AutoSizeText(
                      t('paymentSuccess'),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing / 2),
                Center(
                  child: QrImageView(
                    data: ticketJson,
                    size: qrSize,
                    foregroundColor: isDark ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: spacing),
                // Tarjeta resumen
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      MowizDesignSystem.borderRadiusXL,
                    ),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(MowizDesignSystem.paddingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AutoSizeText(
                          t('ticketSummary'),
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: labelFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: MowizDesignSystem.spacingS),
                        // Información reducida del ticket
                        AutoSizeText(
                          "${widget.plate} • ${_getZoneName(widget.zone, t)}",
                          maxLines: 1,
                          style: TextStyle(fontSize: bodyFontSize - 1),
                        ),
                        SizedBox(height: MowizDesignSystem.spacingXS),
                        AutoSizeText(
                          "${timeFormat.format(widget.start)} - ${timeFormat.format(finish)}",
                          maxLines: 1,
                          style: TextStyle(fontSize: bodyFontSize - 2),
                        ),
                        SizedBox(height: MowizDesignSystem.spacingS),
                        AutoSizeText(
                          "${t('totalPrice')}: ${formatPrice(widget.price, localeCode)}",
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: bodyFontSize - 3,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if ((widget.discount ?? 0) != 0) ...[
                          SizedBox(height: MowizDesignSystem.spacingXS),
                          AutoSizeText(
                            "${t('discount')}: ${formatPrice(widget.discount!, localeCode)}",
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: bodyFontSize - 3,
                              color: Colors.green,
                            ),
                          ),
                        ],
                        SizedBox(height: MowizDesignSystem.spacingXS),
                        AutoSizeText(
                          "${t('paymentMethod')}: ${methodMap[widget.method] ?? widget.method}",
                          maxLines: 1,
                          style: TextStyle(fontSize: bodyFontSize - 3),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: spacing),
                // Botones de acción en layout compacto
                Column(
                  children: [
                    // Primera fila de botones principales
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              SoundHelper.playTap();
                              await _printTicket();
                            },
                            style: MowizDesignSystem.getSecondaryButtonStyle(
                              width: width,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                            ),
                            child: AutoSizeText(t('printTicket'), maxLines: 1),
                          ),
                        ),
                        SizedBox(width: spacing / 2),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              SoundHelper.playTap();
                              _showWhatsAppDialogWithStates();
                            },
                            style: MowizDesignSystem.getSecondaryButtonStyle(
                              width: width,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onSecondary,
                            ),
                            child: AutoSizeText('📱 WhatsApp', maxLines: 1),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing / 2),
                    // Segunda fila de botones
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              SoundHelper.playTap();
                              _showSMSDialogWithStates();
                            },
                            style: MowizDesignSystem.getSecondaryButtonStyle(
                              width: width,
                              backgroundColor: const Color(
                                0xFFE62144,
                              ), // Rojo corporativo
                              foregroundColor: Colors.white,
                            ),
                            child: AutoSizeText('📱 SMS', maxLines: 1),
                          ),
                        ),
                        SizedBox(width: spacing / 2),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              SoundHelper.playTap();
                              _showEmailDialog();
                            },
                            style: MowizDesignSystem.getSecondaryButtonStyle(
                              width: width,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.tertiary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onTertiary,
                            ),
                            child: AutoSizeText('📧 Email', maxLines: 1),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing / 2),
                    // Botón de inicio centrado
                    SizedBox(
                      width: width * 0.6,
                      child: FilledButton(
                        onPressed: () {
                          SoundHelper.playTap();
                          _goHome();
                        },
                        style: MowizDesignSystem.getSecondaryButtonStyle(
                          width: width,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onSurface,
                        ),
                        child: AutoSizeText(t('home'), maxLines: 1),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing * 1.2),
                // Temporizador de retorno
                AutoSizeText(
                  t('returningIn', params: {'seconds': '$_seconds'}),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: bodyFontSize - 3),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MowizScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          // 🎨 Usar scroll inteligente del sistema de diseño
          return MowizDesignSystem.getScrollableContent(
            availableHeight: height,
            contentHeight: 700, // Altura reducida para diseño más compacto
            child: mainContent(width, height),
          );
        },
      ),
    );
  }

  /// Genera datos QR con etiquetas traducidas según el idioma
  String _generateTranslatedQRData({
    required String plate,
    required String zone,
    required DateTime start,
    required DateTime end,
    required double price,
    required String method,
    double? discount,
    required String locale,
  }) {
    // Traducir etiquetas según el idioma
    String getLabel(String key) {
      switch (key) {
        case 'ticket':
          return 'Ticket';
        case 'plate':
          return 'Matrícula';
        case 'zone':
          return 'Zona';
        case 'start':
          return 'Hora de inicio';
        case 'end':
          return 'Hora de fin';
        case 'price':
          return 'Precio';
        case 'method':
          return 'Método de pago';
        case 'discount':
          return 'Descuento';
        case 'duration':
          return 'Duración';
        default:
          return key;
      }
    }

    // Formatear fechas según el idioma
    String formatDateTime(DateTime date) {
      final formatter = DateFormat('dd/MM/yyyy HH:mm', locale);
      return formatter.format(date);
    }

    // Formatear precio según el idioma
    String formatPrice(double price) {
      if (locale.startsWith('es') || locale.startsWith('ca')) {
        return '${price.toStringAsFixed(2).replaceAll('.', ',')} €';
      } else {
        return '${price.toStringAsFixed(2)} €';
      }
    }

    // Mapear zona
    String getZoneName(String zone) {
      switch (zone) {
        case 'coche':
          return 'Zona Coche';
        case 'moto':
          return 'Zona Moto';
        case 'camion':
          return 'Zona Camión';
        default:
          return zone;
      }
    }

    // Mapear método de pago
    String getMethodName(String method) {
      switch (method) {
        case 'qr':
          return 'QR';
        case 'card':
          return 'Tarjeta';
        case 'cash':
          return 'Efectivo';
        default:
          return method;
      }
    }

    // Generar datos QR traducidos
    final qrData = {
      getLabel('ticket'): 'Meypark',
      getLabel('plate'): plate,
      getLabel('zone'): getZoneName(zone),
      getLabel('start'): formatDateTime(start),
      getLabel('end'): formatDateTime(end),
      getLabel('price'): formatPrice(price),
      getLabel('method'): getMethodName(method),
      if (discount != null && discount != 0)
        getLabel('discount'): formatPrice(discount),
      'timestamp': DateTime.now().toIso8601String(),
    };

    return jsonEncode(qrData);
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
  final VoidCallback? onClose;

  const _EmailDialogWithStates({
    required this.plate,
    required this.zone,
    required this.start,
    required this.minutes,
    required this.price,
    required this.method,
    this.discount,
    this.onClose,
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
        qrData:
            'ticket|plate:${widget.plate}|zone:${widget.zone}|start:${widget.start.toIso8601String()}|end:${endTime.toIso8601String()}|price:${widget.price}${widget.discount != null && widget.discount != 0 ? '|discount:${widget.discount}' : ''}',
        locale: AppLocalizations.of(context).locale.languageCode,
      );

      if (success) {
        setState(() => _state = DialogState.success);
        // Reanudar temporizador después de 2 segundos
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) widget.onClose?.call();
        });
      } else {
        setState(() {
          _state = DialogState.error;
          _errorMessage = 'Error al enviar el email';
        });
        // Reanudar temporizador después de 2 segundos
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) widget.onClose?.call();
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
            Text(
              l.t('pleaseWait'),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
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
            Text(
              _errorMessage ?? 'Error desconocido',
              style: TextStyle(fontSize: 12),
            ),
          ],
        );
    }
  }

  List<Widget> _buildActions(AppLocalizations l) {
    switch (_state) {
      case DialogState.input:
        return [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onClose?.call();
            },
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
            onPressed: () {
              Navigator.pop(context);
              widget.onClose?.call();
            },
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
            onPressed: () {
              Navigator.pop(context);
              widget.onClose?.call();
            },
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

  /// Genera datos QR con etiquetas traducidas según el idioma
  String _generateTranslatedQRData({
    required String plate,
    required String zone,
    required DateTime start,
    required DateTime end,
    required double price,
    required String method,
    double? discount,
    required String locale,
  }) {
    // Traducir etiquetas según el idioma
    String getLabel(String key) {
      switch (key) {
        case 'ticket':
          return 'Ticket';
        case 'plate':
          return 'Matrícula';
        case 'zone':
          return 'Zona';
        case 'start':
          return 'Hora de inicio';
        case 'end':
          return 'Hora de fin';
        case 'price':
          return 'Precio';
        case 'method':
          return 'Método de pago';
        case 'discount':
          return 'Descuento';
        case 'duration':
          return 'Duración';
        default:
          return key;
      }
    }

    // Formatear fechas según el idioma
    String formatDateTime(DateTime date) {
      final formatter = DateFormat('dd/MM/yyyy HH:mm', locale);
      return formatter.format(date);
    }

    // Formatear precio según el idioma
    String formatPrice(double price) {
      if (locale.startsWith('es') || locale.startsWith('ca')) {
        return '${price.toStringAsFixed(2).replaceAll('.', ',')} €';
      } else {
        return '${price.toStringAsFixed(2)} €';
      }
    }

    // Mapear zona
    String getZoneName(String zone) {
      switch (zone) {
        case 'coche':
          return 'Zona Coche';
        case 'moto':
          return 'Zona Moto';
        case 'camion':
          return 'Zona Camión';
        default:
          return zone;
      }
    }

    // Mapear método de pago
    String getMethodName(String method) {
      switch (method) {
        case 'qr':
          return 'QR';
        case 'card':
          return 'Tarjeta';
        case 'cash':
          return 'Efectivo';
        default:
          return method;
      }
    }

    // Generar datos QR traducidos
    final qrData = {
      getLabel('ticket'): 'Meypark',
      getLabel('plate'): plate,
      getLabel('zone'): getZoneName(zone),
      getLabel('start'): formatDateTime(start),
      getLabel('end'): formatDateTime(end),
      getLabel('price'): formatPrice(price),
      getLabel('method'): getMethodName(method),
      if (discount != null && discount != 0)
        getLabel('discount'): formatPrice(discount),
      'timestamp': DateTime.now().toIso8601String(),
    };

    return jsonEncode(qrData);
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
    else if (cleanPhone.startsWith(RegExp(r'[6789]')) &&
        cleanPhone.length == 9) {
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

  /// Genera datos QR con etiquetas traducidas según el idioma
  String _generateTranslatedQRData({
    required String plate,
    required String zone,
    required DateTime start,
    required DateTime end,
    required double price,
    required String method,
    double? discount,
    required String locale,
  }) {
    // Traducir etiquetas según el idioma
    String getLabel(String key) {
      switch (key) {
        case 'ticket':
          return 'Ticket';
        case 'plate':
          return 'Matrícula';
        case 'zone':
          return 'Zona';
        case 'start':
          return 'Hora de inicio';
        case 'end':
          return 'Hora de fin';
        case 'price':
          return 'Precio';
        case 'method':
          return 'Método de pago';
        case 'discount':
          return 'Descuento';
        case 'duration':
          return 'Duración';
        default:
          return key;
      }
    }

    // Formatear fechas según el idioma
    String formatDateTime(DateTime date) {
      final formatter = DateFormat('dd/MM/yyyy HH:mm', locale);
      return formatter.format(date);
    }

    // Formatear precio según el idioma
    String formatPrice(double price) {
      if (locale.startsWith('es') || locale.startsWith('ca')) {
        return '${price.toStringAsFixed(2).replaceAll('.', ',')} €';
      } else {
        return '${price.toStringAsFixed(2)} €';
      }
    }

    // Mapear zona
    String getZoneName(String zone) {
      switch (zone) {
        case 'coche':
          return 'Zona Coche';
        case 'moto':
          return 'Zona Moto';
        case 'camion':
          return 'Zona Camión';
        default:
          return zone;
      }
    }

    // Mapear método de pago
    String getMethodName(String method) {
      switch (method) {
        case 'qr':
          return 'QR';
        case 'card':
          return 'Tarjeta';
        case 'cash':
          return 'Efectivo';
        default:
          return method;
      }
    }

    // Generar datos QR traducidos
    final qrData = {
      getLabel('ticket'): 'Meypark',
      getLabel('plate'): plate,
      getLabel('zone'): getZoneName(zone),
      getLabel('start'): formatDateTime(start),
      getLabel('end'): formatDateTime(end),
      getLabel('price'): formatPrice(price),
      getLabel('method'): getMethodName(method),
      if (discount != null && discount != 0)
        getLabel('discount'): formatPrice(discount),
      'timestamp': DateTime.now().toIso8601String(),
    };

    return jsonEncode(qrData);
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

  /// Genera datos QR con etiquetas traducidas según el idioma
  String _generateTranslatedQRData({
    required String plate,
    required String zone,
    required DateTime start,
    required DateTime end,
    required double price,
    required String method,
    double? discount,
    required String locale,
  }) {
    // Traducir etiquetas según el idioma
    String getLabel(String key) {
      switch (key) {
        case 'ticket':
          return 'Ticket';
        case 'plate':
          return 'Matrícula';
        case 'zone':
          return 'Zona';
        case 'start':
          return 'Hora de inicio';
        case 'end':
          return 'Hora de fin';
        case 'price':
          return 'Precio';
        case 'method':
          return 'Método de pago';
        case 'discount':
          return 'Descuento';
        case 'duration':
          return 'Duración';
        default:
          return key;
      }
    }

    // Formatear fechas según el idioma
    String formatDateTime(DateTime date) {
      final formatter = DateFormat('dd/MM/yyyy HH:mm', locale);
      return formatter.format(date);
    }

    // Formatear precio según el idioma
    String formatPrice(double price) {
      if (locale.startsWith('es') || locale.startsWith('ca')) {
        return '${price.toStringAsFixed(2).replaceAll('.', ',')} €';
      } else {
        return '${price.toStringAsFixed(2)} €';
      }
    }

    // Mapear zona
    String getZoneName(String zone) {
      switch (zone) {
        case 'coche':
          return 'Zona Coche';
        case 'moto':
          return 'Zona Moto';
        case 'camion':
          return 'Zona Camión';
        default:
          return zone;
      }
    }

    // Mapear método de pago
    String getMethodName(String method) {
      switch (method) {
        case 'qr':
          return 'QR';
        case 'card':
          return 'Tarjeta';
        case 'cash':
          return 'Efectivo';
        default:
          return method;
      }
    }

    // Generar datos QR traducidos
    final qrData = {
      getLabel('ticket'): 'Meypark',
      getLabel('plate'): plate,
      getLabel('zone'): getZoneName(zone),
      getLabel('start'): formatDateTime(start),
      getLabel('end'): formatDateTime(end),
      getLabel('price'): formatPrice(price),
      getLabel('method'): getMethodName(method),
      if (discount != null && discount != 0)
        getLabel('discount'): formatPrice(discount),
      'timestamp': DateTime.now().toIso8601String(),
    };

    return jsonEncode(qrData);
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

  /// Genera datos QR con etiquetas traducidas según el idioma
  String _generateTranslatedQRData({
    required String plate,
    required String zone,
    required DateTime start,
    required DateTime end,
    required double price,
    required String method,
    double? discount,
    required String locale,
  }) {
    // Traducir etiquetas según el idioma
    String getLabel(String key) {
      switch (key) {
        case 'ticket':
          return 'Ticket';
        case 'plate':
          return 'Matrícula';
        case 'zone':
          return 'Zona';
        case 'start':
          return 'Hora de inicio';
        case 'end':
          return 'Hora de fin';
        case 'price':
          return 'Precio';
        case 'method':
          return 'Método de pago';
        case 'discount':
          return 'Descuento';
        case 'duration':
          return 'Duración';
        default:
          return key;
      }
    }

    // Formatear fechas según el idioma
    String formatDateTime(DateTime date) {
      final formatter = DateFormat('dd/MM/yyyy HH:mm', locale);
      return formatter.format(date);
    }

    // Formatear precio según el idioma
    String formatPrice(double price) {
      if (locale.startsWith('es') || locale.startsWith('ca')) {
        return '${price.toStringAsFixed(2).replaceAll('.', ',')} €';
      } else {
        return '${price.toStringAsFixed(2)} €';
      }
    }

    // Mapear zona
    String getZoneName(String zone) {
      switch (zone) {
        case 'coche':
          return 'Zona Coche';
        case 'moto':
          return 'Zona Moto';
        case 'camion':
          return 'Zona Camión';
        default:
          return zone;
      }
    }

    // Mapear método de pago
    String getMethodName(String method) {
      switch (method) {
        case 'qr':
          return 'QR';
        case 'card':
          return 'Tarjeta';
        case 'cash':
          return 'Efectivo';
        default:
          return method;
      }
    }

    // Generar datos QR traducidos
    final qrData = {
      getLabel('ticket'): 'Meypark',
      getLabel('plate'): plate,
      getLabel('zone'): getZoneName(zone),
      getLabel('start'): formatDateTime(start),
      getLabel('end'): formatDateTime(end),
      getLabel('price'): formatPrice(price),
      getLabel('method'): getMethodName(method),
      if (discount != null && discount != 0)
        getLabel('discount'): formatPrice(discount),
      'timestamp': DateTime.now().toIso8601String(),
    };

    return jsonEncode(qrData);
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
  final VoidCallback? onClose;

  const _WhatsAppDialogWithStates({
    required this.plate,
    required this.zone,
    required this.start,
    required this.minutes,
    required this.price,
    required this.method,
    this.discount,
    this.onClose,
  });

  @override
  State<_WhatsAppDialogWithStates> createState() =>
      _WhatsAppDialogWithStatesState();
}

class _WhatsAppDialogWithStatesState extends State<_WhatsAppDialogWithStates> {
  DialogState _state = DialogState.input;
  String _phone = '';
  String? _errorMessage;

  Future<void> _sendWhatsApp() async {
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

      print('📱 WhatsApp Dialog - Número original: ${_phone.trim()}');
      print('📱 WhatsApp Dialog - Número formateado: $formattedPhone');

      bool success = await WhatsAppService.sendTicketWhatsApp(
        phone: formattedPhone,
        plate: widget.plate,
        zone: widget.zone,
        start: widget.start,
        end: endTime,
        price: widget.price,
        method: widget.method,
        discount: widget.discount,
        localeCode: AppLocalizations.of(context).locale.languageCode,
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
          _errorMessage = 'Error al enviar el WhatsApp';
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
            Text(
              l.t('pleaseWait'),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
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
            Text(
              _errorMessage ?? 'Error desconocido',
              style: TextStyle(fontSize: 12),
            ),
          ],
        );
    }
  }

  List<Widget> _buildActions(AppLocalizations l) {
    switch (_state) {
      case DialogState.input:
        return [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onClose?.call();
            },
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
            onPressed: () {
              Navigator.pop(context);
              widget.onClose?.call();
            },
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
            onPressed: () {
              Navigator.pop(context);
              widget.onClose?.call();
            },
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

  /// Genera datos QR con etiquetas traducidas según el idioma
  String _generateTranslatedQRData({
    required String plate,
    required String zone,
    required DateTime start,
    required DateTime end,
    required double price,
    required String method,
    double? discount,
    required String locale,
  }) {
    // Traducir etiquetas según el idioma
    String getLabel(String key) {
      switch (key) {
        case 'ticket':
          return 'Ticket';
        case 'plate':
          return 'Matrícula';
        case 'zone':
          return 'Zona';
        case 'start':
          return 'Hora de inicio';
        case 'end':
          return 'Hora de fin';
        case 'price':
          return 'Precio';
        case 'method':
          return 'Método de pago';
        case 'discount':
          return 'Descuento';
        case 'duration':
          return 'Duración';
        default:
          return key;
      }
    }

    // Formatear fechas según el idioma
    String formatDateTime(DateTime date) {
      final formatter = DateFormat('dd/MM/yyyy HH:mm', locale);
      return formatter.format(date);
    }

    // Formatear precio según el idioma
    String formatPrice(double price) {
      if (locale.startsWith('es') || locale.startsWith('ca')) {
        return '${price.toStringAsFixed(2).replaceAll('.', ',')} €';
      } else {
        return '${price.toStringAsFixed(2)} €';
      }
    }

    // Mapear zona
    String getZoneName(String zone) {
      switch (zone) {
        case 'coche':
          return 'Zona Coche';
        case 'moto':
          return 'Zona Moto';
        case 'camion':
          return 'Zona Camión';
        default:
          return zone;
      }
    }

    // Mapear método de pago
    String getMethodName(String method) {
      switch (method) {
        case 'qr':
          return 'QR';
        case 'card':
          return 'Tarjeta';
        case 'cash':
          return 'Efectivo';
        default:
          return method;
      }
    }

    // Generar datos QR traducidos
    final qrData = {
      getLabel('ticket'): 'Meypark',
      getLabel('plate'): plate,
      getLabel('zone'): getZoneName(zone),
      getLabel('start'): formatDateTime(start),
      getLabel('end'): formatDateTime(end),
      getLabel('price'): formatPrice(price),
      getLabel('method'): getMethodName(method),
      if (discount != null && discount != 0)
        getLabel('discount'): formatPrice(discount),
      'timestamp': DateTime.now().toIso8601String(),
    };

    return jsonEncode(qrData);
  }
}
