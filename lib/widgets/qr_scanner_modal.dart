import 'dart:async';
import 'package:flutter/material.dart';

/// Modal de escáner QR mejorado con entrada manual
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
  Timer? _timeoutTimer;
  final TextEditingController _manualInputController = TextEditingController();
  final FocusNode _manualInputFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _startTimeout();
    // Auto-focus en el campo de texto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _manualInputFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _manualInputController.dispose();
    _manualInputFocus.dispose();
    super.dispose();
  }

  /// Parsea el código QR y extrae el descuento
  double? _parseQrCode(String qrData) {
    final cleanData = qrData.trim().toUpperCase();
    
    // Casos especiales para FREE
    if (cleanData == 'FREE' || cleanData == '0.00' || cleanData == '-0.00') {
      return 0.0;
    }
    
    // Intentar parsear como número
    try {
      final value = double.parse(cleanData);
      return value;
    } catch (e) {
      return null;
    }
  }

  /// Maneja cuando se escanea un QR válido
  void _handleQrScanned(double? discount) {
    _timeoutTimer?.cancel();
    widget.onQrScanned(discount);
  }

  /// Inicia el timeout
  void _startTimeout() {
    _timeoutTimer = Timer(Duration(seconds: widget.timeoutSeconds), () {
      _handleQrScanned(null);
    });
  }

  /// Muestra un error
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Procesa entrada manual
  void _processManualInput() {
    final input = _manualInputController.text.trim();
    if (input.isEmpty) return;

    final discount = _parseQrCode(input);
    if (discount != null) {
      _handleQrScanned(discount);
    } else {
      _showError('Código no válido. Use números como -0.5, -1, FREE, etc.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
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
                  const Icon(Icons.qr_code_scanner, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Escanear Código QR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _handleQrScanned(null),
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Cancelar',
                  ),
                ],
              ),
            ),
            
            // Contenido principal
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.black,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icono de QR
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    const Text(
                      'Ingrese el código de descuento',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    const Text(
                      'Use los códigos QR impresos o ingrese manualmente',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Campo de entrada
                    TextField(
                      controller: _manualInputController,
                      focusNode: _manualInputFocus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Ej: -0.5, -1, FREE',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white54),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white54),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      onSubmitted: (_) => _processManualInput(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Botón aplicar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _processManualInput,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Aplicar Descuento',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Códigos válidos
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Text(
                        'Códigos válidos: -0.5, -0.25, -1, -1.5, -2, -3, FREE',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
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
}