import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const supportedLocales = [
    Locale('es'),
    Locale('ca'),
    Locale('en'),
  ];

  static const _localizedValues = <String, Map<String, String>>{
    'es': {
      'welcome': 'Bienvenido a Meypar Optima App',
      'email': 'Email',
      'password': 'Contraseña',
      'signIn': 'Iniciar sesión',
      'invalidEmail': 'La dirección de correo tiene un formato incorrecto.',
      'userDisabled': 'La cuenta de usuario está desactivada.',
      'userNotFound': 'No existe ningún usuario con ese correo.',
      'wrongPassword': 'Correo o contraseña incorrectos.',
      'tooManyRequests': 'Se han intentado demasiados accesos. Intenta más tarde.',
      'invalidCredential': 'La credencial proporcionada es incorrecta o ha expirado.',
      'loginError': 'Error al iniciar sesión: {error}',
      'unexpectedError': 'Ha ocurrido un error inesperado.',
      'zone': 'Zona',
      'chooseZone': 'Escoge zona…',
      'plate': 'Matrícula',
      'plateRequired': 'La matrícula es obligatoria.',
      'invalidPlate': 'Formato de matrícula incorrecto.',
      'price': 'Precio',
      'until': 'Hasta',
      'pay': 'Pagar',
      'correctPlate': '¿Es correcta la matrícula?',
      'yes': 'Sí',
      'no': 'No',
      'sendTicketEmail': '¿Enviar ticket por email?',
      'enterEmail': 'Introduce tu email',
      'sendTicketSms': '¿Enviar ticket por SMS?',
      'enterPhone': 'Introduce tu teléfono',
      'cancel': 'Cancelar',
      'send': 'Enviar',
      'ticketCreated': 'Ticket generado correctamente.',
      'paymentDone': 'Se ha realizado el pago correctamente.',
      'saveTicketQr': 'Escanee el QR para guardar el ticket en su dispositivo.',
      'sendByEmail': 'Enviar por correo electrónico',
      'sendBySms': 'Enviar SMS',
      'emailSent': 'Ticket enviado correctamente.',
      'smsSent': 'Ticket enviado correctamente.',
      'close': 'Cerrar',
      'returningIn': 'Regresando en {seconds} s…',
      'selectMethod': 'Selecciona el método de pago',
      'cardPayment': 'Pago con tarjeta',
      'qrPayment': 'Pago con QR',
      'selectMethodError': 'Debes seleccionar un método antes de continuar.',
      'processingPayment': 'Procesando pago…',
      'paymentSuccess': 'Pago realizado con éxito',
      'digitalTicket': 'Su ticket es digital.',
      'scanQr': 'Escanee el QR para tener el ticket en su móvil.',
      'paymentError': 'Error al procesar el pago',
      'goHome': 'Volver a la pantalla principal',
      'back': 'Atrás',
      'emergencyTitle': 'ADVERTENCIA',
      'autoCloseIn': 'Cierre automático en {seconds} s',
      'emergencyActiveLabel': 'Emergencia: {reason}',
    },
    'ca': {
      'welcome': 'Benvingut a Meypar Optima App',
      'email': 'Email',
      'password': 'Contrasenya',
      'signIn': 'Iniciar sessió',
      'invalidEmail': "L'adreça de correu té un format incorrecte.",
      'userDisabled': 'El compte està desactivat.',
      'userNotFound': 'No existeix cap usuari amb aquest correu.',
      'wrongPassword': 'Correu o contrasenya incorrectes.',
      'tooManyRequests': "S'han intentat massa accessos. Intenta més tard.",
      'invalidCredential': 'La credencial és incorrecta o ha expirat.',
      'loginError': 'Error en iniciar sessió: {error}',
      'unexpectedError': 'Ha ocorregut un error inesperat.',
      'zone': 'Zona',
      'chooseZone': 'Escull zona…',
      'plate': 'Matrícula',
      'plateRequired': 'La matrícula és obligatòria.',
      'invalidPlate': 'Format de matrícula incorrecte.',
      'price': 'Preu',
      'until': 'Fins',
      'pay': 'Pagar',
      'correctPlate': 'És correcta la matrícula?',
      'yes': 'Sí',
      'no': 'No',
      'sendTicketEmail': 'Enviar tiquet per email?',
      'enterEmail': "Introdueix el teu email",
      'sendTicketSms': 'Enviar tiquet per SMS?',
      'enterPhone': 'Introdueix el teu telèfon',
      'cancel': 'Cancel·lar',
      'send': 'Enviar',
      'ticketCreated': 'Tiquet generat correctament.',
      'paymentDone': 'S\'ha realitzat el pagament correctament.',
      'saveTicketQr': 'Escaneja el QR per desar el tiquet al dispositiu.',
      'sendByEmail': 'Enviar per correu electr\u00F2nic',
      'sendBySms': 'Enviar SMS',
      'emailSent': 'Tiquet enviat correctament.',
      'smsSent': 'Tiquet enviat correctament.',
      'close': 'Tancar',
      'returningIn': 'Tornant en {seconds} s…',
      'selectMethod': 'Selecciona el mètode de pagament',
      'cardPayment': 'Pagament amb targeta',
      'qrPayment': 'Pagament amb QR',
      'selectMethodError': 'Has de seleccionar un mètode abans de continuar.',
      'processingPayment': 'Processant pagament…',
      'paymentSuccess': 'Pagament realitzat amb èxit',
      'digitalTicket': 'El tiquet és digital.',
      'scanQr': 'Escaneja el QR per tenir el tiquet al mòbil.',
      'paymentError': 'Error en processar el pagament',
      'goHome': "Tornar a l'inici",
      'back': 'Enrere',
      'emergencyTitle': 'Emergència',
      'autoCloseIn': 'Tancament automàtic en {seconds} s',
      'emergencyActiveLabel': 'Emergència: {reason}',
    },
    'en': {
      'welcome': 'Welcome to Meypar Optima App',
      'email': 'Email',
      'password': 'Password',
      'signIn': 'Sign in',
      'invalidEmail': 'The email address is badly formatted.',
      'userDisabled': 'The user account is disabled.',
      'userNotFound': 'There is no user with that email.',
      'wrongPassword': 'Incorrect email or password.',
      'tooManyRequests': 'Too many attempts. Try again later.',
      'invalidCredential': 'The credential is invalid or has expired.',
      'loginError': 'Error signing in: {error}',
      'unexpectedError': 'An unexpected error occurred.',
      'zone': 'Zone',
      'chooseZone': 'Choose zone…',
      'plate': 'Plate',
      'plateRequired': 'Plate is required.',
      'invalidPlate': 'Invalid plate format.',
      'price': 'Price',
      'until': 'Until',
      'pay': 'Pay',
      'correctPlate': 'Is the plate correct?',
      'yes': 'Yes',
      'no': 'No',
      'sendTicketEmail': 'Send ticket by email?',
      'enterEmail': 'Enter your email',
      'sendTicketSms': 'Send ticket by SMS?',
      'enterPhone': 'Enter your phone number',
      'cancel': 'Cancel',
      'send': 'Send',
      'ticketCreated': 'Ticket generated correctly.',
      'paymentDone': 'Payment completed successfully',
      'saveTicketQr': 'Scan the QR to save the ticket on your device.',
      'sendByEmail': 'Send by email',
      'sendBySms': 'Send SMS',
      'emailSent': 'Ticket sent successfully.',
      'smsSent': 'Ticket sent successfully.',
      'close': 'Close',
      'returningIn': 'Returning in {seconds}s…',
      'selectMethod': 'Select payment method',
      'cardPayment': 'Card payment',
      'qrPayment': 'QR payment',
      'selectMethodError': 'Select a method before continuing.',
      'processingPayment': 'Processing payment…',
      'paymentSuccess': 'Payment completed successfully',
      'digitalTicket': 'Your ticket is digital.',
      'scanQr': 'Scan the QR to save the ticket on your phone.',
      'paymentError': 'Payment error',
      'goHome': 'Return to main screen',
      'back': 'Back',
      'emergencyTitle': 'Emergency',
      'autoCloseIn': 'Auto close in {seconds}s',
      'emergencyActiveLabel': 'Emergency: {reason}',
    },
  };

  String _get(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['es']![key] ?? key;
  }

  String t(String key, {Map<String, String>? params}) {
    var text = _get(key);
    params?.forEach((k, v) {
      text = text.replaceAll('{$k}', v);
    });
    return text;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['es', 'ca', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}
