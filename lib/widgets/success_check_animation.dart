import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget personalizado para mostrar una animación elegante de check de éxito
/// Un solo check que aparece con efecto y se mantiene visible
class SuccessCheckAnimation extends StatefulWidget {
  final double size;
  final Color? color;
  final Duration animationDuration;
  final VoidCallback? onAnimationComplete;

  const SuccessCheckAnimation({
    super.key,
    this.size = 120.0,
    this.color,
    this.animationDuration = const Duration(milliseconds: 3000),
    this.onAnimationComplete,
  });

  @override
  State<SuccessCheckAnimation> createState() => _SuccessCheckAnimationState();
}

class _SuccessCheckAnimationState extends State<SuccessCheckAnimation>
    with TickerProviderStateMixin {
  late AnimationController _tvController;
  late AnimationController _checkController;
  late AnimationController _glowController;
  late AnimationController _finalController;
  
  late Animation<double> _tvAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _finalAnimation;

  @override
  void initState() {
    super.initState();
    
    // Controlador para el efecto TV (encendido)
    _tvController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Controlador para la animación del check
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Controlador para el efecto glow final
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Controlador para el estado final (check permanente)
    _finalController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Animación del efecto TV (como encender una pantalla)
    _tvAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _tvController,
      curve: Curves.easeOutQuart,
    ));

    // Animación del check (aparece después del efecto TV)
    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    ));

    // Animación glow (resplandor final)
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeOut,
    ));

    // Animación final (check permanente con movimiento suave)
    _finalAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _finalController,
      curve: Curves.easeOutBack,
    ));

    // Iniciar la secuencia de animación
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // 1. Efecto TV (encendido)
    _tvController.forward();
    
    // 2. Esperar un poco y mostrar el check
    await Future.delayed(const Duration(milliseconds: 800));
    _checkController.forward();
    
    // 3. Efecto glow final
    await Future.delayed(const Duration(milliseconds: 500));
    _glowController.forward();
    
    // 4. Transición al estado final
    await Future.delayed(const Duration(milliseconds: 500));
    _finalController.forward();
    
    // 5. Llamar callback cuando termine
    await Future.delayed(const Duration(milliseconds: 300));
    widget.onAnimationComplete?.call();
  }

  @override
  void dispose() {
    _tvController.dispose();
    _checkController.dispose();
    _glowController.dispose();
    _finalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? const Color(0xFF4CAF50);
    
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Efecto glow de fondo
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                width: widget.size * 1.4,
                height: widget.size * 1.4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color.withOpacity(0.4 * _glowAnimation.value),
                      color.withOpacity(0.2 * _glowAnimation.value),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              );
            },
          ),
          
          // Círculo principal con efecto TV
          AnimatedBuilder(
            animation: _tvAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _tvAnimation.value,
                child: Container(
                  width: widget.size * 0.9,
                  height: widget.size * 0.9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        color.withOpacity(0.9),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5 * _tvAnimation.value),
                        blurRadius: 40 * _tvAnimation.value,
                        spreadRadius: 15 * _tvAnimation.value,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // UN SOLO CHECK MARK que se mantiene visible
          AnimatedBuilder(
            animation: Listenable.merge([_checkAnimation, _finalAnimation]),
            builder: (context, child) {
              // Si la animación del check ha terminado, mostrar el check final
              if (_checkController.isCompleted) {
                return Transform.scale(
                  scale: 1.0 + (_finalAnimation.value * 0.1), // Movimiento suave
                  child: Transform.translate(
                    offset: Offset(0, -2 * _finalAnimation.value), // Movimiento hacia arriba
                    child: CustomPaint(
                      size: Size(widget.size * 0.5, widget.size * 0.5),
                      painter: CheckPainter(
                        progress: 1.0,
                        color: Colors.white,
                        strokeWidth: widget.size * 0.08,
                      ),
                    ),
                  ),
                );
              }
              
              // Durante la animación inicial
              if (_checkAnimation.value <= 0) return const SizedBox.shrink();
              
              return Transform.scale(
                scale: _checkAnimation.value,
                child: CustomPaint(
                  size: Size(widget.size * 0.5, widget.size * 0.5),
                  painter: CheckPainter(
                    progress: 1.0,
                    color: Colors.white,
                    strokeWidth: widget.size * 0.08,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Painter personalizado para dibujar el check mark elegante y moderno
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
    // Crear gradiente para el check mark más brillante
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white,
        color.withOpacity(0.9),
      ],
    );
    
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.5 // Más grueso para mayor visibilidad
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Añadir sombra al check
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    
    // Definir los puntos del check mark más grande y claro
    final startPoint = Offset(size.width * 0.15, size.height * 0.55);
    final middlePoint = Offset(size.width * 0.45, size.height * 0.75);
    final endPoint = Offset(size.width * 0.85, size.height * 0.25);

    // Crear el path del check con curvas más pronunciadas
    path.moveTo(startPoint.dx, startPoint.dy);
    path.quadraticBezierTo(
      middlePoint.dx - 8, middlePoint.dy - 8,
      middlePoint.dx, middlePoint.dy,
    );
    path.quadraticBezierTo(
      endPoint.dx - 8, endPoint.dy + 8,
      endPoint.dx, endPoint.dy,
    );

    // Dibujar sombra primero
    canvas.save();
    canvas.translate(2, 2);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Dibujar el check principal
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CheckPainter oldDelegate) {
    return progress != oldDelegate.progress || 
           color != oldDelegate.color || 
           strokeWidth != oldDelegate.strokeWidth;
  }
}