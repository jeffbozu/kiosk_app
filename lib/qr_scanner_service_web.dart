import 'dart:async';
import 'package:universal_html/html.dart' as html;

/// Servicio de escáner QR para web que usa la cámara del dispositivo
class QrScannerServiceWeb {
  
  // Stream para códigos QR escaneados
  static final StreamController<String> _qrController = StreamController<String>.broadcast();
  static Stream<String> get qrStream => _qrController.stream;
  
  // Estado del escáner
  static bool _isScannerConnected = false;
  static bool get isScannerConnected => _isScannerConnected;
  
  // Último código QR leído
  static String? _lastQrCode;
  static String? get lastQrCode => _lastQrCode;
  
  // Callback para cambios de estado
  static Function(bool)? _onScannerStatusChanged;
  
  /// Inicializa el servicio de escáner QR para web
  static Future<void> initialize({Function(bool)? onScannerStatusChanged}) async {
    _onScannerStatusChanged = onScannerStatusChanged;
    
    // En web, verificamos si hay cámara disponible
    _isScannerConnected = await _checkCameraAvailability();
    _onScannerStatusChanged?.call(_isScannerConnected);
    
    print('QrScannerServiceWeb inicializado. Cámara disponible: $_isScannerConnected');
  }
  
  /// Verifica si hay cámara disponible
  static Future<bool> _checkCameraAvailability() async {
    try {
      // Verificar si el navegador soporta getUserMedia
      if (html.window.navigator.mediaDevices == null) {
        return false;
      }
      
      // Verificar permisos de cámara
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) return false;
      
      final devices = await mediaDevices.enumerateDevices();
      final videoDevices = devices.where((device) => device.kind == 'videoinput');
      
      return videoDevices.isNotEmpty;
    } catch (e) {
      print('Error verificando cámara: $e');
      return false;
    }
  }
  
  /// Escanea un código QR usando la cámara
  static Future<String?> scanQrCode({int timeout = 30}) async {
    if (!_isScannerConnected) {
      throw Exception('No hay cámara disponible');
    }
    
    try {
      // Mostrar diálogo de escaneo con cámara
      final qrCode = await _showCameraScanner(timeout);
      
      if (qrCode != null) {
        _lastQrCode = qrCode;
        _qrController.add(qrCode);
        
        // Procesar descuento si es válido
        if (_isValidDiscount(qrCode)) {
          // Retornar el código QR como string, el servicio unificado lo procesará
          return qrCode;
        }
        
        return qrCode;
      }
      
      return null;
    } catch (e) {
      print('Error escaneando QR: $e');
      return null;
    }
  }
  
  /// Muestra el escáner de cámara
  static Future<String?> _showCameraScanner(int timeout) async {
    try {
      // Crear elemento de video para la cámara
      final videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%';
      
      // Crear canvas para capturar frames
      final canvasElement = html.CanvasElement()
        ..width = 640
        ..height = 480;
      
      // Detectar modo oscuro
      final isDarkMode = html.window.matchMedia('(prefers-color-scheme: dark)').matches;
      
      // Crear diálogo modal
      final dialog = html.DivElement()
        ..style.position = 'fixed'
        ..style.top = '0'
        ..style.left = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = 'rgba(0, 0, 0, 0.85)'
        ..style.zIndex = '9999'
        ..style.display = 'flex'
        ..style.alignItems = 'center'
        ..style.justifyContent = 'center'
        ..style.setProperty('-webkit-backdrop-filter', 'blur(4px)')
        ..style.setProperty('backdrop-filter', 'blur(4px)');
      
      // Contenido del diálogo con diseño moderno
      final content = html.DivElement()
        ..style.backgroundColor = isDarkMode ? '#1e1e1e' : '#ffffff'
        ..style.padding = '32px'
        ..style.borderRadius = '20px'
        ..style.maxWidth = '480px'
        ..style.width = '90%'
        ..style.textAlign = 'center'
        ..style.boxShadow = '0 20px 60px rgba(0, 0, 0, 0.3)'
        ..style.border = isDarkMode ? '1px solid #333' : '1px solid #e0e0e0';
      
      // Título con diseño mejorado
      final title = html.HeadingElement.h2()
        ..text = '📱 Escanear Código QR'
        ..style.marginBottom = '16px'
        ..style.marginTop = '0'
        ..style.fontSize = '24px'
        ..style.fontWeight = '600'
        ..style.color = isDarkMode ? '#ffffff' : '#1a1a1a'
        ..style.fontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
      
      // Subtítulo informativo
      final subtitle = html.ParagraphElement()
        ..text = 'Apunta la cámara hacia el código QR de descuento'
        ..style.marginBottom = '20px'
        ..style.fontSize = '14px'
        ..style.color = isDarkMode ? '#b0b0b0' : '#666666'
        ..style.fontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
      
      // Contenedor de video con diseño mejorado
      final videoContainer = html.DivElement()
        ..style.marginBottom = '20px'
        ..style.borderRadius = '16px'
        ..style.overflow = 'hidden'
        ..style.border = isDarkMode ? '2px solid #333' : '2px solid #e0e0e0'
        ..style.boxShadow = '0 8px 24px rgba(0, 0, 0, 0.15)';
      
      // Indicador de estado
      final statusIndicator = html.DivElement()
        ..style.marginBottom = '20px'
        ..style.padding = '12px 20px'
        ..style.borderRadius = '25px'
        ..style.backgroundColor = '#e3f2fd'
        ..style.border = '1px solid #2196f3'
        ..style.fontSize = '14px'
        ..style.color = '#1976d2'
        ..style.fontWeight = '500'
        ..style.fontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
        ..text = '🔍 Iniciando cámara...';
      
      // Contenedor de botones
      final buttonContainer = html.DivElement()
        ..style.display = 'flex'
        ..style.gap = '12px'
        ..style.justifyContent = 'center'
        ..style.marginTop = '24px';
      
      // Solo botón cancelar (escaneo automático)
      final cancelButton = html.ButtonElement()
        ..text = '✕ Cerrar'
        ..style.padding = '16px 32px'
        ..style.backgroundColor = isDarkMode ? '#333333' : '#f5f5f5'
        ..style.color = isDarkMode ? '#ffffff' : '#333333'
        ..style.border = isDarkMode ? '1px solid #555' : '1px solid #ddd'
        ..style.borderRadius = '12px'
        ..style.cursor = 'pointer'
        ..style.fontSize = '16px'
        ..style.fontWeight = '600'
        ..style.fontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
        ..style.transition = 'all 0.2s ease'
        ..style.minWidth = '120px';
      
      // Efectos hover para el botón
      cancelButton.onMouseEnter.listen((_) {
        cancelButton.style.backgroundColor = isDarkMode ? '#444444' : '#e0e0e0';
        cancelButton.style.transform = 'translateY(-1px)';
      });
      
      cancelButton.onMouseLeave.listen((_) {
        cancelButton.style.backgroundColor = isDarkMode ? '#333333' : '#f5f5f5';
        cancelButton.style.transform = 'translateY(0)';
      });
      
      // Agregar elementos
      videoContainer.append(videoElement);
      buttonContainer.append(cancelButton);
      
      content.append(title);
      content.append(subtitle);
      content.append(videoContainer);
      content.append(statusIndicator);
      content.append(buttonContainer);
      dialog.append(content);
      
      // Agregar al DOM
      html.document.body!.append(dialog);
      
      // Iniciar cámara
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {
          'facingMode': 'environment', // Cámara trasera si está disponible
          'width': {'ideal': 640},
          'height': {'ideal': 480}
        }
      });
      
      videoElement.srcObject = stream;
      
      // Completer para el resultado
      final completer = Completer<String?>();
      
      // Variables para el resultado
      bool isCompleted = false;
      
      // Función para completar
      void complete(String? value) {
        if (isCompleted) return;
        isCompleted = true;
        
        // Detener cámara
        stream.getTracks().forEach((track) => track.stop());
        
        // Remover diálogo
        dialog.remove();
        
        // Resolver
        completer.complete(value);
      }
      
      // Función para actualizar el indicador de estado
      void updateStatus(String message, String color) {
        statusIndicator.text = message;
        statusIndicator.style.backgroundColor = color == 'success' ? '#e8f5e8' : 
                                               color == 'error' ? '#ffebee' : 
                                               color == 'warning' ? '#fff3e0' : '#e3f2fd';
        statusIndicator.style.borderColor = color == 'success' ? '#4caf50' : 
                                           color == 'error' ? '#f44336' : 
                                           color == 'warning' ? '#ff9800' : '#2196f3';
        statusIndicator.style.color = color == 'success' ? '#2e7d32' : 
                                     color == 'error' ? '#c62828' : 
                                     color == 'warning' ? '#ef6c00' : '#1976d2';
      }

      // Iniciar escaneo automático después de que el video esté listo
      videoElement.onLoadedMetadata.listen((_) async {
        updateStatus('📷 Cámara lista - Escaneando automáticamente...', 'info');
        
        try {
          final context = canvasElement.getContext('2d');
          if (context == null) {
            updateStatus('❌ Error: No se pudo inicializar el canvas', 'error');
            complete(null);
            return;
          }
          final ctx = context as dynamic; // CanvasRenderingContext2D
          
          // Bucle de lectura automático hasta timeout o detección de QR VÁLIDO
          final startedAt = DateTime.now();
          while (!isCompleted) {
            // timeout manual
            if (DateTime.now().difference(startedAt).inSeconds >= timeout) {
              updateStatus('⏱️ Tiempo agotado - No se detectó código QR válido', 'error');
              await Future.delayed(const Duration(milliseconds: 2000));
              complete(null);
              break;
            }
            
            // Dibujar frame actual
            try {
              ctx.drawImage(videoElement, 0, 0);
            } catch (_) {
              // Continuar si hay error dibujando
            }
            
            // Obtener píxeles
            final imageData = (ctx.getImageData(0, 0, canvasElement.width!, canvasElement.height!));
            
            // Llamar a jsQR (expuesta en window.jsQR)
            final qr = (html.window as dynamic).jsQR?.call(
              imageData.data,
              canvasElement.width,
              canvasElement.height,
              {'inversionAttempts': 'dontInvert'},
            );
            
            if (qr != null && qr.data != null) {
              final qrData = qr.data as String;
              
              // Validar si el QR es válido
              if (_isValidDiscount(qrData)) {
                updateStatus('✅ ¡Código QR válido detectado!', 'success');
                await Future.delayed(const Duration(milliseconds: 800)); // Mostrar éxito brevemente
                complete(qrData);
                break;
              } else {
                // QR detectado pero no válido - mostrar mensaje y continuar escaneando
                updateStatus('⚠️ QR no soportado o no válido - Sigue escaneando...', 'warning');
                await Future.delayed(const Duration(milliseconds: 1500)); // Mostrar mensaje un poco más
                updateStatus('🔍 Buscando código QR válido...', 'info');
              }
            }
            
            // Pequeña espera para no bloquear UI
            await Future.delayed(const Duration(milliseconds: 150));
          }
        } catch (e) {
          print('Error capturando/decodificando QR: $e');
          updateStatus('❌ Error en el escaneo', 'error');
          await Future.delayed(const Duration(milliseconds: 2000));
          complete(null);
        }
      });
      
      cancelButton.onClick.listen((_) => complete(null));
      
      // Timeout global
      Timer(Duration(seconds: timeout), () {
        if (!isCompleted) {
          updateStatus('⏱️ Tiempo agotado', 'error');
          complete(null);
        }
      });
      
      return await completer.future;
      
    } catch (e) {
      print('Error iniciando cámara: $e');
      return null;
    }
  }
  
  /// Verifica si el código QR es un descuento válido
  static bool _isValidDiscount(String qrCode) {
    try {
      // Patrón: -X o -X.XX donde X son números (por ejemplo: -1, -0.90, -5.50)
      final discountPattern = RegExp(r'^-(\d+(?:\.\d{1,2})?)$');
      if (discountPattern.hasMatch(qrCode)) {
        final amount = double.parse(qrCode);
        return amount < 0 && amount > -10000; // aceptamos descuentos grandes; la UI trunca a 0
      }
      // Códigos VIP/FREE que anulan el total
      final normalized = qrCode.trim().toUpperCase();
      if (normalized == 'FREE' || normalized == 'VIP' || normalized == 'VIP-ALL' || normalized == '-ALL' || normalized == '-100%') {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Verifica si el escáner está conectado
  static Future<bool> checkScanner() async {
    return _isScannerConnected;
  }
  
  /// Obtiene el estado del servicio
  static Map<String, dynamic> getStatus() {
    return {
      'scanner_connected': _isScannerConnected,
      'last_qr_code': _lastQrCode,
      'mode': 'web',
    };
  }
  
  /// Libera recursos
  static void dispose() {
    _qrController.close();
  }
}





