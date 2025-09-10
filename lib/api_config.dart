import 'package:flutter/foundation.dart';

/// Global API configuration
/// Default API base URL for the mock backend
const String defaultApiBaseUrl = kIsWeb
  ? 'http://localhost:3001/api'  // Desarrollo: Proxy local
  : 'https://mock-mowiz.onrender.com';  // Producción: API directa

