import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

/// A widget that displays an animated progress bar with a walking person PNG
/// following a curved road path with bobbing and rotation effects.
class WalkingPersonRoadProgressBar extends StatefulWidget {
  /// Duration of the animation (default: 10 seconds)
  final Duration duration;

  /// Path to the walking person PNG image
  final String imagePath;

  /// Callback when animation completes
  final VoidCallback? onComplete;

  const WalkingPersonRoadProgressBar({
    super.key,
    this.duration = const Duration(seconds: 10),
    this.imagePath = 'assets/images/walking_person.png',
    this.onComplete,
  });

  @override
  State<WalkingPersonRoadProgressBar> createState() =>
      _WalkingPersonRoadProgressBarState();
}

class _WalkingPersonRoadProgressBarState
    extends State<WalkingPersonRoadProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  ui.Image? _personImage;

  @override
  void initState() {
    super.initState();
    _loadImage();
    _initializeAnimation();
    _startAnimation();
  }

  Future<void> _loadImage() async {
    try {
      final data = await DefaultAssetBundle.of(context).load(widget.imagePath);
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _personImage = frame.image;
        });
      }
    } catch (e) {
      // Image loading failed, will use fallback drawing
      debugPrint('Failed to load walking person image: $e');
    }
  }

  void _initializeAnimation() {
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  void _startAnimation() {
    _controller.forward(from: 0);
  }

  void _restartAnimation() {
    setState(() {
      _controller.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _personImage?.dispose();
    super.dispose();
  }

  String _getRemainingTime(double progress) {
    final remaining = widget.duration.inSeconds * (1 - progress);
    return 'Temps restant : ${remaining.ceil()}s';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _restartAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Countdown timer
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Text(
                  _getRemainingTime(_progressAnimation.value),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A5276),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Curved road with animated walking person
            SizedBox(
              height: 180,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: WalkingPersonRoadPainter(
                      progress: _progressAnimation.value,
                      personImage: _personImage,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Hint text
            Text(
              'Appuyez pour redémarrer',
              style: TextStyle(
                fontSize: 11,
                color: const Color(0xFF1A5276).withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter that draws the curved road with walking person image
class WalkingPersonRoadPainter extends CustomPainter {
  final double progress;
  final ui.Image? personImage;

  WalkingPersonRoadPainter({required this.progress, this.personImage});

  @override
  void paint(Canvas canvas, Size size) {
    // Define the curved path (S-shaped bezier curve)
    final path = Path();
    final startPoint = Offset(20, size.height * 0.8);
    final endPoint = Offset(size.width - 20, size.height * 0.2);

    // Control points for S-curve
    final controlPoint1 = Offset(size.width * 0.3, size.height * 0.2);
    final controlPoint2 = Offset(size.width * 0.7, size.height * 0.8);

    path.moveTo(startPoint.dx, startPoint.dy);
    path.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      endPoint.dx,
      endPoint.dy,
    );

    // Draw road background (dark asphalt)
    final roadPaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 40
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, roadPaint);

    // Draw dashed center line
    _drawDashedPath(canvas, path);

    // Draw location pins
    _drawLocationPins(canvas, path);

    // Draw house at start
    _drawHouseIcon(canvas, startPoint);

    // Draw pharmacy at end
    _drawPharmacyIcon(canvas, endPoint);

    // Draw walking person with PNG image
    final travelerPosition = _getPointOnPath(path, progress);
    final tangent = _getTangentAtProgress(path, progress);
    _drawWalkingPerson(canvas, travelerPosition, tangent);
  }

  /// Draws dashed center line
  void _drawDashedPath(Canvas canvas, Path path) {
    final dashPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final extractPath = pathMetric.extractPath(
          distance,
          distance + 10 < pathMetric.length ? distance + 10 : pathMetric.length,
        );
        canvas.drawPath(extractPath, dashPaint);
        distance += 20;
      }
    }
  }

  /// Draws location pins
  void _drawLocationPins(Canvas canvas, Path path) {
    final pinColors = [
      const Color(0xFF6DD5ED),
      const Color(0xFFFFC107),
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFF9B59B6),
    ];

    final pinPositions = [0.2, 0.35, 0.5, 0.65, 0.8];

    for (int i = 0; i < pinPositions.length; i++) {
      final position = _getPointOnPath(path, pinPositions[i]);
      _drawPin(canvas, position, pinColors[i]);
    }
  }

  /// Draws a single pin
  void _drawPin(Canvas canvas, Offset position, Color color) {
    final pinPaint = Paint()..color = color;
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(position + const Offset(0, 2), 8, shadowPaint);
    canvas.drawCircle(position, 8, pinPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(position, 8, borderPaint);

    final pointerPath = Path();
    pointerPath.moveTo(position.dx, position.dy);
    pointerPath.lineTo(position.dx - 4, position.dy - 10);
    pointerPath.quadraticBezierTo(
      position.dx,
      position.dy - 14,
      position.dx + 4,
      position.dy - 10,
    );
    pointerPath.close();
    canvas.drawPath(pointerPath, pinPaint);
  }

  /// Draws house icon
  void _drawHouseIcon(Canvas canvas, Offset position) {
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawCircle(position, 18, bgPaint);

    final iconPaint = Paint()..color = const Color(0xFF4CAF50);
    final housePath = Path();
    housePath.moveTo(position.dx, position.dy - 8);
    housePath.lineTo(position.dx - 8, position.dy);
    housePath.lineTo(position.dx - 6, position.dy);
    housePath.lineTo(position.dx - 6, position.dy + 6);
    housePath.lineTo(position.dx + 6, position.dy + 6);
    housePath.lineTo(position.dx + 6, position.dy);
    housePath.lineTo(position.dx + 8, position.dy);
    housePath.close();
    canvas.drawPath(housePath, iconPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(position, 18, borderPaint);
  }

  /// Draws pharmacy icon
  void _drawPharmacyIcon(Canvas canvas, Offset position) {
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawCircle(position, 18, bgPaint);

    final iconPaint = Paint()..color = const Color(0xFFF44336);
    canvas.drawRect(
      Rect.fromCenter(center: position, width: 4, height: 14),
      iconPaint,
    );
    canvas.drawRect(
      Rect.fromCenter(center: position, width: 14, height: 4),
      iconPaint,
    );

    final borderPaint = Paint()
      ..color = const Color(0xFFF44336)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(position, 18, borderPaint);
  }

  /// Draws walking person with PNG image, bobbing, and rotation
  void _drawWalkingPerson(Canvas canvas, Offset position, double angle) {
    // Bobbing effect (up and down)
    final bobbingOffset = math.sin(progress * 30) * 4;

    // Rotation effect (slight tilt)
    final tiltAngle = math.sin(progress * 25) * 0.12;

    // Ajuster la position pour que les pieds touchent la route
    // On décale le personnage vers le haut de la moitié de sa taille
    final imageSize = 50.0;
    final verticalOffset = -imageSize / 2; // Décalage vers le haut

    final adjustedPosition = Offset(
      position.dx,
      position.dy + bobbingOffset + verticalOffset,
    );

    canvas.save();

    // Move to person position
    canvas.translate(adjustedPosition.dx, adjustedPosition.dy);

    // Apply walking direction rotation
    canvas.rotate(angle);

    // Apply bobbing tilt
    canvas.rotate(tiltAngle);

    if (personImage != null) {
      // Draw PNG image
      final srcRect = Rect.fromLTWH(
        0,
        0,
        personImage!.width.toDouble(),
        personImage!.height.toDouble(),
      );
      final dstRect = Rect.fromCenter(
        center: Offset.zero,
        width: imageSize,
        height: imageSize,
      );

      // Draw shadow at road level (below the person)
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(
        Offset(0, imageSize / 2 + 5), // Shadow at feet level
        imageSize / 2,
        shadowPaint,
      );

      // Draw image
      canvas.drawImageRect(personImage!, srcRect, dstRect, Paint());
    } else {
      // Fallback: draw simple stick figure
      _drawFallbackPerson(canvas);
    }

    canvas.restore();
  }

  /// Draws fallback stick figure if PNG not loaded
  void _drawFallbackPerson(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFF1A5276)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Head
    canvas.drawCircle(
      const Offset(0, -8),
      4,
      paint..style = PaintingStyle.fill,
    );

    paint.style = PaintingStyle.stroke;

    // Body
    canvas.drawLine(const Offset(0, -4), const Offset(0, 6), paint);

    // Legs
    final legAngle = math.sin(progress * 20) * 0.5;
    canvas.drawLine(
      const Offset(0, 6),
      Offset(-4 * math.cos(legAngle), 12),
      paint,
    );
    canvas.drawLine(
      const Offset(0, 6),
      Offset(4 * math.cos(legAngle), 12),
      paint,
    );
  }

  /// Gets point on path at progress
  Offset _getPointOnPath(Path path, double progress) {
    final pathMetrics = path.computeMetrics();
    final pathMetric = pathMetrics.first;
    final value = pathMetric.length * progress;
    final tangent = pathMetric.getTangentForOffset(value);
    return tangent?.position ?? Offset.zero;
  }

  /// Gets tangent angle at progress for rotation
  double _getTangentAtProgress(Path path, double progress) {
    final pathMetrics = path.computeMetrics();
    final pathMetric = pathMetrics.first;
    final value = pathMetric.length * progress;
    final tangent = pathMetric.getTangentForOffset(value);
    if (tangent == null) return 0;

    final angle = math.atan2(tangent.vector.dy, tangent.vector.dx);
    return angle;
  }

  @override
  bool shouldRepaint(WalkingPersonRoadPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.personImage != personImage;
  }
}
