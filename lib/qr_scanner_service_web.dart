import 'dart:async';
import 'package:universal_html/html.dart' as html;
import 'l10n/app_localizations.dart';
import 'package:flutter/material.dart';

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
    // Obtener contexto para traducciones (fallback a español si no hay contexto)
    BuildContext? context;
    try {
      // Intentar obtener contexto del navegador actual si está disponible
      context = null; // Simplificado para evitar problemas de API
    } catch (e) {
      // Ignorar error de contexto
    }
    
    String t(String key) {
      if (context != null) {
        try {
          return AppLocalizations.of(context).t(key);
        } catch (e) {
          // Fallback a español
        }
      }
      // Traducciones fallback en español
      final fallbacks = {
        'qrScanTitle': 'Escanear Código QR',
        'qrScanSubtitle': 'Apunta la cámara hacia el código QR de descuento',
        'qrScanClose': 'Cerrar',
        'qrScanSwitchCamera': 'Cambiar cámara',
        'qrScanInitializing': 'Iniciando cámara...',
        'qrScanReady': 'Cámara lista - Escaneando...',
        'qrScanValid': 'Código válido',
        'qrScanTimeout': 'Tiempo agotado - No se detectó QR',
      };
      return fallbacks[key] ?? key;
    }
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
        ..text = '📱 ${t('qrScanTitle')}'
        ..style.marginBottom = '16px'
        ..style.marginTop = '0'
        ..style.fontSize = '24px'
        ..style.fontWeight = '600'
        ..style.color = isDarkMode ? '#ffffff' : '#1a1a1a'
        ..style.fontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
      
      // Subtítulo informativo
      final subtitle = html.ParagraphElement()
        ..text = t('qrScanSubtitle')
        ..style.marginBottom = '20px'
        ..style.fontSize = '14px'
        ..style.color = isDarkMode ? '#b0b0b0' : '#666666'
        ..style.fontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
      
      // Contenedor de video con diseño mejorado (más pequeño para evitar solaparse con barras del móvil)
      final videoContainer = html.DivElement()
        ..style.marginBottom = '16px'
        ..style.borderRadius = '16px'
        ..style.overflow = 'hidden'
        ..style.border = isDarkMode ? '2px solid #333' : '2px solid #e0e0e0'
        ..style.boxShadow = '0 8px 24px rgba(0, 0, 0, 0.15)'
        ..style.maxHeight = '360px'
        ..style.height = 'min(60vh, 360px)';
      
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
        ..text = '🔍 ${t('qrScanInitializing')}...';
      
      // Contenedor de botones (con safe-area inferior)
      final buttonContainer = html.DivElement()
        ..style.display = 'flex'
        ..style.gap = '12px'
        ..style.justifyContent = 'center'
        ..style.marginTop = '16px'
        ..style.paddingBottom = 'calc(env(safe-area-inset-bottom, 0px) + 12px)';
      
      // Botón cerrar con estilo tipo app
      final cancelButton = html.ButtonElement()
        ..text = '✕ ${t('qrScanClose')}'
        ..style.padding = '18px 36px'
        ..style.backgroundColor = isDarkMode ? '#0d47a1' : '#1a73e8'
        ..style.color = '#ffffff'
        ..style.border = 'none'
        ..style.borderRadius = '14px'
        ..style.cursor = 'pointer'
        ..style.fontSize = '18px'
        ..style.fontWeight = '700'
        ..style.fontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
        ..style.transition = 'all 0.2s ease'
        ..style.minWidth = '200px'
        ..style.boxShadow = '0 6px 18px rgba(26, 115, 232, 0.35)';

      // Botón para cambiar de cámara
      final switchCamButton = html.ButtonElement()
        ..text = '🔁 ${t('qrScanSwitchCamera')}'
        ..style.padding = '16px 24px'
        ..style.backgroundColor = isDarkMode ? '#2d2d2d' : '#eeeeee'
        ..style.color = isDarkMode ? '#ffffff' : '#333333'
        ..style.border = isDarkMode ? '1px solid #555' : '1px solid #ddd'
        ..style.borderRadius = '12px'
        ..style.cursor = 'pointer'
        ..style.fontSize = '16px'
        ..style.fontWeight = '600'
        ..style.fontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
        ..style.transition = 'all 0.2s ease'
        ..style.minWidth = '160px';
      
      // Efectos hover para el botón
      cancelButton.onMouseEnter.listen((_) {
        cancelButton.style.transform = 'translateY(-1px)';
        cancelButton.style.boxShadow = '0 10px 24px rgba(26, 115, 232, 0.45)';
      });
      cancelButton.onMouseLeave.listen((_) {
        cancelButton.style.transform = 'translateY(0)';
        cancelButton.style.boxShadow = '0 6px 18px rgba(26, 115, 232, 0.35)';
      });
      
      // Agregar elementos
      videoContainer.append(videoElement);
      buttonContainer.append(switchCamButton);
      buttonContainer.append(cancelButton);
      
      content.append(title);
      content.append(subtitle);
      content.append(videoContainer);
      content.append(statusIndicator);
      content.append(buttonContainer);
      dialog.append(content);
      
      // Agregar al DOM
      html.document.body!.append(dialog);
      
      // Iniciar cámara con control de dispositivos
      List<dynamic> videoInputs = [];
      int currentDeviceIndex = 0;

      Future<html.MediaStream> startStream({String? deviceId}) async {
        final constraints = {
          'video': deviceId != null
              ? {
                  'deviceId': {'exact': deviceId},
                  'width': {'ideal': 1280, 'min': 640},
                  'height': {'ideal': 720, 'min': 480}
                }
              : {
                  'facingMode': {'ideal': 'environment'},
                  'width': {'ideal': 1280, 'min': 640},
                  'height': {'ideal': 720, 'min': 480}
                }
        };
        return await html.window.navigator.mediaDevices!.getUserMedia(constraints);
      }

      try {
        final devices = await html.window.navigator.mediaDevices!.enumerateDevices();
        videoInputs = devices.where((d) => (d as dynamic).kind == 'videoinput').toList();
      } catch (e) {
        print('No se pudieron enumerar dispositivos: $e');
      }

      var stream = await startStream(
        deviceId: videoInputs.isNotEmpty ? (videoInputs[currentDeviceIndex] as dynamic).deviceId as String? : null,
      );
      videoElement.srcObject = stream;
      videoElement.setAttribute('playsinline', 'true');
      
      // Alternar cámara
      switchCamButton.onClick.listen((_) async {
        try {
          if (videoInputs.isEmpty) return;
          currentDeviceIndex = (currentDeviceIndex + 1) % videoInputs.length;
          // Detener stream actual
          stream.getTracks().forEach((t) => t.stop());
          // Iniciar nuevo stream con el siguiente deviceId
          final nextId = (videoInputs[currentDeviceIndex] as dynamic).deviceId as String?;
          stream = await startStream(deviceId: nextId);
          videoElement.srcObject = stream;
        } catch (e) {
          print('Error cambiando de cámara: $e');
        }
      });
      
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

      // Inicializar el canvas cuando el video esté listo y comenzar escaneo automático
      videoElement.onLoadedMetadata.listen((_) async {
        updateStatus('📷 ${t('qrScanReady')}', 'info');
        
        // Verificar si jsQR está disponible
        final jsQRAvailable = (html.window as dynamic).jsQR != null;
        print('🔍 jsQR disponible: $jsQRAvailable');
        if (!jsQRAvailable) {
          updateStatus('❌ Error: jsQR no está cargado', 'error');
          await Future.delayed(const Duration(milliseconds: 2000));
          complete(null);
          return;
        }

        final context = canvasElement.getContext('2d');
        if (context == null) {
          updateStatus('❌ Error: No se pudo inicializar el canvas', 'error');
          await Future.delayed(const Duration(milliseconds: 1600));
          complete(null);
          return;
        }
        final ctx = context as dynamic;

        // Fijar canvas de procesamiento a 640x480 para mejorar estabilidad de jsQR
        canvasElement.width = 640;
        canvasElement.height = 480;

        _isScanning = true;
        final startedAt = DateTime.now();

        int frameCounter = 0;
        Future<void> scanFrame(num _) async {
          if (!_isScanning || isCompleted) return;

          // Timeout
          if (DateTime.now().difference(startedAt).inSeconds >= timeout) {
            updateStatus('⏱️ ${t('qrScanTimeout')}', 'error');
            _isScanning = false;
            await Future.delayed(const Duration(milliseconds: 800));
            complete(null);
            return;
          }

          try {
            if (videoElement.readyState >= 2) {
              // Escalar el frame del video al canvas 640x480
              ctx.drawImage(videoElement, 0, 0, canvasElement.width, canvasElement.height);
              final imageData = ctx.getImageData(0, 0, canvasElement.width, canvasElement.height);

              // Decodificar 1 de cada 2 frames para estabilidad
              frameCounter = (frameCounter + 1) & 0x7fffffff;
              if (frameCounter % 2 == 0) {
                // Intento más permisivo primero
                dynamic qr = (html.window as dynamic).jsQR?.call(
                  imageData.data,
                  canvasElement.width,
                  canvasElement.height,
                  {'inversionAttempts': 'attemptBoth'},
                );
                // Fallback sin invertir
                if ((qr == null || qr.data == null)) {
                  qr = (html.window as dynamic).jsQR?.call(
                    imageData.data,
                    canvasElement.width,
                    canvasElement.height,
                    {'inversionAttempts': 'dontInvert'},
                  );
                }

                if (qr != null && qr.data != null) {
                  final qrData = qr.data as String;
                  print('🔍 QR detectado: "$qrData"');
                  if (_isValidDiscount(qrData)) {
                    updateStatus('✅ ${t('qrScanValid')}', 'success');
                    _isScanning = false;
                    await Future.delayed(const Duration(milliseconds: 400));
                    complete(qrData);
                    return;
                  } else {
                    // Mantener el escaneo, no saturar con mensajes
                  }
                }
              }
            }
          } catch (e) {
            print('Error en scanFrame: $e');
          }

          if (_isScanning) html.window.requestAnimationFrame(scanFrame);
        }

        html.window.requestAnimationFrame(scanFrame);
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
      // Limpiar el código: trim + eliminar caracteres invisibles comunes
      final cleaned = qrCode.trim().replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '');
      print('🔍 QR original: "$qrCode" → limpio: "$cleaned" (longitud: ${cleaned.length})');
      
      // Mostrar cada carácter para debug
      for (int i = 0; i < cleaned.length && i < 10; i++) {
        print('  Carácter $i: "${cleaned[i]}" (código: ${cleaned.codeUnitAt(i)})');
      }
      
      // 1. Códigos VIP/FREE que anulan el total (verificar primero)
      final normalized = cleaned.toUpperCase();
      if (normalized == 'FREE' || normalized == 'VIP' || normalized == 'VIP-ALL' || normalized == '-ALL' || normalized == '-100%') {
        print('✅ QR válido como FREE/VIP: $normalized');
        return true;
      }
      
      // 2. Patrón de descuento más permisivo: cualquier cosa que empiece con - seguido de números
      if (cleaned.startsWith('-')) {
        // Extraer la parte numérica después del -
        final numberPart = cleaned.substring(1).replaceAll(RegExp(r'[^0-9.]'), '');
        print('🔄 Extrayendo número de "$cleaned" → "$numberPart"');
        
        final number = double.tryParse(numberPart);
        if (number != null && number > 0 && number <= 10000) {
          print('✅ QR válido como descuento: -$number');
          return true;
        } else {
          print('❌ Número no válido o fuera de rango: $number');
        }
      }
      
      // 3. Patrón estricto como fallback: -X o -X.XX donde X son números
      final discountPattern = RegExp(r'^-\d+(?:\.\d+)?$');
      if (discountPattern.hasMatch(cleaned)) {
        final amount = double.tryParse(cleaned);
        if (amount != null && amount < 0 && amount >= -10000) {
          print('✅ QR válido (patrón estricto): $amount');
          return true;
        }
      }
      
      // 4. Intentar extraer cualquier número precedido por -
      final flexiblePattern = RegExp(r'-\s*(\d+(?:\.\d+)?)');
      final match = flexiblePattern.firstMatch(cleaned);
      if (match != null) {
        final numberStr = match.group(1);
        final number = double.tryParse(numberStr ?? '');
        if (number != null && number > 0 && number <= 10000) {
          print('✅ QR válido (patrón flexible): -$number');
          return true;
        }
      }
      
      print('❌ QR no válido: "$cleaned"');
      return false;
    } catch (e) {
      print('💥 Error validando QR: $e');
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





