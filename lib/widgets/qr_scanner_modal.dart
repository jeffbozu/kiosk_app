import 'dart:async';
import 'dart:html' as html; // Use dart:html for web-specific APIs
import 'dart:js' as js; // For calling jsQR
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class QrScannerModal extends StatefulWidget {
  final Function(double?) onQrScanned;
  final int timeoutSeconds;

  const QrScannerModal({
    super.key,
    required this.onQrScanned,
    this.timeoutSeconds = 30,
  });

  @override
  State<QrScannerModal> createState() => _QrScannerModalState();
}

class _QrScannerModalState extends State<QrScannerModal> {
  html.VideoElement? _videoElement;
  html.CanvasElement? _canvasElement;
  html.CanvasRenderingContext2D? _canvasContext;
  StreamSubscription? _timeoutSubscription;
  Timer? _detectionTimer;
  bool _isScanning = false;
  bool _isCameraActive = false;
  String _statusMessage = 'Iniciando cámara...';
  String? _lastScannedCode;
  List<dynamic> _cameras = []; // Changed from MediaDeviceInfo to dynamic
  String? _currentCameraId;
  int _currentCameraIndex = 0;
  final TextEditingController _manualCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Enumerar dispositivos de cámara
      final devices = await html.window.navigator.mediaDevices!.enumerateDevices();
      _cameras = devices.where((device) => device['kind'] == 'videoinput').toList();
      
      print('📷 Cámaras encontradas: ${_cameras.length}');
      
      // Buscar cámara trasera por defecto
      int rearCameraIndex = 0;
      for (int i = 0; i < _cameras.length; i++) {
        final label = _cameras[i]['label']?.toString().toLowerCase() ?? '';
        if (label.contains('back') || label.contains('rear') || label.contains('environment')) {
          rearCameraIndex = i;
          break;
        }
      }
      
      _currentCameraIndex = rearCameraIndex;
      _currentCameraId = _cameras.isNotEmpty ? _cameras[_currentCameraIndex]['deviceId']?.toString() : null;
      
