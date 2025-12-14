import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A self-contained animated curved road progress bar widget representing a journey
/// from house to pharmacy with a walking person icon following a wavy path.
class JourneyProgressBar extends StatefulWidget {
  /// Duration of the animation (default: 10 seconds)
  final Duration duration;

  /// Callback when animation completes
  final VoidCallback? onComplete;

  const JourneyProgressBar({
    super.key,
    this.duration = const Duration(seconds: 10),
    this.onComplete,
  });

  @override
  State<JourneyProgressBar> createState() => _JourneyProgressBarState();
}

class _JourneyProgressBarState extends State<JourneyProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _startAnimation();
  }

  void _initializeAnimation() {
    _controller = AnimationController(vsync: this, duration: widget.duration);

    // Smooth progress animation with easeInOut curve
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
            // Countdown timer display
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

            // Curved Road with animated traveler
            SizedBox(
              height: 180,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: CurvedRoadPainter(
                      progress: _progressAnimation.value,
                    ),
                    size: Size.infinite,
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
                color: const Color(0xFF1A5276).withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter that draws a curved road with location pins and animated traveler
class CurvedRoadPainter extends CustomPainter {
  final double progress;

  CurvedRoadPainter({required this.progress});

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
    _drawDashedPath(canvas, path, const Color(0xFFFFFFFF), 2);

    // Draw location pins along the path
    _drawLocationPins(canvas, path, size);

    // Draw house icon at start
    _drawHouseIcon(canvas, startPoint);

    // Draw pharmacy icon at end
    _drawPharmacyIcon(canvas, endPoint);

    // Draw animated traveler (walking person)
    final travelerPosition = _getPointOnPath(path, progress);
    _drawTraveler(canvas, travelerPosition);
  }

  /// Draws dashed line along the path
  void _drawDashedPath(Canvas canvas, Path path, Color color, double width) {
    final dashPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final nextDistance = distance + 10;
        final extractPath = pathMetric.extractPath(
          distance,
          nextDistance > pathMetric.length ? pathMetric.length : nextDistance,
        );
        canvas.drawPath(extractPath, dashPaint);
        distance = nextDistance + 10;
      }
    }
  }

  /// Draws colored location pins along the path
  void _drawLocationPins(Canvas canvas, Path path, Size size) {
    final pinColors = [
      const Color(0xFF6DD5ED), // Cyan
      const Color(0xFFFFC107), // Yellow
      const Color(0xFFFF6B6B), // Red
      const Color(0xFF4ECDC4), // Turquoise
      const Color(0xFF9B59B6), // Purple
    ];

    final pinPositions = [0.2, 0.35, 0.5, 0.65, 0.8];

    for (int i = 0; i < pinPositions.length; i++) {
      final position = _getPointOnPath(path, pinPositions[i]);
      _drawPin(canvas, position, pinColors[i % pinColors.length]);
    }
  }

  /// Draws a single location pin
  void _drawPin(Canvas canvas, Offset position, Color color) {
    final pinPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Pin shadow
    canvas.drawCircle(position + const Offset(0, 2), 8, shadowPaint);

    // Pin circle
    canvas.drawCircle(position, 8, pinPaint);

    // Pin border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(position, 8, borderPaint);

    // Pin pointer (teardrop shape)
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
    final iconPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.fill;

    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Background circle
    canvas.drawCircle(position, 18, bgPaint);

    // House shape
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

    // Border
    final borderPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(position, 18, borderPaint);
  }

  /// Draws pharmacy icon
  void _drawPharmacyIcon(Canvas canvas, Offset position) {
    final iconPaint = Paint()
      ..color = const Color(0xFFF44336)
      ..style = PaintingStyle.fill;

    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Background circle
    canvas.drawCircle(position, 18, bgPaint);

    // Cross shape
    canvas.drawRect(
      Rect.fromCenter(center: position, width: 4, height: 14),
      iconPaint,
    );
    canvas.drawRect(
      Rect.fromCenter(center: position, width: 14, height: 4),
      iconPaint,
    );

    // Border
    final borderPaint = Paint()
      ..color = const Color(0xFFF44336)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(position, 18, borderPaint);
  }

  /// Draws walking person (traveler) - now using PNG image with bobbing and rotation
  void _drawTraveler(Canvas canvas, Offset position) {
    // Note: In the actual implementation, you should load and draw the PNG image here
    // For now, we keep the stick figure as fallback until the PNG is added

    // Calculate bobbing effect (vertical oscillation)
    final bobbingOffset = math.sin(progress * 30) * 3;

    // Calculate rotation angle based on progress (slight tilt while walking)
    final rotationAngle =
        math.sin(progress * 25) * 0.1; // ±0.1 radians (~6 degrees)

    // Adjust position with bobbing
    final adjustedPosition = Offset(position.dx, position.dy + bobbingOffset);

    canvas.save();

    // Apply rotation at the character's center
    canvas.translate(adjustedPosition.dx, adjustedPosition.dy);
    canvas.rotate(rotationAngle);
    canvas.translate(-adjustedPosition.dx, -adjustedPosition.dy);

    final travelerPaint = Paint()
      ..color = const Color(0xFF1A5276)
      ..style = PaintingStyle.fill;

    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Shadow (adjusted for bobbing)
    canvas.drawCircle(adjustedPosition + const Offset(0, 3), 14, shadowPaint);

    // Background
    canvas.drawCircle(adjustedPosition, 14, bgPaint);

    // Note: Pour utiliser une image PNG, ajoutez l'image dans assets/images/
    // et utilisez la méthode paintImage() pour la dessiner
    // Exemple:
    // final image = await rootBundle.load('assets/images/walking_person.png');
    // final codec = await instantiateImageCodec(image.buffer.asUint8List());
    // final frame = await codec.getNextFrame();
    // paintImage(canvas: canvas, rect: Rect.fromCenter(...), image: frame.image);

    // Fallback: Simple walking person (stick figure with animated legs)
    // Head
    canvas.drawCircle(adjustedPosition + const Offset(0, -4), 3, travelerPaint);

    // Body
    canvas.drawLine(
      adjustedPosition + const Offset(0, -1),
      adjustedPosition + const Offset(0, 6),
      Paint()
        ..color = const Color(0xFF1A5276)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Legs (animated walking with alternating movement)
    final legAngle = math.sin(progress * 20) * 0.4;
    canvas.drawLine(
      adjustedPosition + const Offset(0, 6),
      adjustedPosition + Offset(-3 * math.cos(legAngle), 10),
      Paint()
        ..color = const Color(0xFF1A5276)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      adjustedPosition + const Offset(0, 6),
      adjustedPosition + Offset(3 * math.cos(legAngle), 10),
      Paint()
        ..color = const Color(0xFF1A5276)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Border
    final borderPaint = Paint()
      ..color = const Color(0xFF1A5276)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(adjustedPosition, 14, borderPaint);

    canvas.restore();
  }

  /// Gets point on bezier path at specific progress (0.0 to 1.0)
  Offset _getPointOnPath(Path path, double progress) {
    final pathMetrics = path.computeMetrics();
    final pathMetric = pathMetrics.first;
    final value = pathMetric.length * progress;
    final tangent = pathMetric.getTangentForOffset(value);
    return tangent?.position ?? Offset.zero;
  }

  @override
  bool shouldRepaint(CurvedRoadPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
