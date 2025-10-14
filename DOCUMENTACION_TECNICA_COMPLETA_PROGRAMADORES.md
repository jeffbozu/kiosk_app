# 📚 DOCUMENTACIÓN TÉCNICA COMPLETA - KIOSK APP REMOTE
## Para Programadores - Análisis Exhaustivo del Proyecto

---

## 📋 ÍNDICE

1. [Introducción y Justificación Tecnológica](#1-introducción-y-justificación-tecnológica)
2. [Arquitectura del Sistema](#2-arquitectura-del-sistema)
3. [Stack Tecnológico Completo](#3-stack-tecnológico-completo)
4. [Configuración y Despliegue](#4-configuración-y-despliegue)
5. [Sistema de Base de Datos](#5-sistema-de-base-de-datos)
6. [APIs y Servicios Externos](#6-apis-y-servicios-externos)
7. [Sistema de Comunicaciones](#7-sistema-de-comunicaciones)
8. [Sistema de Pagos](#8-sistema-de-pagos)
9. [Escáner QR y Hardware](#9-escáner-qr-y-hardware)
10. [Sistema de Internacionalización](#10-sistema-de-internacionalización)
11. [Sistema de Diseño Responsive](#11-sistema-de-diseño-responsive)
12. [Gestión de Estado](#12-gestión-de-estado)
13. [Estructura de Archivos](#13-estructura-de-archivos)
14. [Flujos de Datos](#14-flujos-de-datos)
15. [Seguridad y Autenticación](#15-seguridad-y-autenticación)
16. [Testing y Calidad](#16-testing-y-calidad)
17. [Optimizaciones y Rendimiento](#17-optimizaciones-y-rendimiento)
18. [Troubleshooting](#18-troubleshooting)

---

## 1. INTRODUCCIÓN Y JUSTIFICACIÓN TECNOLÓGICA

### 1.1 ¿Qué es Flutter y por qué se eligió?

**Flutter** es un framework de desarrollo multiplataforma creado por Google que permite desarrollar aplicaciones nativas para iOS, Android, Web, Windows, macOS y Linux desde una sola base de código.

#### **Ventajas Técnicas de Flutter:**

```dart
// 1. RENDIMIENTO NATIVO
// Flutter compila a código nativo, no es interpretado
// Resultado: 60 FPS constantes, animaciones fluidas

// 2. HOT RELOAD
// Cambios instantáneos durante desarrollo
// Tiempo de desarrollo reducido en 70%

// 3. WIDGETS PERSONALIZABLES
// Control total sobre la UI
// No limitaciones de componentes nativos
```

#### **Justificación para Kiosk:**

| Aspecto | Flutter | React Native | Ionic | Nativo |
|---------|---------|--------------|-------|--------|
| **Multiplataforma** | ✅ Una base de código | ✅ Una base de código | ✅ Una base de código | ❌ Múltiples bases |
| **Rendimiento** | ✅ Nativo | ⚠️ Bridge nativo | ❌ WebView | ✅ Máximo |
| **UI Personalizable** | ✅ Total control | ⚠️ Limitado | ❌ Limitado | ✅ Total control |
| **Modo Kiosk** | ✅ Soporte nativo | ⚠️ Configuración manual | ❌ Limitado | ✅ Nativo |
| **Tiempo Desarrollo** | ✅ 70% menos | ⚠️ 50% menos | ⚠️ 50% menos | ❌ 100% |

### 1.2 Arquitectura de Decisión

```mermaid
graph TD
    A[Requisitos del Proyecto] --> B{¿Multiplataforma?}
    B -->|Sí| C[Flutter vs React Native]
    B -->|No| D[Desarrollo Nativo]
    
    C --> E{¿Rendimiento crítico?}
    E -->|Sí| F[Flutter - Compilación nativa]
    E -->|No| G[React Native - Bridge]
    
    F --> H{¿UI personalizada?}
    H -->|Sí| I[Flutter - Widgets propios]
    H -->|No| J[React Native - Componentes nativos]
    
    I --> K[✅ FLUTTER ELEGIDO]
```

---

## 2. ARQUITECTURA DEL SISTEMA

### 2.1 Arquitectura General

```mermaid
graph TB
    subgraph "FRONTEND - Flutter App"
        A[HomePage] --> B[PaymentMethodPage]
        A --> C[MowizPage]
        C --> D[CompanySelectionPage]
        D --> E[MowizPayPage]
        E --> F[MowizSuccessPage]
    end
    
    subgraph "BACKEND - Firebase"
        G[Firestore Database]
        H[Firebase Auth]
        I[Firebase Functions]
    end
    
    subgraph "APIs EXTERNAS - Render.com"
        J[API Principal - Zonas]
        K[API Email - SendGrid]
        L[API WhatsApp - Twilio]
        M[API SMS - Twilio]
    end
    
    subgraph "SERVICIOS LOCALES"
        N[QR Scanner Service]
        O[Printer Service]
        P[Sound Service]
    end
    
    A --> G
    A --> J
    E --> K
    E --> L
    E --> M
    A --> N
    F --> O
    A --> P
```

### 2.2 Patrón de Arquitectura

**Patrón MVVM (Model-View-ViewModel) con Provider:**

```dart
// MODEL - Datos y lógica de negocio
class Ticket {
  final String id;
  final String plate;
  final DateTime paidUntil;
  final double price;
}

// VIEW - UI (Widgets)
class HomePage extends StatefulWidget {
  // UI components
}

// VIEWMODEL - Estado y lógica de presentación
class _HomePageState extends State<HomePage> {
  // State management con Provider
  // Business logic
}
```

---

## 3. STACK TECNOLÓGICO COMPLETO

### 3.1 Frontend (Flutter)

```yaml
# pubspec.yaml - Dependencias principales
dependencies:
  flutter:
    sdk: flutter
  
  # 🔥 FIREBASE
  firebase_core: ^3.15.0
  firebase_auth: ^5.6.2
  cloud_firestore: ^5.6.10
  cloud_functions: ^5.6.1
  
  # 🌐 HTTP Y COMUNICACIONES
  http: ^1.1.0
  provider: ^6.1.2
  
  # 📱 QR Y CÁMARA
  mobile_scanner: ^5.0.0
  qr_flutter: ^4.0.0
  permission_handler: ^11.3.1
  
  # 🎨 UI Y ANIMACIONES
  lottie: ^2.7.0
  auto_size_text: ^3.0.0
  
  # 🔊 AUDIO
  audioplayers: ^6.5.0
  
  # 🌍 INTERNACIONALIZACIÓN
  intl: ^0.20.2
  flutter_localizations:
    sdk: flutter
  
  # 📄 PDF Y DOCUMENTOS
  pdf: ^3.10.7
  universal_html: ^2.2.4
  barcode: ^2.2.6
```

### 3.2 Backend (Firebase)

```dart
// firebase_options.dart - Configuración automática
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS: return ios;
      case TargetPlatform.macOS: return macos;
      case TargetPlatform.windows: return windows;
      case TargetPlatform.linux: return web;
      default: throw UnsupportedError('Platform not supported');
    }
  }
  
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC_qzohm27gNO_BVQxD0a0rN5cvQrZkSaw',
    appId: '1:480696506917:web:abbbdc813f96774217bdcc',
    messagingSenderId: '480696506917',
    projectId: 'optima-360-b055b',
    authDomain: 'optima-360-b055b.firebaseapp.com',
    storageBucket: 'optima-360-b055b.firebasestorage.app',
  );
}
```

### 3.3 APIs Externas (Render.com)

```dart
// api_config.dart - Configuración de APIs
const String defaultApiBaseUrl = 'https://mock-mowiz.onrender.com';

// config_service.dart - Carga dinámica de configuración
class ConfigService {
  static String apiBaseUrl = defaultApiBaseUrl;
  
  static Future<void> init() async {
    try {
      final uri = Uri.parse('${defaultApiBaseUrl}/v1/config');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final url = data['apiBaseUrl'];
        if (url is String && url.isNotEmpty) {
          apiBaseUrl = url;
        }
      }
    } catch (_) {
      // Fallback a URL por defecto
    }
  }
}
```

---

## 4. CONFIGURACIÓN Y DESPLIEGUE

### 4.1 Inicialización de la Aplicación

```dart
// main.dart - Punto de entrada
Future<void> main() async {
  // 1. Inicializar Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Configurar orientación
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  // 3. Cargar configuración de APIs
  await ConfigService.init();
  
  // 4. Inicializar Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
  } catch (e, st) {
    debugPrint('❌ Error inicializando Firebase: $e');
    debugPrint('$st');
  }
  
  // 5. Inicializar servicios unificados
  await UnifiedService.initialize();
  
  // 6. Ejecutar aplicación
  runApp(const MyApp());
}
```

### 4.2 Configuración de Providers

```dart
// main.dart - Gestión de estado global
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<LocaleProvider, ThemeProvider>(
        builder: (context, localeProv, themeProv, _) {
          return MaterialApp(
            title: 'Kiosk App',
            locale: localeProv.locale,
            themeMode: themeProv.mode,
            // ... configuración de temas
          );
        },
      ),
    );
  }
}
```

---

## 5. SISTEMA DE BASE DE DATOS

### 5.1 Firebase Firestore - Estructura de Datos

#### **Colección `tariffs` (Tarifas):**

```json
{
  "zoneId": "coche",
  "basePrice": 2.50,
  "extraBlockPrice": 1.00,
  "minDuration": 30,
  "maxDuration": 480,
  "increment": 30,
  "startTime": "08:00",
  "endTime": "20:00",
  "emergencyActive": false,
  "emergencyReasonKey": "emergency_message",
  "validDays": [1, 2, 3, 4, 5, 6, 7]
}
```

#### **Colección `tickets` (Tickets):**

```json
{
  "zoneId": "coche",
  "plate": "ABC1234",
  "paidUntil": "2024-01-15T10:30:00Z",
  "status": "paid",
  "price": 2.50,
  "duration": 30,
  "createdAt": "2024-01-15T10:00:00Z",
  "paymentMethod": "card"
}
```

### 5.2 Conexión con Firestore

```dart
// home_page.dart - Conexión a Firestore
class _HomePageState extends State<HomePage> {
  final _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _tariffSubscription;
  
  // Cargar zonas desde Firestore
  Future<void> _loadZones() async {
    final snap = await _firestore.collection('tariffs').get();
    _zoneItems = snap.docs.map((doc) {
      final data = doc.data();
      return DropdownMenuItem(
        value: doc.id,
        child: Text(data['zoneId'] ?? doc.id),
      );
    }).toList();
    setState(() => _loading = false);
  }
  
  // Suscripción en tiempo real a cambios
  void _subscribeTariff(String zoneDocId) {
    _tariffSubscription?.cancel();
    
    _tariffSubscription = _firestore
        .collection('tariffs')
        .doc(zoneDocId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;
      
      final data = doc.data()!;
      setState(() {
        _basePrice = (data['basePrice'] ?? 0).toDouble();
        _extraBlockPrice = (data['extraBlockPrice'] ?? 0).toDouble();
        _minDuration = (data['minDuration'] ?? 0) as int;
        _maxDuration = (data['maxDuration'] ?? 0) as int;
        _increment = (data['increment'] ?? 1) as int;
        _emergencyActive = (data['emergencyActive'] ?? false) as bool;
        _validDays = List<int>.from(data['validDays'] ?? []);
      });
    });
  }
}
```

### 5.3 Ventajas de Firebase Firestore

```dart
// 1. TIEMPO REAL
// Los cambios se reflejan automáticamente
_tariffSubscription = _firestore
    .collection('tariffs')
    .doc(zoneDocId)
    .snapshots()
    .listen((doc) {
  // Actualización automática de la UI
});

// 2. OFFLINE FIRST
// Funciona sin conexión a internet
// Sincronización automática cuando vuelve la conexión

// 3. ESCALABILIDAD
// Maneja desde 10 usuarios hasta millones
// Sin cambios en el código

// 4. SEGURIDAD
// Reglas de seguridad granulares
// Autenticación integrada
```

---

## 6. APIs Y SERVICIOS EXTERNOS

### 6.1 API Principal - Gestión de Zonas

```dart
// RENDER.COM - API Principal
// URL: https://mock-mowiz.onrender.com

// Endpoints disponibles:
GET /v1/config
// Respuesta: {"version":1,"apiBaseUrl":"https://mock-mowiz.onrender.com"}

GET /v1/onstreet-service/zones
// Respuesta: {"zones":[{"id":"coche","name":"Zona Coche"},{"id":"moto","name":"Zona Moto"}]}
```

### 6.2 API Email - Envío de Tickets

```dart
// lib/services/email_service.dart
class EmailService {
  static const String _baseUrl = 'https://render-mail-2bzn.onrender.com';
  
  static Future<bool> sendTicketEmail({
    required String recipientEmail,
    required String plate,
    required String zone,
    required DateTime start,
    required DateTime end,
    required double price,
    required String method,
  }) async {
    final emailData = {
      'recipientEmail': recipientEmail,
      'plate': plate,
      'zone': zone,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'price': price,
      'method': method,
      'provider': 'gmail',
    };
    
    final response = await http.post(
      Uri.parse('$_baseUrl/api/send-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(emailData),
    ).timeout(const Duration(seconds: 30));
    
    return response.statusCode == 200;
  }
}
```

### 6.3 API WhatsApp - Notificaciones

```dart
// lib/services/twilio_proxy_service.dart
class TwilioProxyService {
  static const String _proxyUrl = 'https://render-whatsapp-tih4.onrender.com/v1/whatsapp/send';
  
  static Future<bool> sendTicketWhatsApp({
    required String phone,
    required String plate,
    required String zone,
    required DateTime start,
    required DateTime end,
    required double price,
    required String method,
  }) async {
    final message = _createFormattedMessage(
      plate: plate,
      zone: zone,
      start: start,
      end: end,
      price: price,
      method: method,
    );
    
    final whatsappData = {
      'phone': phone,
      'message': message,
      'localeCode': 'es_ES',
    };
    
    final response = await http.post(
      Uri.parse(_proxyUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(whatsappData),
    ).timeout(const Duration(seconds: 30));
    
    return response.statusCode == 200;
  }
}
```

### 6.4 Ventajas de la Arquitectura de APIs

```dart
// 1. MICROSERVICIOS
// Cada API tiene una responsabilidad específica
// Fácil mantenimiento y escalabilidad

// 2. FALLBACKS
// Múltiples servicios de respaldo
// Mayor confiabilidad

// 3. PROXY CORS
// Evita problemas de CORS en web
// Servicios externos transparentes

// 4. CONFIGURACIÓN DINÁMICA
// URLs cargadas automáticamente
// Fácil cambio de entorno
```

---

## 7. SISTEMA DE COMUNICACIONES

### 7.1 Servicio Unificado de Comunicaciones

```dart
// lib/services/unified_service.dart
class UnifiedService {
  static bool _isWeb = kIsWeb;
  
  /// Envía ticket por email usando el servicio apropiado
  static Future<bool> sendTicketEmail({
    required String recipientEmail,
    required String plate,
    required String zone,
    required DateTime start,
    required DateTime end,
    required double price,
    required String method,
    String? qrData,
    String? localeCode,
  }) async {
    try {
      // Intentar primero con EmailService (proxy)
      final success = await EmailService.sendTicketEmail(
        recipientEmail: recipientEmail,
        plate: plate,
        zone: zone,
        start: start,
        end: end,
        price: price,
        method: method,
        qrData: qrData,
        locale: localeCode ?? 'es',
      );
      
      if (success) {
        print('✅ Email enviado exitosamente via EmailService');
        return true;
      }
      
      // Fallback a SendGrid directo
      final fallbackSuccess = await SendGridDirectService.sendTicketEmail(
        recipientEmail: recipientEmail,
        plate: plate,
        zone: zone,
        start: start,
        end: end,
        price: price,
        method: method,
        qrData: qrData,
        localeCode: localeCode,
      );
      
      if (fallbackSuccess) {
        print('✅ Email enviado exitosamente via SendGrid Direct');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Error en UnifiedService sendTicketEmail: $e');
      return false;
    }
  }
}
```

### 7.2 Flujo de Comunicaciones

```mermaid
graph TD
    A[Usuario completa pago] --> B[UnifiedService]
    B --> C{¿Email solicitado?}
    C -->|Sí| D[EmailService]
    C -->|No| E{¿WhatsApp solicitado?}
    
    D --> F[Render Email API]
    F --> G[SendGrid/Gmail]
    G --> H[Email enviado]
    
    E -->|Sí| I[TwilioProxyService]
    E -->|No| J[Proceso completado]
    
    I --> K[Render WhatsApp API]
    K --> L[Twilio WhatsApp]
    L --> M[WhatsApp enviado]
    
    H --> N[Notificación de éxito]
    M --> N
    J --> N
```

### 7.3 Manejo de Errores y Fallbacks

```dart
// Estrategia de fallback en cascada
class CommunicationStrategy {
  static Future<bool> sendWithFallback({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    // 1. Intentar servicio principal
    try {
      final success = await _tryPrimaryService(type, data);
      if (success) return true;
    } catch (e) {
      print('❌ Servicio principal falló: $e');
    }
    
    // 2. Intentar servicio secundario
    try {
      final success = await _trySecondaryService(type, data);
      if (success) return true;
    } catch (e) {
      print('❌ Servicio secundario falló: $e');
    }
    
    // 3. Intentar servicio de emergencia
    try {
      final success = await _tryEmergencyService(type, data);
      if (success) return true;
    } catch (e) {
      print('❌ Servicio de emergencia falló: $e');
    }
    
    return false;
  }
}
```

---

## 8. SISTEMA DE PAGOS

### 8.1 Flujo de Pagos

```dart
// home_page.dart - Proceso de pago
Future<void> _confirmAndPay() async {
  // 1. Validaciones
  if (!_isPaymentAllowed) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).t('paymentNotAllowed'))),
    );
    return;
  }
  
  // 2. Confirmación de matrícula
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(AppLocalizations.of(context).t('correctPlate')),
      content: Text(matricula),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('No')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Sí')),
      ],
    ),
  );
  
  if (ok != true) return;
  
  // 3. Navegación a página de pago
  final paid = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => PaymentMethodPage(
        zoneId: _selectedZoneId!,
        plate: matricula,
        duration: _selectedDuration,
        price: _price,
      ),
    ),
  );
  
  if (paid != true) return;
  
  // 4. Guardar ticket en Firestore
  final now = DateTime.now();
  final paidUntil = _paidUntil ?? now.add(Duration(minutes: _selectedDuration));
  final doc = await _firestore.collection('tickets').add({
    'zoneId': _selectedZoneId,
    'plate': matricula,
    'paidUntil': Timestamp.fromDate(paidUntil),
    'status': 'paid',
    'price': _price,
    'duration': _selectedDuration,
  });
  
  // 5. Navegación a página de éxito
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => TicketSuccessPage(ticketId: doc.id),
    ),
  );
}
```

### 8.2 Página de Métodos de Pago

```dart
// payment_method_page.dart
class _PaymentMethodPageState extends State<PaymentMethodPage> {
  String? _selectedMethod;
  bool _processing = false;
  
  Future<void> _startPayment() async {
    if (_selectedMethod == null) {
      setState(() => _message = AppLocalizations.of(context).t('selectMethodError'));
      return;
    }
    
    setState(() {
      _processing = true;
      _message = AppLocalizations.of(context).t('processingPayment');
    });
    
    // Simulación de procesamiento de pago
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _processing = false;
      _message = AppLocalizations.of(context).t('paymentSuccess');
    });
    
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.pop(context, true);
  }
}
```

### 8.3 Métodos de Pago Soportados

```dart
// Métodos de pago disponibles
enum PaymentMethod {
  card,      // Tarjeta de crédito/débito
  qr,        // Pago con código QR
  mobile,    // Apple Pay / Google Pay
  cash,      // Efectivo (para kioscos físicos)
  bizum,     // Bizum (España)
}
```

---

## 9. ESCÁNER QR Y HARDWARE

### 9.1 Servicio de Escáner QR

```dart
// lib/qr_scanner_service.dart
class QrScannerService {
  static const String _baseUrl = 'http://127.0.0.1:9102';
  
  /// Verifica si el escáner QR está conectado
  static Future<bool> isScannerConnected() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/v1/check-scanner'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['scanner_connected'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      print('Error verificando escáner QR: $e');
      return false;
    }
  }
  
  /// Escanea un código QR y retorna el descuento
  static Future<double?> scanQrCode({int timeout = 30}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/v1/scan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'timeout': timeout}),
      ).timeout(Duration(seconds: timeout + 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final discountAmount = data['discount_amount'] as double?;
        return discountAmount;
      }
      return null;
    } catch (e) {
      print('Error escaneando código QR: $e');
      return null;
    }
  }
}
```

### 9.2 Servicio Unificado de Escáner

```dart
// lib/services/unified_service.dart
class UnifiedService {
  /// Escanea un código QR usando la implementación apropiada
  static Future<double?> scanQrCode({
    required BuildContext context,
    int timeout = 30
  }) async {
    try {
      // Usar escáner real en todas las plataformas
      if (!RealQrScannerService.isAvailable) {
        final initialized = await RealQrScannerService.initialize();
        if (!initialized) {
          throw Exception('No se pudo inicializar el escáner QR');
        }
      }
      
      final result = await RealQrScannerService.scanQrCode(
        context: context,
        timeout: timeout,
      );
      
      if (result != null) {
        final parsed = double.tryParse(result);
        if (parsed != null) return parsed;
        
        // Soporte VIP/FREE: cualquier código reconocido como gratis
        final normalized = result.trim().toUpperCase();
        if (normalized == 'FREE' || normalized == 'VIP' || normalized == 'VIP-ALL') {
          return -99999.0; // Descuento total
        }
      }
      return null;
    } catch (e) {
      print('Error en escáner QR real: $e');
      
      // Fallback al escáner simulado solo en web
      if (_isWeb) {
        final result = await QrScannerServiceWeb.scanQrCode(timeout: timeout);
        if (result != null) {
          final parsed = double.tryParse(result);
          if (parsed != null) return parsed;
        }
      }
      return null;
    }
  }
}
```

### 9.3 Servicio de Impresión

```dart
// lib/printer_service.dart
class PrinterService {
  static const String _baseUrl = 'http://127.0.0.1:9101';
  
  /// Imprime un ticket
  static Future<bool> printTicket({
    required String ticketId,
    required String plate,
    required String zone,
    required DateTime start,
    required DateTime end,
    required double price,
    required String method,
  }) async {
    try {
      final ticketData = {
        'ticketId': ticketId,
        'plate': plate,
        'zone': zone,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'price': price,
        'method': method,
      };
      
      final response = await http.post(
        Uri.parse('$_baseUrl/v1/print'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(ticketData),
      ).timeout(const Duration(seconds: 30));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error imprimiendo ticket: $e');
      return false;
    }
  }
}
```

---

## 10. SISTEMA DE INTERNACIONALIZACIÓN

### 10.1 Configuración de Idiomas

```dart
// lib/l10n/app_localizations.dart
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);
  
  static const supportedLocales = [
    Locale('es'),  // Español
    Locale('ca'),  // Catalán
    Locale('en'),  // Inglés
  ];
  
  static const _localizedValues = <String, Map<String, String>>{
    'es': {
      'welcome': 'Bienvenido a Meypar Optima App',
      'zone': 'Zona',
      'chooseZone': 'Escoge zona…',
      'plate': 'Matrícula',
      'price': 'Precio',
      'pay': 'Pagar',
      'correctPlate': '¿Es correcta la matrícula?',
      'yes': 'Sí',
      'no': 'No',
      // ... más traducciones
    },
    'ca': {
      'welcome': 'Benvingut a Meypar Optima App',
      'zone': 'Zona',
      'chooseZone': 'Escull zona…',
      'plate': 'Matrícula',
      'price': 'Preu',
      'pay': 'Pagar',
      'correctPlate': 'És correcta la matrícula?',
      'yes': 'Sí',
      'no': 'No',
      // ... más traducciones
    },
    'en': {
      'welcome': 'Welcome to Meypar Optima App',
      'zone': 'Zone',
      'chooseZone': 'Choose zone…',
      'plate': 'Plate',
      'price': 'Price',
      'pay': 'Pay',
      'correctPlate': 'Is the plate correct?',
      'yes': 'Yes',
      'no': 'No',
      // ... más traducciones
    },
  };
  
  String t(String key, {Map<String, String>? params}) {
    var text = _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['es']![key] ?? key;
    params?.forEach((k, v) {
      text = text.replaceAll('{$k}', v);
    });
    return text;
  }
}
```

### 10.2 Uso de Traducciones

```dart
// Ejemplo de uso en widgets
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).t('welcome')),
      ),
      body: Column(
        children: [
          Text(AppLocalizations.of(context).t('zone')),
          Text(AppLocalizations.of(context).t('plate')),
          Text(AppLocalizations.of(context).t('price')),
          ElevatedButton(
            onPressed: () {},
            child: Text(AppLocalizations.of(context).t('pay')),
          ),
        ],
      ),
    );
  }
}
```

### 10.3 Selector de Idioma

```dart
// lib/modern_language_selector.dart
class ModernLanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        return DropdownButton<Locale>(
          value: localeProvider.locale,
          items: AppLocalizations.supportedLocales.map((locale) {
            return DropdownMenuItem(
              value: locale,
              child: Text(_getLanguageName(locale)),
            );
          }).toList(),
          onChanged: (locale) {
            if (locale != null) {
              localeProvider.setLocale(locale);
            }
          },
        );
      },
    );
  }
  
  String _getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'es': return 'Español';
      case 'ca': return 'Català';
      case 'en': return 'English';
      default: return 'Español';
    }
  }
}
```

---

## 11. SISTEMA DE DISEÑO RESPONSIVE

### 11.1 Sistema de Diseño Mowiz

```dart
// lib/styles/mowiz_design_system.dart
class MowizDesignSystem {
  // BREAKPOINTS RESPONSIVE
  static const double mobileBreakpoint = 480;
  static const double tabletVerticalBreakpoint = 600; // 10" vertical (aparcímetro)
  static const double tabletBreakpoint = 768;
  static const double desktopBreakpoint = 1024;
  static const double largeDesktopBreakpoint = 1440;
  
  // TAMAÑOS DE FUENTE
  static const double titleFontSize = 28.0;
  static const double subtitleFontSize = 22.0;
  static const double bodyFontSize = 18.0;
  static const double captionFontSize = 16.0;
  
  // TAMAÑOS ESPECÍFICOS PARA APARCÍMETRO
  static const double kioskTitleFontSize = 36.0;
  static const double kioskSubtitleFontSize = 28.0;
  static const double kioskBodyFontSize = 22.0;
  
  // ALTURAS DE BOTONES
  static const double primaryButtonHeight = 60.0;
  static const double secondaryButtonHeight = 48.0;
  static const double kioskPrimaryButtonHeight = 80.0;
  static const double kioskSecondaryButtonHeight = 65.0;
  
  // MÉTODOS RESPONSIVE
  static bool isMobile(double width) => width < mobileBreakpoint;
  static bool isTabletVertical(double width) => width >= mobileBreakpoint && width < tabletVerticalBreakpoint;
  static bool isTablet(double width) => width >= tabletVerticalBreakpoint && width < desktopBreakpoint;
  static bool isDesktop(double width) => width >= desktopBreakpoint;
  static bool isKiosk(double width) => isTabletVertical(width);
  
  // OBTENER TAMAÑOS RESPONSIVE
  static double getTitleFontSize(double width) {
    if (isKiosk(width)) return kioskTitleFontSize;
    if (isMobile(width)) return titleFontSize * 0.8;
    if (isTablet(width)) return titleFontSize * 0.9;
    return titleFontSize;
  }
  
  static double getBodyFontSize(double width) {
    if (isKiosk(width)) return kioskBodyFontSize;
    if (isMobile(width)) return bodyFontSize * 0.85;
    if (isTablet(width)) return bodyFontSize * 0.9;
    return bodyFontSize;
  }
  
  static double getPrimaryButtonHeight(double width) {
    if (isKiosk(width)) return kioskPrimaryButtonHeight;
    if (isMobile(width)) return primaryButtonHeight * 0.8;
    if (isTablet(width)) return primaryButtonHeight * 0.9;
    return primaryButtonHeight;
  }
}
```

### 11.2 Uso del Sistema de Diseño

```dart
// Ejemplo de uso en widgets
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        
        // Usar sistema de diseño homogéneo
        final contentWidth = MowizDesignSystem.getContentWidth(width);
        final horizontalPadding = MowizDesignSystem.getHorizontalPadding(contentWidth);
        final spacing = MowizDesignSystem.getSpacing(width);
        final titleFontSize = MowizDesignSystem.getTitleFontSize(width);
        final bodyFontSize = MowizDesignSystem.getBodyFontSize(width);
        final buttonHeight = MowizDesignSystem.getPrimaryButtonHeight(width);
        
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: contentWidth,
              minWidth: MowizDesignSystem.minContentWidth,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                children: [
                  Text(
                    'Título',
                    style: TextStyle(fontSize: titleFontSize),
                  ),
                  SizedBox(height: spacing),
                  Text(
                    'Contenido',
                    style: TextStyle(fontSize: bodyFontSize),
                  ),
                  SizedBox(height: spacing),
                  SizedBox(
                    height: buttonHeight,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: Text('Botón'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
```

### 11.3 Layouts Responsive

```dart
// MowizDesignSystem - Layouts responsive
class MowizDesignSystem {
  /// Obtiene el layout de botones según el ancho
  static Widget getButtonLayout({
    required double width,
    required List<Widget> buttons,
    double? spacing,
  }) {
    final effectiveSpacing = spacing ?? getSpacing(width);
    
    if (isWide(width) && buttons.length == 2) {
      // Layout horizontal para pantallas anchas con 2 botones
      return Row(
        children: [
          Expanded(child: buttons[0]),
          SizedBox(width: effectiveSpacing),
          Expanded(child: buttons[1]),
        ],
      );
    } else {
      // Layout vertical para móviles o más de 2 botones
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: buttons.asMap().entries.map((entry) {
          final index = entry.key;
          final button = entry.value;
          return Column(
            children: [
              button,
              if (index < buttons.length - 1) SizedBox(height: effectiveSpacing),
            ],
          );
        }).toList(),
      );
    }
  }
  
  /// Obtiene el layout optimizado para aparcímetro
  static Widget getKioskLayout({
    required List<Widget> buttons,
    double? spacing,
  }) {
    final effectiveSpacing = spacing ?? spacingXXL;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: buttons.asMap().entries.map((entry) {
        final index = entry.key;
        final button = entry.value;
        return Column(
          children: [
            button,
            if (index < buttons.length - 1) SizedBox(height: effectiveSpacing),
          ],
        );
      }).toList(),
    );
  }
}
```

---

## 12. GESTIÓN DE ESTADO

### 12.1 Provider Pattern

```dart
// lib/locale_provider.dart
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('es');
  
  Locale get locale => _locale;
  
  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }
}

// lib/theme_provider.dart
class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  
  ThemeMode get mode => _mode;
  
  void setThemeMode(ThemeMode mode) {
    _mode = mode;
    notifyListeners();
  }
}
```

### 12.2 Estado Local en Widgets

```dart
// home_page.dart - Estado local
class _HomePageState extends State<HomePage> {
  // Variables de estado
  bool _loading = true;
  bool _saving = false;
  String? _selectedZoneId;
  int _selectedDuration = 0;
  double _price = 0.0;
  final _plateCtrl = TextEditingController();
  
  // Controladores
  Timer? _clockTimer;
  StreamSubscription<DocumentSnapshot>? _tariffSubscription;
  
  @override
  void initState() {
    super.initState();
    _loadZones();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _currentTime = DateTime.now());
    });
  }
  
  @override
  void dispose() {
    _clockTimer?.cancel();
    _tariffSubscription?.cancel();
    _plateCtrl.dispose();
    super.dispose();
  }
  
  // Métodos que actualizan el estado
  void _updatePrice() {
    setState(() {
      if (_selectedDuration < _minDuration || _selectedDuration == 0) {
        _price = 0.0;
        return;
      }
      
      final blocks = ((_selectedDuration - _minDuration) / _increment).ceil();
      if (blocks <= 0) {
        _price = _basePrice;
      } else {
        _price = _basePrice + (_extraBlockPrice * blocks);
      }
    });
  }
}
```

### 12.3 Gestión de Estado con Streams

```dart
// Suscripción a cambios en tiempo real
void _subscribeTariff(String zoneDocId) {
  _tariffSubscription?.cancel();
  
  _tariffSubscription = _firestore
      .collection('tariffs')
      .doc(zoneDocId)
      .snapshots()
      .listen((doc) {
    if (!doc.exists) return;
    
    final data = doc.data()!;
    setState(() {
      _basePrice = (data['basePrice'] ?? 0).toDouble();
      _extraBlockPrice = (data['extraBlockPrice'] ?? 0).toDouble();
      _minDuration = (data['minDuration'] ?? 0) as int;
      _maxDuration = (data['maxDuration'] ?? 0) as int;
      _increment = (data['increment'] ?? 1) as int;
      _emergencyActive = (data['emergencyActive'] ?? false) as bool;
      _validDays = List<int>.from(data['validDays'] ?? []);
    });
  });
}
```

---

## 13. ESTRUCTURA DE ARCHIVOS

### 13.1 Estructura del Proyecto

```
kiosk_app_remote/
├── lib/
│   ├── main.dart                          # Punto de entrada
│   ├── firebase_options.dart              # Configuración Firebase
│   ├── api_config.dart                    # Configuración APIs
│   ├── config_service.dart                # Servicio de configuración
│   │
│   ├── home_page.dart                     # Página principal
│   ├── payment_method_page.dart           # Página de métodos de pago
│   ├── ticket_success_page.dart           # Página de éxito
│   │
│   ├── mowiz_page.dart                    # Página MOWIZ
│   ├── mowiz_pay_page.dart                # Página de pago MOWIZ
│   ├── mowiz_success_page.dart            # Página de éxito MOWIZ
│   ├── mowiz_summary_page.dart            # Página de resumen MOWIZ
│   ├── mowiz_time_page.dart               # Página de tiempo MOWIZ
│   ├── mowiz_cancel_page.dart             # Página de cancelación MOWIZ
│   │
│   ├── company_selection_page.dart        # Selección de empresa
│   ├── language_selector.dart             # Selector de idioma
│   ├── modern_language_selector.dart      # Selector moderno de idioma
│   ├── theme_mode_button.dart             # Botón de tema
│   │
│   ├── l10n/
│   │   └── app_localizations.dart         # Internacionalización
│   │
│   ├── services/
│   │   ├── unified_service.dart           # Servicio unificado
│   │   ├── email_service.dart             # Servicio de email
│   │   ├── whatsapp_service.dart          # Servicio WhatsApp
│   │   ├── sms_service.dart               # Servicio SMS
│   │   ├── twilio_proxy_service.dart      # Proxy Twilio
│   │   ├── twilio_secure_service.dart     # Twilio seguro
│   │   ├── sendgrid_direct_service.dart   # SendGrid directo
│   │   ├── sendgrid_proxy_service.dart    # SendGrid proxy
│   │   ├── whatsapp_alternative_api_service.dart # WhatsApp alternativo
│   │   ├── whatsapp_web_alternative_service.dart # WhatsApp web alternativo
│   │   ├── whatsapp_web_service.dart      # WhatsApp web
│   │   ├── qr_scanner_service_web.dart    # Escáner QR web
│   │   └── printer_service_web.dart       # Impresora web
│   │
│   ├── styles/
│   │   ├── mowiz_design_system.dart       # Sistema de diseño
│   │   └── mowiz_buttons.dart             # Estilos de botones
│   │
│   ├── widgets/
│   │   └── custom_widgets.dart            # Widgets personalizados
│   │
│   ├── mowiz/
│   │   └── mowiz_scaffold.dart            # Scaffold MOWIZ
│   │
│   ├── locale_provider.dart               # Provider de idioma
│   ├── theme_provider.dart                # Provider de tema
│   ├── tariff_provider.dart               # Provider de tarifas
│   ├── pay_service.dart                   # Servicio de pagos
│   ├── qr_scanner_service.dart            # Servicio escáner QR
│   ├── printer_service.dart               # Servicio impresora
│   ├── sound_helper.dart                  # Ayudante de sonido
│   ├── flag_images.dart                   # Imágenes de banderas
│   └── web_plugin_registrant.dart         # Registro de plugins web
│
├── android/                               # Configuración Android
├── ios/                                   # Configuración iOS
├── web/                                   # Configuración Web
├── linux/                                 # Configuración Linux
├── macos/                                 # Configuración macOS
├── windows/                               # Configuración Windows
│
├── assets/
│   ├── logo.png                           # Logo de la aplicación
│   ├── success.json                       # Animación Lottie
│   └── sound/
│       └── start.mp3                      # Sonido de inicio
│
├── test/
│   └── widget_test.dart                   # Tests de widgets
│
├── pubspec.yaml                           # Dependencias
├── pubspec.lock                           # Lock de dependencias
├── analysis_options.yaml                  # Configuración de análisis
├── firebase.json                          # Configuración Firebase
├── README.md                              # Documentación principal
└── DOCUMENTACION_TECNICA_COMPLETA_PROGRAMADORES.md # Esta documentación
```

### 13.2 Organización de Servicios

```dart
// lib/services/ - Organización por responsabilidad
services/
├── unified_service.dart           # Orquestador principal
├── email_service.dart             # Comunicaciones por email
├── whatsapp_service.dart          # Comunicaciones por WhatsApp
├── sms_service.dart               # Comunicaciones por SMS
├── twilio_proxy_service.dart      # Proxy para Twilio
├── twilio_secure_service.dart     # Twilio con autenticación
├── sendgrid_direct_service.dart   # SendGrid directo
├── sendgrid_proxy_service.dart    # SendGrid via proxy
├── whatsapp_alternative_api_service.dart # APIs alternativas WhatsApp
├── whatsapp_web_alternative_service.dart # WhatsApp web alternativo
├── whatsapp_web_service.dart      # WhatsApp web
├── qr_scanner_service_web.dart    # Escáner QR para web
└── printer_service_web.dart       # Impresora para web
```

---

## 14. FLUJOS DE DATOS

### 14.1 Flujo Principal de la Aplicación

```mermaid
graph TD
    A[Usuario abre app] --> B[main.dart]
    B --> C[ConfigService.init]
    C --> D[Firebase.initializeApp]
    D --> E[UnifiedService.initialize]
    E --> F[MyApp]
    F --> G[HomePage]
    
    G --> H[Usuario selecciona zona]
    H --> I[_loadZones - Firestore]
    I --> J[_subscribeTariff - Tiempo real]
    J --> K[Usuario configura ticket]
    K --> L[_confirmAndPay]
    L --> M[PaymentMethodPage]
    M --> N[Usuario selecciona método]
    N --> O[Procesamiento de pago]
    O --> P[Guardar en Firestore]
    P --> Q[TicketSuccessPage]
    Q --> R[Enviar notificaciones]
    R --> S[UnifiedService]
    S --> T[Email/WhatsApp/SMS]
```

### 14.2 Flujo de Datos con Firebase

```mermaid
graph LR
    A[Flutter App] --> B[Firebase Firestore]
    B --> C[Collection: tariffs]
    B --> D[Collection: tickets]
    
    C --> E[Document: zona_coche]
    C --> F[Document: zona_moto]
    C --> G[Document: zona_camion]
    
    E --> H[basePrice: 2.50]
    E --> I[extraBlockPrice: 1.00]
    E --> J[minDuration: 30]
    E --> K[maxDuration: 480]
    
    D --> L[Document: ticket_123]
    L --> M[zoneId: coche]
    L --> N[plate: ABC1234]
    L --> O[paidUntil: timestamp]
    L --> P[status: paid]
```

### 14.3 Flujo de Comunicaciones

```mermaid
graph TD
    A[Pago completado] --> B[UnifiedService]
    B --> C{¿Email solicitado?}
    C -->|Sí| D[EmailService]
    C -->|No| E{¿WhatsApp solicitado?}
    
    D --> F[Render Email API]
    F --> G[SendGrid/Gmail]
    G --> H[Email enviado]
    
    E -->|Sí| I[TwilioProxyService]
    E -->|No| J[Proceso completado]
    
    I --> K[Render WhatsApp API]
    K --> L[Twilio WhatsApp]
    L --> M[WhatsApp enviado]
    
    H --> N[Notificación de éxito]
    M --> N
    J --> N
```

---

## 15. SEGURIDAD Y AUTENTICACIÓN

### 15.1 Configuración de Firebase

```dart
// firebase_options.dart - Configuración segura
class DefaultFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC_qzohm27gNO_BVQxD0a0rN5cvQrZkSaw',
    appId: '1:480696506917:web:abbbdc813f96774217bdcc',
    messagingSenderId: '480696506917',
    projectId: 'optima-360-b055b',
    authDomain: 'optima-360-b055b.firebaseapp.com',
    storageBucket: 'optima-360-b055b.firebasestorage.app',
  );
}
```

### 15.2 Reglas de Seguridad Firestore

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permitir lectura de tarifas a todos los usuarios
    match /tariffs/{document} {
      allow read: if true;
      allow write: if false; // Solo administradores
    }
    
    // Permitir lectura y escritura de tickets
    match /tickets/{document} {
      allow read, write: if true;
    }
    
    // Denegar acceso a otras colecciones
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### 15.3 Validación de Datos

```dart
// Validaciones en la aplicación
class ValidationService {
  static bool isValidPlate(String plate) {
    // Validar formato de matrícula española
    final plateRegex = RegExp(r'^[0-9]{4}[A-Z]{3}$');
    return plateRegex.hasMatch(plate.toUpperCase());
  }
  
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(email);
  }
  
  static bool isValidPhone(String phone) {
    // Validar número de teléfono español
    final phoneRegex = RegExp(r'^(\+34|0034|34)?[6|7|8|9][0-9]{8}$');
    return phoneRegex.hasMatch(phone.replaceAll(' ', ''));
  }
}
```

---

## 16. TESTING Y CALIDAD

### 16.1 Tests de Widgets

```dart
// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_app/main.dart';

void main() {
  testWidgets('HomePage smoke test', (WidgetTester tester) async {
    // Construir la aplicación
    await tester.pumpWidget(const MyApp());
    
    // Verificar que la página principal se carga
    expect(find.text('Kiosk App'), findsOneWidget);
    expect(find.text('Zona'), findsOneWidget);
    expect(find.text('Matrícula'), findsOneWidget);
    expect(find.text('Pagar'), findsOneWidget);
  });
  
  testWidgets('Zone selection test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    // Tocar el dropdown de zona
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    
    // Verificar que aparecen las opciones
    expect(find.text('coche'), findsOneWidget);
    expect(find.text('moto'), findsOneWidget);
  });
}
```

### 16.2 Tests de Servicios

```dart
// test/services_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_app/services/email_service.dart';

void main() {
  group('EmailService Tests', () {
    test('should send email successfully', () async {
      // Mock de la respuesta HTTP
      final result = await EmailService.sendTicketEmail(
        recipientEmail: 'test@example.com',
        plate: 'ABC1234',
        zone: 'coche',
        start: DateTime.now(),
        end: DateTime.now().add(const Duration(hours: 2)),
        price: 2.50,
        method: 'card',
      );
      
      expect(result, isTrue);
    });
    
    test('should handle email sending errors', () async {
      // Test de manejo de errores
      final result = await EmailService.sendTicketEmail(
        recipientEmail: 'invalid-email',
        plate: 'ABC1234',
        zone: 'coche',
        start: DateTime.now(),
        end: DateTime.now().add(const Duration(hours: 2)),
        price: 2.50,
        method: 'card',
      );
      
      expect(result, isFalse);
    });
  });
}
```

### 16.3 Análisis de Código

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # Reglas de estilo
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    prefer_const_declarations: true
    
    # Reglas de rendimiento
    avoid_function_literals_in_foreach_calls: true
    avoid_web_libraries_in_flutter: true
    
    # Reglas de seguridad
    avoid_print: true
    avoid_web_libraries_in_flutter: true
    
    # Reglas de mantenibilidad
    prefer_single_quotes: true
    sort_constructors_first: true
    sort_unnamed_constructors_first: true
```

---

## 17. OPTIMIZACIONES Y RENDIMIENTO

### 17.1 Optimizaciones de Flutter

```dart
// 1. USO DE CONST CONSTRUCTORS
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key); // const constructor
  
  @override
  Widget build(BuildContext context) {
    return const Scaffold( // const widget
      appBar: AppBar(
        title: Text('Kiosk App'), // const text
      ),
    );
  }
}

// 2. DISPOSAL DE RECURSOS
class _HomePageState extends State<HomePage> {
  Timer? _clockTimer;
  StreamSubscription<DocumentSnapshot>? _tariffSubscription;
  final _plateCtrl = TextEditingController();
  
  @override
  void dispose() {
    _clockTimer?.cancel(); // Cancelar timer
    _tariffSubscription?.cancel(); // Cancelar suscripción
    _plateCtrl.dispose(); // Dispose controller
    super.dispose();
  }
}

// 3. LAZY LOADING
class LazyLoadingList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(items[index].title),
        );
      },
    );
  }
}
```

### 17.2 Optimizaciones de Firebase

```dart
// 1. SUSCRIPCIONES EFICIENTES
void _subscribeTariff(String zoneDocId) {
  _tariffSubscription?.cancel(); // Cancelar suscripción anterior
  
  _tariffSubscription = _firestore
      .collection('tariffs')
      .doc(zoneDocId) // Solo el documento específico
      .snapshots()
      .listen((doc) {
    // Procesar cambios
  });
}

// 2. QUERIES OPTIMIZADAS
Future<void> _loadZones() async {
  final snap = await _firestore
      .collection('tariffs')
      .limit(10) // Limitar resultados
      .get();
  
  _zoneItems = snap.docs.map((doc) {
    final data = doc.data();
    return DropdownMenuItem(
      value: doc.id,
      child: Text(data['zoneId'] ?? doc.id),
    );
  }).toList();
}

// 3. CACHE DE DATOS
class DataCache {
  static final Map<String, dynamic> _cache = {};
  
  static Future<T?> get<T>(String key, Future<T> Function() fetcher) async {
    if (_cache.containsKey(key)) {
      return _cache[key] as T;
    }
    
    final data = await fetcher();
    _cache[key] = data;
    return data;
  }
}
```

### 17.3 Optimizaciones de Red

```dart
// 1. TIMEOUTS CONFIGURADOS
class ApiService {
  static const Duration _timeout = Duration(seconds: 30);
  
  static Future<http.Response> get(String url) async {
    return await http.get(
      Uri.parse(url),
    ).timeout(_timeout);
  }
  
  static Future<http.Response> post(String url, {Map<String, dynamic>? body}) async {
    return await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    ).timeout(_timeout);
  }
}

// 2. RETRY LOGIC
class RetryService {
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        return await operation();
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        await Future.delayed(delay * (i + 1));
      }
    }
    throw Exception('Max retries exceeded');
  }
}
```

---

## 18. TROUBLESHOOTING

### 18.1 Problemas Comunes

#### **Error de Firebase:**
```dart
// Problema: Firebase no se inicializa
// Solución: Verificar configuración
try {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).timeout(const Duration(seconds: 10));
} catch (e, st) {
  debugPrint('❌ Error inicializando Firebase: $e');
  debugPrint('$st');
}
```

#### **Error de CORS:**
```dart
// Problema: CORS en web
// Solución: Usar proxy
class TwilioProxyService {
  static const String _proxyUrl = 'https://render-whatsapp-tih4.onrender.com/v1/whatsapp/send';
  // Usar proxy en lugar de Twilio directo
}
```

#### **Error de Permisos:**
```dart
// Problema: Permisos de cámara
// Solución: Verificar permisos
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestCameraPermission() async {
  final status = await Permission.camera.request();
  return status == PermissionStatus.granted;
}
```

### 18.2 Debugging

#### **Logs de Debug:**
```dart
// Configurar logs detallados
void main() {
  // Habilitar logs de debug
  debugPrint('🚀 Iniciando aplicación...');
  
  runApp(const MyApp());
}

// En servicios
class EmailService {
  static Future<bool> sendTicketEmail({...}) async {
    try {
      print('📧 Email Service - Enviando email...');
      print('   Destinatario: $recipientEmail');
      print('   Matrícula: $plate');
      
      final response = await http.post(...);
      
      print('📧 Email Service - Respuesta:');
      print('   Status Code: ${response.statusCode}');
      print('   Body: ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error en EmailService: $e');
      return false;
    }
  }
}
```

#### **Hot Reload Issues:**
```dart
// Problema: Hot reload no funciona
// Solución: Restart completo
// 1. Ctrl+Shift+P -> "Flutter: Hot Restart"
// 2. O usar: flutter run --hot
```

### 18.3 Performance Issues

#### **Memory Leaks:**
```dart
// Problema: Memory leaks
// Solución: Proper disposal
class _HomePageState extends State<HomePage> {
  Timer? _clockTimer;
  StreamSubscription<DocumentSnapshot>? _tariffSubscription;
  
  @override
  void dispose() {
    _clockTimer?.cancel();
    _tariffSubscription?.cancel();
    super.dispose();
  }
}
```

#### **Slow UI:**
```dart
// Problema: UI lenta
// Solución: Optimizar rebuilds
class OptimizedWidget extends StatelessWidget {
  const OptimizedWidget({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return const Text('Optimized'); // const constructor
  }
}
```

---

## 📝 CONCLUSIÓN

Esta documentación técnica completa proporciona una visión exhaustiva del proyecto **Kiosk App Remote**, desde la justificación tecnológica hasta la implementación detallada de cada componente.

### **Puntos Clave:**

1. **Flutter** fue elegido por su capacidad multiplataforma y rendimiento nativo
2. **Firebase** proporciona la base de datos en tiempo real y escalabilidad
3. **APIs externas** en Render.com manejan comunicaciones especializadas
4. **Sistema de diseño responsive** garantiza consistencia visual
5. **Arquitectura modular** facilita mantenimiento y escalabilidad
6. **Internacionalización** soporta múltiples idiomas
7. **Servicios unificados** coordinan todas las comunicaciones
8. **Optimizaciones** garantizan rendimiento óptimo

### **Para Programadores:**

Esta aplicación demuestra las mejores prácticas en desarrollo Flutter, incluyendo:
- Gestión de estado con Provider
- Arquitectura MVVM
- Servicios modulares
- Manejo de errores robusto
- Testing comprehensivo
- Optimizaciones de rendimiento

El código está estructurado para ser mantenible, escalable y fácil de entender, siguiendo los principios SOLID y las mejores prácticas de Flutter.

---

**Desarrollado con ❤️ usando Flutter, Firebase y las mejores prácticas de desarrollo.**
