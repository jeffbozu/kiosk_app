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
  // Variable de control de escaneo a nivel de clase
  static bool _isScanning = false;
  
  static Future<String?> _showCameraScanner(int timeout) async {
    try {
      // Resetear el estado de escaneo
      _isScanning = false;
      
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
      
      // Botón de escaneo manual
      final scanButton = html.ButtonElement()
        ..text = '🔍 Escanear QR'
        ..style.padding = '16px 32px'
        ..style.backgroundColor = isDarkMode ? '#1a73e8' : '#1a73e8'
        ..style.color = '#ffffff'
        ..style.border = 'none'
        ..style.borderRadius = '12px'
        ..style.cursor = 'pointer'
        ..style.fontSize = '16px'
        ..style.fontWeight = '600'
        ..style.fontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
        ..style.transition = 'all 0.2s ease'
        ..style.minWidth = '180px';
      
      // Botón cancelar
      final cancelButton = html.ButtonElement()
        ..text = '✕ Cerrar'
        ..style.padding = '16px 24px'
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
      buttonContainer.append(scanButton);
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

      // Inicializar el canvas cuando el video esté listo
      videoElement.onLoadedMetadata.listen((_) async {
        updateStatus('📷 Cámara lista - Presiona "Escanear QR" para comenzar', 'info');
        
        final context = canvasElement.getContext('2d');
        if (context == null) {
          updateStatus('❌ Error: No se pudo inicializar el canvas', 'error');
          await Future.delayed(const Duration(milliseconds: 2000));
          complete(null);
          return;
        }
        final ctx = context as dynamic; // CanvasRenderingContext2D
        
        // Usar la variable de clase _isScanning
        DateTime? scanStartTime;
        
        // Función para realizar un solo escaneo
        Future<void> performScan() async {
          if (isCompleted || !_isScanning) return;
          
          try {
            // Verificar timeout
            if (scanStartTime != null && 
                DateTime.now().difference(scanStartTime!).inSeconds >= timeout) {
              updateStatus('⏱️ Tiempo agotado - No se detectó código QR válido', 'error');
              _isScanning = false;
              scanButton.text = '🔁 Reintentar';
              return;
            }
            
            // Verificar que el video esté listo
            if (videoElement.readyState < 2) {
              await Future.delayed(const Duration(milliseconds: 100));
              performScan();
              return;
            }
            
            // Dibujar frame actual
            ctx.drawImage(videoElement, 0, 0, canvasElement.width, canvasElement.height);
            
            // Obtener píxeles
            final imageData = ctx.getImageData(0, 0, canvasElement.width, canvasElement.height);
            
            // Llamar a jsQR (expuesta en window.jsQR) con configuración más permisiva
            final qr = (html.window as dynamic).jsQR?.call(
              imageData.data,
              canvasElement.width,
              canvasElement.height,
              {
                'inversionAttempts': 'dontInvert', // Usar 'dontInvert' para mejor rendimiento
              },
            );
            
            if (qr != null && qr.data != null) {
              final qrData = qr.data as String;
              // QR detectado
              
              // Validar si el QR es válido
              if (_isValidDiscount(qrData)) {
                updateStatus('✅ ¡Código QR válido detectado!', 'success');
                _isScanning = false;
                await Future.delayed(const Duration(milliseconds: 800));
                complete(qrData);
                return;
              } else {
                // QR detectado pero no válido
                updateStatus('⚠️ Código no válido - Intenta con otro', 'error');
                _isScanning = false;
                scanButton.text = '🔁 Reintentar';
                return;
              }
            }
            
            // Continuar escaneando si aún está activo
            if (_isScanning) {
              html.window.requestAnimationFrame((_) => performScan());
            }
            
          } catch (e) {
            print('Error en performScan: $e');
            // Reintentar después de un error
            if (_isScanning) {
              await Future.delayed(const Duration(milliseconds: 300));
              performScan();
            }
          }
        }
        
        // Manejador del botón de escaneo
        scanButton.onClick.listen((_) async {
          if (!_isScanning) {
            // Iniciar escaneo
            _isScanning = true;
            scanStartTime = DateTime.now();
            scanButton.text = '🔄 Escaneando...';
            scanButton.style.backgroundColor = isDarkMode ? '#0d47a1' : '#0d47a1';
            updateStatus('🔍 Escaneando código QR...', 'info');
            performScan();
          } else {
            // Detener escaneo
            _isScanning = false;
            scanButton.text = '🔍 Escanear QR';
            scanButton.style.backgroundColor = isDarkMode ? '#1a73e8' : '#1a73e8';
            updateStatus('⏹️ Escaneo detenido', 'info');
          }
        });
      });
      
      cancelButton.onClick.listen((_) {
        _isScanning = false;
        complete(null);
      });
      
      // Timeout global como respaldo (solo para cierre inactivo)
      Timer(Duration(seconds: timeout * 2), () {
        if (!isCompleted) {
          updateStatus('⚠️ Inactividad - La ventana se cerrará pronto', 'warning');
          Timer(const Duration(seconds: 5), () {
            if (!isCompleted) {
              complete(null);
            }
          });
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
      final trimmed = qrCode.trim();
      // QR detectado
      
      // Validando QR
      
      // Patrón más permisivo: -X o -X.XX donde X son números
      final discountPattern = RegExp(r'^-\d+(?:\.\d+)?$');
      if (discountPattern.hasMatch(trimmed)) {
        final amount = double.tryParse(trimmed);
        if (amount != null && amount < 0 && amount >= -10000) {
          // QR válido como descuento
          return true;
        } else {
          // Número fuera de rango
        }
      } else {
        // No coincide con patrón de descuento
      }
      
      // Códigos VIP/FREE que anulan el total
      final normalized = trimmed.toUpperCase();
      if (normalized == 'FREE' || normalized == 'VIP' || normalized == 'VIP-ALL' || normalized == '-ALL' || normalized == '-100%') {
        // QR válido como FREE/VIP
        return true;
      }
      
      // Intentar validar cualquier contenido que empiece con -
      if (trimmed.startsWith('-')) {
        // Contenido empieza con -, validando
        final numberPart = trimmed.substring(1);
        final number = double.tryParse(numberPart);
        if (number != null && number >= 0) {
          // QR válido (formato alternativo)
          return true;
        }
      }
      
      // QR no válido
      return false;
    } catch (e) {
      // Error validando QR
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





