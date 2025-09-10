import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import 'l10n/app_localizations.dart';

/// Widget modal para escaneo de códigos QR REALES con vista previa de cámara
class QrScannerModal extends StatefulWidget {
  final Function(double?) onQrScanned;
  final int timeoutSeconds;
  final String title;
  final String instructions;

  const QrScannerModal({
    super.key,
    required this.onQrScanned,
    this.timeoutSeconds = 30,
    this.title = 'Escanear Código QR',
    this.instructions = 'Apunta la cámara al código QR',
  });

  @override
  State<QrScannerModal> createState() => _QrScannerModalState();
}

class _QrScannerModalState extends State<QrScannerModal>
    with TickerProviderStateMixin {
  late AnimationController _scanAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;

  html.VideoElement? _videoElement;
  html.CanvasElement? _canvasElement;
  html.CanvasRenderingContext2D? _canvasContext;
  StreamSubscription<dynamic>? _qrSubscription;
  Timer? _timeoutTimer;
  Timer? _detectionTimer;
  bool _isScanning = false;
  bool _isCameraActive = false;
  String _statusMessage = 'Iniciando cámara...';
  String? _lastScannedCode;
  List<MediaDeviceInfo> _cameras = [];
  String? _currentCameraId;
  int _currentCameraIndex = 0;
  final TextEditingController _manualCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCamera();
  }

  void _initializeAnimations() {
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanAnimationController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));

    _scanAnimationController.repeat();
    _pulseAnimationController.repeat(reverse: true);
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _statusMessage = 'Obteniendo cámaras disponibles...';
      });

      // Obtener lista de cámaras
      final devices = await html.window.navigator.mediaDevices!.enumerateDevices();
      _cameras = devices.where((device) => device.kind == 'videoinput').toList();
      
      if (_cameras.isEmpty) {
        setState(() {
          _statusMessage = 'No se encontraron cámaras disponibles';
          _isScanning = false;
        });
        return;
      }

      // Buscar cámara trasera (environment) por defecto
      int preferredCameraIndex = 0;
      for (int i = 0; i < _cameras.length; i++) {
        final device = _cameras[i];
        if (device.label.toLowerCase().contains('back') || 
            device.label.toLowerCase().contains('rear') ||
            device.label.toLowerCase().contains('environment')) {
          preferredCameraIndex = i;
          break;
        }
      }

      _currentCameraIndex = preferredCameraIndex;
      _currentCameraId = _cameras[preferredCameraIndex].deviceId;

      setState(() {
        _statusMessage = 'Iniciando cámara trasera...';
      });

      await _startCameraWithId(_currentCameraId!);

    } catch (e) {
      setState(() {
        _statusMessage = 'Error al acceder a la cámara: $e';
        _isScanning = false;
      });
    }
  }

  Future<void> _startCameraWithId(String deviceId) async {
    try {
      // Detener cámara anterior si existe
      if (_videoElement != null) {
        _videoElement!.srcObject?.getTracks().forEach((track) => track.stop());
      }

      // Crear elementos HTML para la cámara
      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..playsInline = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';

      _canvasElement = html.CanvasElement()
        ..width = 640
        ..height = 480;

      _canvasContext = _canvasElement!.getContext('2d') as html.CanvasRenderingContext2D;

      // Solicitar acceso a la cámara específica
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {
          'deviceId': {'exact': deviceId},
          'facingMode': 'environment', // Cámara trasera por defecto
          'width': {'ideal': 640},
          'height': {'ideal': 480},
        }
      });

      _videoElement!.srcObject = stream;
      await _videoElement!.play();

      setState(() {
        _isCameraActive = true;
        _statusMessage = 'Cámara activa - Detección automática iniciada';
        _isScanning = true;
      });

      // Iniciar detección de QR REAL
      _startRealQrDetection();

      // Configurar timeout
      _timeoutTimer = Timer(Duration(seconds: widget.timeoutSeconds), () {
        if (mounted) {
          _stopScanning();
          widget.onQrScanned(null);
        }
      });

    } catch (e) {
      setState(() {
        _statusMessage = 'Error al iniciar cámara: $e';
        _isScanning = false;
      });
    }
  }

  void _startRealQrDetection() {
    // Detección de QR REAL cada 100ms
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isScanning || !mounted) {
        timer.cancel();
        return;
      }

      _detectRealQrCode();
    });
  }

  void _detectRealQrCode() {
    if (_videoElement == null || _canvasElement == null || _canvasContext == null) return;

    try {
      // Dibujar frame actual en el canvas
      _canvasContext!.drawImageScaled(
        _videoElement!,
        0,
        0,
        _canvasElement!.width!,
        _canvasElement!.height!,
      );

      // Obtener datos de imagen
      final imageData = _canvasContext!.getImageData(
        0,
        0,
        _canvasElement!.width!,
        _canvasElement!.height!,
      );

      // Usar jsQR REAL para detectar códigos QR
      final qrCode = _detectQrWithJsQR(imageData);
      
      if (qrCode != null && qrCode != _lastScannedCode) {
        _lastScannedCode = qrCode;
        _processQrCode(qrCode);
      }
    } catch (e) {
      print('Error detectando QR real: $e');
    }
  }

  String? _detectQrWithJsQR(html.ImageData imageData) {
    try {
      // Usar jsQR real para detectar códigos QR
      final jsQR = js.context['jsQR'];
      if (jsQR == null) {
        print('jsQR no está disponible');
        return null;
      }

      final result = jsQR.callMethod('call', [
        null, // this context
        imageData.data, // image data
        imageData.width, // width
        imageData.height, // height
        js.JsObject.jsify({
          'inversionAttempts': 'dontInvert',
        })
      ]);

      if (result != null && result['data'] != null) {
        final qrData = result['data'] as String;
        print('QR detectado: $qrData');
        return qrData;
      }
    } catch (e) {
      print('Error en detección jsQR: $e');
    }
    return null;
  }

  void _processQrCode(String qrCode) {
    setState(() {
      _statusMessage = 'Código QR detectado: $qrCode';
    });

    // Procesar el código QR
    final discount = _parseQrCode(qrCode);
    
    if (discount != null) {
      _stopScanning();
      widget.onQrScanned(discount);
    } else {
      setState(() {
        _statusMessage = 'Código QR no válido: $qrCode';
      });
    }
  }

  double? _parseQrCode(String qrCode) {
    final cleaned = qrCode.trim().toUpperCase();
    
    // Códigos FREE/VIP
    if (cleaned == 'FREE' || cleaned == 'VIP' || cleaned == 'GRATIS') {
      return -99999.0; // Descuento total
    }
    
    // Código 0.00
    if (cleaned == '0.00' || cleaned == '0') {
      return 0.0; // Descuento total
    }
    
    // Descuento numérico
    final parsed = double.tryParse(cleaned);
    if (parsed != null) {
      return parsed;
    }
    
    return null;
  }

  void _switchCamera() {
    if (_cameras.length <= 1) return;
    
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    _currentCameraId = _cameras[_currentCameraIndex].deviceId;
    
    setState(() {
      _statusMessage = 'Cambiando a cámara ${_currentCameraIndex + 1}...';
    });
    
    _startCameraWithId(_currentCameraId!);
  }

  void _stopScanning() {
    setState(() {
      _isScanning = false;
      _statusMessage = 'Deteniendo escáner...';
    });

    _timeoutTimer?.cancel();
    _detectionTimer?.cancel();
    _qrSubscription?.cancel();
    
    if (_videoElement != null) {
      _videoElement!.srcObject?.getTracks().forEach((track) => track.stop());
    }
  }

  void _submitManualCode() {
    final code = _manualCodeController.text.trim();
    if (code.isNotEmpty) {
      final discount = _parseQrCode(code);
      if (discount != null) {
        _stopScanning();
        widget.onQrScanned(discount);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código no válido'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _pulseAnimationController.dispose();
    _manualCodeController.dispose();
    _stopScanning();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _statusMessage,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botón cambiar cámara
                  if (_cameras.length > 1)
                    IconButton(
                      onPressed: _switchCamera,
                      icon: const Icon(Icons.switch_camera, color: Colors.white),
                      tooltip: 'Cambiar cámara',
                    ),
                  IconButton(
                    onPressed: () {
                      _stopScanning();
                      widget.onQrScanned(null);
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Camera Preview
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // Camera view
                      if (_isCameraActive && _videoElement != null)
                        HtmlElementView(
                          viewType: 'video',
                          onPlatformViewCreated: (id) {
                            // El video se renderiza automáticamente
                          },
                        ),
                      
                      // Overlay de escaneo
                      if (_isScanning)
                        AnimatedBuilder(
                          animation: _scanAnimation,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: QrScanOverlayPainter(
                                scanProgress: _scanAnimation.value,
                                pulseScale: _pulseAnimation.value,
                              ),
                            );
                          },
                        ),
                      
                      // Instrucciones
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Apunta la cámara al código QR\nDetección automática en tiempo real',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Manual input section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.keyboard, color: Colors.white70, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'O introduce el código manualmente:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualCodeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Ej: FREE, 5.00, VIP...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[600]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[600]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                          ),
                          onSubmitted: (_) => _submitManualCode(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _submitManualCode,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Aplicar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Footer con solo botón cancelar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child: FilledButton.icon(
                  onPressed: () {
                    _stopScanning();
                    widget.onQrScanned(null);
                  },
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancelar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(200, 48),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter personalizado para el overlay de escaneo QR
class QrScanOverlayPainter extends CustomPainter {
  final double scanProgress;
  final double pulseScale;

  QrScanOverlayPainter({
    required this.scanProgress,
    required this.pulseScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final scanSize = 200.0 * pulseScale;
    
    // Dibujar marco de escaneo
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: scanSize, height: scanSize),
      const Radius.circular(12),
    );
    
    canvas.drawRRect(rect, paint);
    
    // Dibujar línea de escaneo animada
    final scanY = center.dy - scanSize / 2 + (scanSize * scanProgress);
    final scanLinePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(
      Offset(center.dx - scanSize / 2 + 20, scanY),
      Offset(center.dx + scanSize / 2 - 20, scanY),
      scanLinePaint,
    );
    
    // Dibujar esquinas
    final cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // Esquina superior izquierda
    canvas.drawLine(
      Offset(center.dx - scanSize / 2, center.dy - scanSize / 2),
      Offset(center.dx - scanSize / 2 + cornerLength, center.dy - scanSize / 2),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(center.dx - scanSize / 2, center.dy - scanSize / 2),
      Offset(center.dx - scanSize / 2, center.dy - scanSize / 2 + cornerLength),
      cornerPaint,
    );
    
    // Esquina superior derecha
    canvas.drawLine(
      Offset(center.dx + scanSize / 2, center.dy - scanSize / 2),
      Offset(center.dx + scanSize / 2 - cornerLength, center.dy - scanSize / 2),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(center.dx + scanSize / 2, center.dy - scanSize / 2),
      Offset(center.dx + scanSize / 2, center.dy - scanSize / 2 + cornerLength),
      cornerPaint,
    );
    
    // Esquina inferior izquierda
    canvas.drawLine(
      Offset(center.dx - scanSize / 2, center.dy + scanSize / 2),
      Offset(center.dx - scanSize / 2 + cornerLength, center.dy + scanSize / 2),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(center.dx - scanSize / 2, center.dy + scanSize / 2),
      Offset(center.dx - scanSize / 2, center.dy + scanSize / 2 - cornerLength),
      cornerPaint,
    );
    
    // Esquina inferior derecha
    canvas.drawLine(
      Offset(center.dx + scanSize / 2, center.dy + scanSize / 2),
      Offset(center.dx + scanSize / 2 - cornerLength, center.dy + scanSize / 2),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(center.dx + scanSize / 2, center.dy + scanSize / 2),
      Offset(center.dx + scanSize / 2, center.dy + scanSize / 2 - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}