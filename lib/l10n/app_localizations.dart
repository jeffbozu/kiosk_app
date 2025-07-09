import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  /// Retrieve the localization instance from the closest [BuildContext].
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
      'price': 'Precio',
      'until': 'Hasta',
      'pay': 'Pagar',
      'correctPlate': '¿Es correcta la matrícula?',
      'yes': 'Sí',
      'no': 'No',
      'sendTicketEmail': '¿Enviar ticket por email?',
      'enterEmail': 'Introduce tu email',
      'cancel': 'Cancelar',
      'send': 'Enviar',
      'ticketCreated': 'Ticket generado correctamente.',
      'returningIn': 'Regresando en {seconds} s…',
      'selectMethod': 'Selecciona el método de pago',
      'cardPayment': 'Pago con tarjeta',
      'qrPayment': 'Pago con QR',
      'selectMethodError': 'Debes seleccionar un método antes de continuar.',
      'processingPayment': 'Procesando pago…',
      'paymentSuccess': 'Pago realizado con éxito',
      'digitalTicket': 'Su ticket es digital.',
      'paymentError': 'Error al procesar el pago',
      'goHome': 'Volver a la pantalla principal',
      'back': 'Atrás',
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
      'price': 'Preu',
      'until': 'Fins',
      'pay': 'Pagar',
      'correctPlate': 'És correcta la matrícula?',
      'yes': 'Sí',
      'no': 'No',
      'sendTicketEmail': 'Enviar tiquet per email?',
      'enterEmail': "Introdueix el teu email",
      'cancel': 'Cancel·lar',
      'send': 'Enviar',
      'ticketCreated': 'Tiquet generat correctament.',
      'returningIn': 'Tornant en {seconds} s…',
      'selectMethod': 'Selecciona el mètode de pagament',
      'cardPayment': 'Pagament amb targeta',
      'qrPayment': 'Pagament amb QR',
      'selectMethodError': 'Has de seleccionar un mètode abans de continuar.',
      'processingPayment': 'Processant pagament…',
      'paymentSuccess': 'Pagament completat',
      'digitalTicket': 'El tiquet és digital.',
      'paymentError': 'Error en processar el pagament',
      'goHome': "Tornar a l'inici",
      'back': 'Enrere',
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
      'price': 'Price',
      'until': 'Until',
      'pay': 'Pay',
      'correctPlate': 'Is the plate correct?',
      'yes': 'Yes',
      'no': 'No',
      'sendTicketEmail': 'Send ticket by email?',
      'enterEmail': 'Enter your email',
      'cancel': 'Cancel',
      'send': 'Send',
      'ticketCreated': 'Ticket generated correctly.',
      'returningIn': 'Returning in {seconds}s…',
      'selectMethod': 'Select payment method',
      'cardPayment': 'Card payment',
      'qrPayment': 'QR payment',
      'selectMethodError': 'Select a method before continuing.',
      'processingPayment': 'Processing payment…',
      'paymentSuccess': 'Payment completed successfully',
      'digitalTicket': 'Your ticket is digital.',
      'paymentError': 'Payment error',
      'goHome': 'Return to main screen',
      'back': 'Back',
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
