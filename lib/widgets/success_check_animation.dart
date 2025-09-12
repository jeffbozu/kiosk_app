import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget personalizado para mostrar una animación elegante de check de éxito
/// Efecto moderno con shimmer, glow y animaciones suaves como en apps de pago
class SuccessCheckAnimation extends StatefulWidget {
  final double size;
  final Color? color;
  final Duration animationDuration;
  final VoidCallback? onAnimationComplete;

  const SuccessCheckAnimation({
    super.key,
    this.size = 120.0,
    this.color,
    this.animationDuration = const Duration(milliseconds: 2500),
    this.onAnimationComplete,
  });

  @override
  State<SuccessCheckAnimation> createState() => _SuccessCheckAnimationState();
}

class _SuccessCheckAnimationState extends State<SuccessCheckAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _checkController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _glowController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Controlador para la animación de escala del círculo
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Controlador para la animación del check
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Controlador para la animación de pulso
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Controlador para el efecto shimmer
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Controlador para el efecto glow
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Animación de escala con efecto de rebote suave
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Animación del check con efecto de dibujo
    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOut,
    ));

    // Animación de pulso para el efecto de ondas
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    ));

    // Animación shimmer
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    // Animación glow
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeOut,
    ));

    // Iniciar las animaciones en secuencia
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Iniciar escala del círculo
    _scaleController.forward();
    
    // Esperar un poco y luego iniciar el check
    await Future.delayed(const Duration(milliseconds: 200));
    _checkController.forward();
    
    // Iniciar el pulso después del check
    await Future.delayed(const Duration(milliseconds: 300));
    _pulseController.forward();
    
    // Iniciar shimmer
    await Future.delayed(const Duration(milliseconds: 100));
    _shimmerController.repeat();
    
    // Iniciar glow
    await Future.delayed(const Duration(milliseconds: 200));
    _glowController.forward();
    
    // Llamar callback cuando termine la animación
    await Future.delayed(widget.animationDuration);
    widget.onAnimationComplete?.call();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _checkController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? const Color(0xFF4CAF50); // Verde moderno
    
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Efecto de ondas de pulso múltiples
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: PulsePainter(
                  progress: _pulseAnimation.value,
                  color: color.withOpacity(0.2),
                ),
              );
            },
          ),
          
          // Efecto glow brillante
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_glowAnimation.value * 0.3),
                child: Container(
                  width: widget.size * 0.9,
                  height: widget.size * 0.9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withOpacity(0.1),
                        color.withOpacity(0.05),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Círculo principal con animación de escala
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: widget.size * 0.8,
                  height: widget.size * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        color.withOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 50,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Efecto shimmer
          AnimatedBuilder(
            animation: _shimmerAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: widget.size * 0.8,
                  height: widget.size * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment(-1.0 + _shimmerAnimation.value, -1.0),
                      end: Alignment(1.0 + _shimmerAnimation.value, 1.0),
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Check mark con animación de dibujo
          AnimatedBuilder(
            animation: _checkAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size * 0.4, widget.size * 0.4),
                painter: CheckPainter(
                  progress: _checkAnimation.value,
                  color: Colors.white,
                  strokeWidth: widget.size * 0.08,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Painter personalizado para el efecto de ondas de pulso modernas
class PulsePainter extends CustomPainter {
  final double progress;
  final Color color;

  PulsePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Dibujar múltiples ondas con gradientes y opacidades variables
    for (int i = 0; i < 4; i++) {
      final waveProgress = (progress - i * 0.25).clamp(0.0, 1.0);
      if (waveProgress > 0) {
        final radius = maxRadius * waveProgress;
        final opacity = (1.0 - waveProgress) * 0.4;
        
        // Crear gradiente radial para cada onda
        final gradient = RadialGradient(
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(opacity * 0.5),
            Colors.transparent,
          ],
          stops: const [0.0, 0.7, 1.0],
        );
        
        final rect = Rect.fromCircle(center: center, radius: radius);
        final paint = Paint()
          ..shader = gradient.createShader(rect)
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(center, radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(PulsePainter oldDelegate) {
    return progress != oldDelegate.progress || color != oldDelegate.color;
  }
}

/// Painter personalizado para dibujar el check mark elegante
class CheckPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  CheckPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Crear gradiente para el check mark
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color,
        color.withOpacity(0.8),
      ],
    );
    
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    
    // Definir los puntos del check mark con curvas suaves
    final startPoint = Offset(size.width * 0.2, size.height * 0.5);
    final middlePoint = Offset(size.width * 0.45, size.height * 0.7);
    final endPoint = Offset(size.width * 0.8, size.height * 0.3);

    // Crear el path del check con curvas
    path.moveTo(startPoint.dx, startPoint.dy);
    path.quadraticBezierTo(
      middlePoint.dx - 5, middlePoint.dy - 5,
      middlePoint.dx, middlePoint.dy,
    );
    path.quadraticBezierTo(
      endPoint.dx - 5, endPoint.dy + 5,
      endPoint.dx, endPoint.dy,
    );

    // Crear un path que se dibuje progresivamente
    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      final extractPath = pathMetric.extractPath(
        0.0,
        pathMetric.length * progress,
      );
      canvas.drawPath(extractPath, paint);
    }
  }

  @override
  bool shouldRepaint(CheckPainter oldDelegate) {
    return progress != oldDelegate.progress || 
           color != oldDelegate.color || 
           strokeWidth != oldDelegate.strokeWidth;
  }
}
