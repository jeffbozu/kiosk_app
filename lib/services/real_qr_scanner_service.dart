import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../l10n/app_localizations.dart';

/// Servicio de escáner QR real que usa la cámara del dispositivo
class RealQrScannerService {
  static MobileScannerController? _controller;
  static bool _isInitialized = false;
  static bool _isScanning = false;
  
  /// Inicializa el servicio de escáner QR (sin solicitar permisos)
  static Future<bool> initialize() async {
    try {
      // Solo verificar si la cámara está disponible, sin solicitar permisos
      _isInitialized = true;
      print('✅ RealQrScannerService inicializado (permisos se solicitarán cuando sea necesario)');
      return true;
    } catch (e) {
      print('❌ Error inicializando RealQrScannerService: $e');
      return false;
    }
  }

  /// Inicializa la cámara y solicita permisos cuando sea necesario
  static Future<bool> _initializeCamera() async {
    try {
      // Verificar permisos de cámara
      final cameraStatus = await Permission.camera.status;
      if (!cameraStatus.isGranted) {
        final result = await Permission.camera.request();
        if (!result.isGranted) {
          print('❌ Permisos de cámara denegados');
          return false;
        }
      }
      
      // Inicializar el controlador de la cámara
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
      
      print('✅ Cámara inicializada correctamente');
      return true;
    } catch (e) {
      print('❌ Error inicializando cámara: $e');
      return false;
    }
  }
  
  /// Verifica si el escáner está disponible
  static bool get isAvailable => _isInitialized && _controller != null;
  
  /// Escanea un código QR usando la cámara real
  static Future<String?> scanQrCode({
    required BuildContext context,
    int timeout = 30,
  }) async {
    // Inicializar la cámara si no está disponible
    if (!isAvailable) {
      final cameraInitialized = await _initializeCamera();
      if (!cameraInitialized) {
        throw Exception('No se pudo inicializar la cámara');
      }
    }
    
    _isScanning = true;
    
    try {
      final result = await Navigator.of(context).push<String?>(
        MaterialPageRoute(
          builder: (context) => _QrScannerScreen(
            controller: _controller!,
            timeout: timeout,
          ),
        ),
      );
      
      return result;
    } finally {
      _isScanning = false;
    }
  }
  
  /// Libera recursos
  static Future<void> dispose() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }
    _isInitialized = false;
    _isScanning = false;
  }
}

/// Pantalla de escáner QR
class _QrScannerScreen extends StatefulWidget {
  final MobileScannerController controller;
  final int timeout;
  
  const _QrScannerScreen({
    required this.controller,
    required this.timeout,
  });
  
  @override
  State<_QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<_QrScannerScreen> {
  bool _isScanning = true;
  String? _lastScannedCode;
  Timer? _timeoutTimer;
  
  @override
  void initState() {
    super.initState();
    _startTimeout();
    // Iniciar escaneo automáticamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScanning();
    });
  }
  
  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }
  
  void _startTimeout() {
    _timeoutTimer = Timer(Duration(seconds: widget.timeout), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }
  
  void _startScanning() {
    setState(() {
      _isScanning = true;
    });
  }
  
  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null && _isValidQrCode(code)) {
        setState(() {
          _isScanning = false;
          _lastScannedCode = code;
        });
        
        // Vibrar o hacer sonido de confirmación
        // HapticFeedback.lightImpact();
        
        // Cerrar después de un breve delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop(code);
          }
        });
      }
    }
  }
  
  bool _isValidQrCode(String code) {
    final trimmed = code.trim();
    
    // Patrón de descuento: -X o -X.XX donde X son números
    final discountPattern = RegExp(r'^-\d+(?:\.\d+)?$');
    if (discountPattern.hasMatch(trimmed)) {
      final amount = double.tryParse(trimmed);
      if (amount != null && amount < 0 && amount >= -10000) {
        return true;
      }
    }
    
    // Códigos VIP/FREE
    final normalized = trimmed.toUpperCase();
    if (normalized == 'FREE' || normalized == 'VIP' || normalized == 'VIP-ALL' || 
        normalized == '-ALL' || normalized == '-100%') {
      return true;
    }
    
    // Formato alternativo que empiece con -
    if (trimmed.startsWith('-')) {
      final numberPart = trimmed.substring(1);
      final number = double.tryParse(numberPart);
      if (number != null && number >= 0) {
        return true;
      }
    }
    
    return false;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(AppLocalizations.of(context).t('scanQrTitle')),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_front),
            onPressed: () => widget.controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Cámara
          MobileScanner(
            controller: widget.controller,
            onDetect: _onDetect,
          ),
          
          // Overlay con guías
          _buildScannerOverlay(),
          
          // Indicador de estado
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isScanning 
                  ? '🔍 ${AppLocalizations.of(context).t('scanning')}'
                  : '⏹️ ${AppLocalizations.of(context).t('scanPaused')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Botón de cancelar
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppLocalizations.of(context).t('cancelScan'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScannerOverlay() {
    return Container(
      decoration: ShapeDecoration(
        shape: QrScannerOverlayShape(
          borderColor: Colors.white,
          borderRadius: 20,
          borderLength: 40,
          borderWidth: 4,
          cutOutSize: 280,
          overlayColor: const Color.fromRGBO(0, 0, 0, 120),
        ),
      ),
    );
  }
}