      await _startCameraWithId(_currentCameraId);
    } catch (e) {
      print('Error inicializando cámara: $e');
      setState(() {
        _statusMessage = 'Error: No se pudo acceder a la cámara';
      });
    }
  }

  Future<void> _startCameraWithId(String? deviceId) async {
    try {
      final constraints = {
        'video': deviceId != null
            ? {
                'deviceId': {'exact': deviceId},
                'width': {'ideal': 1280, 'min': 640},
                'height': {'ideal': 720, 'min': 480}
              }
            : {
                'facingMode': {'exact': 'environment'}, // Cámara trasera por defecto
                'width': {'ideal': 1280, 'min': 640},
                'height': {'ideal': 720, 'min': 480}
              }
      };

      final stream = await html.window.navigator.mediaDevices!.getUserMedia(constraints);
      
      _videoElement = html.VideoElement()
        ..srcObject = stream
        ..autoplay = true
        ..muted = true
        ..setAttribute('playsinline', 'true'); // Fixed: use setAttribute instead of playsInline

      _canvasElement = html.CanvasElement()
        ..width = 640
        ..height = 480;

      _canvasContext = _canvasElement!.getContext('2d') as html.CanvasRenderingContext2D?;

      setState(() {
        _isCameraActive = true;
        _statusMessage = 'Cámara activa - Escaneando...';
        _isScanning = true;
      });

      // Iniciar detección automática
      _startQrDetection();
    } catch (e) {
      print('Error iniciando cámara: $e');
      setState(() {
        _statusMessage = 'Error: No se pudo iniciar la cámara';
      });
    }
  }

  void _startQrDetection() {
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isScanning || !mounted) {
        timer.cancel();
        return;
      }
      _detectQrCode();
    });
  }

  void _detectQrCode() {
    if (_videoElement == null || _canvasElement == null || _canvasContext == null) return;

    try {
      _canvasContext!.drawImageScaled(_videoElement!, 0, 0, _canvasElement!.width!, _canvasElement!.height!);
      final imageData = _canvasContext!.getImageData(0, 0, _canvasElement!.width!, _canvasElement!.height!);

      // Usar jsQR para la detección real
      final qrCode = js.context.callMethod('jsQR', [imageData.data, imageData.width, imageData.height]);

      if (qrCode != null && qrCode['data'] != null) {
        final String scannedData = qrCode['data'];
        if (scannedData.isNotEmpty && scannedData != _lastScannedCode) {
          _lastScannedCode = scannedData;
          _processQrCode(scannedData);
        }
      }
    } catch (e) {
      print('Error detectando QR: $e');
    }
  }

  void _switchCamera() {
    if (_cameras.length <= 1) return;

    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    _currentCameraId = _cameras[_currentCameraIndex]['deviceId']?.toString();

    setState(() {
      _statusMessage = 'Cambiando a cámara ${_currentCameraIndex + 1}...';
    });

    _startCameraWithId(_currentCameraId!);
  }

  void _processQrCode(String qrCode) {
    print('🔍 QR detectado: "$qrCode"');
    
    // Detener escaneo
    _isScanning = false;
    _detectionTimer?.cancel();
    
    // Procesar el código QR
    final discount = _parseQrDiscount(qrCode);
    
    setState(() {
      _statusMessage = 'Código válido detectado!';
    });
    
    // Cerrar modal y retornar resultado
    widget.onQrScanned(discount);
  }

  double? _parseQrDiscount(String qrCode) {
    final cleaned = qrCode.trim();
    
    // Patrones FREE/VIP
    final freePatterns = ['FREE', 'VIP', 'GRATIS', '0.00', '-0.00', '0', '-0'];
    final normalized = cleaned.toUpperCase();
    
    for (final pattern in freePatterns) {
      if (normalized.contains(pattern) || cleaned.contains(pattern)) {
        return 0.0; // Precio final 0.00€
      }
    }
    
    // Descuentos numéricos
    if (cleaned.startsWith('-')) {
      final numberPart = cleaned.substring(1).replaceAll(RegExp(r'[^0-9.]'), '');
      final number = double.tryParse(numberPart);
      if (number != null && number > 0) {
        return -number; // Descuento negativo
      }
    }
    
    // Números sin signo
    final number = double.tryParse(cleaned);
    if (number != null && number > 0) {
      return -number; // Descuento negativo
    }
    
    return null; // No válido
  }

  void _submitManualCode() {
    final code = _manualCodeController.text.trim();
    if (code.isNotEmpty) {
      _processQrCode(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Escanear Código QR',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => widget.onQrScanned(null),
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Camera preview placeholder
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                          width: 2,
                        ),
                      ),
                      child: _isCameraActive
                          ? const Center(
                              child: Text(
                                'Cámara activa\nEscaneando automáticamente...',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Status message
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _statusMessage.contains('Error')
                            ? Colors.red.withOpacity(0.1)
                            : _statusMessage.contains('válido')
                                ? Colors.green.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _statusMessage.contains('Error')
                              ? Colors.red
                              : _statusMessage.contains('válido')
                                  ? Colors.green
                                  : Colors.blue,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _statusMessage.contains('Error')
                              ? Colors.red[700]
                              : _statusMessage.contains('válido')
                                  ? Colors.green[700]
                                  : Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Manual input
                    TextField(
                      controller: _manualCodeController,
                      decoration: InputDecoration(
                        labelText: 'O introduce el código manualmente',
                        hintText: 'Ej: FREE, -5.00, -0.5',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.keyboard),
                        suffixIcon: IconButton(
                          onPressed: _submitManualCode,
                          icon: const Icon(Icons.check),
                        ),
                      ),
                      onSubmitted: (_) => _submitManualCode(),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Camera switch button (only if multiple cameras)
                    if (_cameras.length > 1)
                      ElevatedButton.icon(
                        onPressed: _switchCamera,
                        icon: const Icon(Icons.switch_camera),
                        label: Text('Cambiar cámara (${_currentCameraIndex + 1}/${_cameras.length})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          foregroundColor: Theme.of(context).colorScheme.onSecondary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _timeoutSubscription?.cancel();
    _manualCodeController.dispose();
    
    // Detener cámara
    if (_videoElement != null) {
      final stream = _videoElement!.srcObject as html.MediaStream?;
      stream?.getTracks().forEach((track) => track.stop());
    }
    
    super.dispose();
  }
}
