import 'package:flutter/foundation.dart';

/// Global API configuration
/// Default API base URL for the mock backend
String get defaultApiBaseUrl {
  if (kIsWeb) {
    // En web, detectar si estamos en desarrollo local o producción
    return Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1'
        ? 'http://localhost:3001/api'  // Desarrollo local
        : 'https://mock-mowiz.onrender.com';  // Producción web
  }
  return 'https://mock-mowiz.onrender.com';  // Móvil: API directa
}