/// Forma del overlay del escáner
class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    double? cutOutSize,
    double? cutOutWidth,
    double? cutOutHeight,
  })  : cutOutWidth = cutOutWidth ?? cutOutSize ?? 250,
        cutOutHeight = cutOutHeight ?? cutOutSize ?? 250;

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutWidth;
  final double cutOutHeight;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + borderRadius, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final cutOutWidth = this.cutOutWidth < width ? this.cutOutWidth : width - borderOffset;
    final cutOutHeight = this.cutOutHeight < height ? this.cutOutHeight : height - borderOffset;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - cutOutWidth / 2 + borderOffset,
      rect.top + height / 2 - cutOutHeight / 2 + borderOffset,
      cutOutWidth - borderOffset * 2,
      cutOutHeight - borderOffset * 2,
    );

    canvas
      ..saveLayer(
        rect,
        backgroundPaint,
      )
      ..drawRect(rect, backgroundPaint)
      ..drawRRect(
        RRect.fromRectAndRadius(
          cutOutRect,
          Radius.circular(borderRadius),
        ),
        Paint()..blendMode = BlendMode.clear,
      )
      ..restore();

    // Draw elegant corners with glow effect
    final glowPaint = Paint()
      ..color = borderColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth * 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Draw glow effect
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left - borderOffset, cutOutRect.top + borderLength)
        ..lineTo(cutOutRect.left - borderOffset, cutOutRect.top + borderRadius)
        ..quadraticBezierTo(cutOutRect.left - borderOffset, cutOutRect.top - borderOffset,
            cutOutRect.left + borderRadius, cutOutRect.top - borderOffset)
        ..lineTo(cutOutRect.left + borderLength, cutOutRect.top - borderOffset)
        ..moveTo(cutOutRect.right + borderOffset, cutOutRect.top + borderLength)
        ..lineTo(cutOutRect.right + borderOffset, cutOutRect.top + borderRadius)
        ..quadraticBezierTo(cutOutRect.right + borderOffset, cutOutRect.top - borderOffset,
            cutOutRect.right - borderRadius, cutOutRect.top - borderOffset)
        ..lineTo(cutOutRect.right - borderLength, cutOutRect.top - borderOffset)
        ..moveTo(cutOutRect.left - borderOffset, cutOutRect.bottom - borderLength)
        ..lineTo(cutOutRect.left - borderOffset, cutOutRect.bottom - borderRadius)
        ..quadraticBezierTo(cutOutRect.left - borderOffset, cutOutRect.bottom + borderOffset,
            cutOutRect.left + borderRadius, cutOutRect.bottom + borderOffset)
        ..lineTo(cutOutRect.left + borderLength, cutOutRect.bottom + borderOffset)
        ..moveTo(cutOutRect.right + borderOffset, cutOutRect.bottom - borderLength)
        ..lineTo(cutOutRect.right + borderOffset, cutOutRect.bottom - borderRadius)
        ..quadraticBezierTo(cutOutRect.right + borderOffset, cutOutRect.bottom + borderOffset,
            cutOutRect.right - borderRadius, cutOutRect.bottom + borderOffset)
        ..lineTo(cutOutRect.right - borderLength, cutOutRect.bottom + borderOffset),
      glowPaint,
    );

    // Draw main border
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left - borderOffset, cutOutRect.top + borderLength)
        ..lineTo(cutOutRect.left - borderOffset, cutOutRect.top + borderRadius)
        ..quadraticBezierTo(cutOutRect.left - borderOffset, cutOutRect.top - borderOffset,
            cutOutRect.left + borderRadius, cutOutRect.top - borderOffset)
        ..lineTo(cutOutRect.left + borderLength, cutOutRect.top - borderOffset)
        ..moveTo(cutOutRect.right + borderOffset, cutOutRect.top + borderLength)
        ..lineTo(cutOutRect.right + borderOffset, cutOutRect.top + borderRadius)
        ..quadraticBezierTo(cutOutRect.right + borderOffset, cutOutRect.top - borderOffset,
            cutOutRect.right - borderRadius, cutOutRect.top - borderOffset)
        ..lineTo(cutOutRect.right - borderLength, cutOutRect.top - borderOffset)
        ..moveTo(cutOutRect.left - borderOffset, cutOutRect.bottom - borderLength)
        ..lineTo(cutOutRect.left - borderOffset, cutOutRect.bottom - borderRadius)
        ..quadraticBezierTo(cutOutRect.left - borderOffset, cutOutRect.bottom + borderOffset,
            cutOutRect.left + borderRadius, cutOutRect.bottom + borderOffset)
        ..lineTo(cutOutRect.left + borderLength, cutOutRect.bottom + borderOffset)
        ..moveTo(cutOutRect.right + borderOffset, cutOutRect.bottom - borderLength)
        ..lineTo(cutOutRect.right + borderOffset, cutOutRect.bottom - borderRadius)
        ..quadraticBezierTo(cutOutRect.right + borderOffset, cutOutRect.bottom + borderOffset,
            cutOutRect.right - borderRadius, cutOutRect.bottom + borderOffset)
        ..lineTo(cutOutRect.right - borderLength, cutOutRect.bottom + borderOffset),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
