import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../models/models.dart';

class TopologyCanvasPainter extends CustomPainter {
  final Q11Device masterNode;
  final List<Q11Device> satellites;
  final double animationProgress; // 0.0 to 1.0
  final String? localConnectedNodeIp;
  final Set<String> flashingNodeIps;

  TopologyCanvasPainter({
    required this.masterNode,
    required this.satellites,
    required this.animationProgress,
    this.localConnectedNodeIp,
    this.flashingNodeIps = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw subtle grid background
    _drawGrid(canvas, size);

    if (satellites.isEmpty) {
      // Single Master Node centered
      final center = Offset(w / 2, h / 2);
      _drawNode(canvas, center, masterNode, isMaster: true);
      return;
    }

    final masterPos = Offset(w * 0.25, h * 0.5);

    final satPositions = <Offset>[];
    if (satellites.length == 1) {
      satPositions.add(Offset(w * 0.75, h * 0.5));
    } else {
      // 2 or more satellites
      final stepY = h / (satellites.length + 1);
      for (int i = 0; i < satellites.length; i++) {
        satPositions.add(Offset(w * 0.75, stepY * (i + 1)));
      }
    }

    // Draw connecting mesh lines with animated packet flow
    for (int i = 0; i < satellites.length; i++) {
      final sat = satellites[i];
      final satPos = satPositions[i];
      _drawMeshLink(canvas, masterPos, satPos, sat.backhaul, sat.isOnline);
    }

    // Draw Master Node
    _drawNode(canvas, masterPos, masterNode, isMaster: true);

    // Draw Satellite Nodes
    for (int i = 0; i < satellites.length; i++) {
      _drawNode(canvas, satPositions[i], satellites[i], isMaster: false);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawMeshLink(
    Canvas canvas,
    Offset start,
    Offset end,
    BackhaulType backhaul,
    bool isOnline,
  ) {
    final linkColor = isOnline ? AppColors.primaryLight : AppColors.border;
    final linePaint = Paint()
      ..color = linkColor.withValues(alpha: 0.6)
      ..strokeWidth = backhaul == BackhaulType.ethernet ? 2.5 : 1.8
      ..style = PaintingStyle.stroke;

    // Curved Bezier path
    final controlPoint1 = Offset(
      start.dx + (end.dx - start.dx) * 0.5,
      start.dy,
    );
    final controlPoint2 = Offset(
      start.dx + (end.dx - start.dx) * 0.5,
      end.dy,
    );

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        end.dx,
        end.dy,
      );

    canvas.drawPath(path, linePaint);

    // Draw flowing data packet if online
    if (isOnline) {
      // Approximate position along the cubic curve using animationProgress
      final t = animationProgress;
      final point = _computeCubicBezierPoint(start, controlPoint1, controlPoint2, end, t);

      final pulsePaint = Paint()
        ..color = AppColors.secondary
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 4.0, pulsePaint);

      final glowPaint = Paint()
        ..color = AppColors.secondary.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 7.0, glowPaint);
    }
  }

  Offset _computeCubicBezierPoint(
    Offset p0,
    Offset p1,
    Offset p2,
    Offset p3,
    double t,
  ) {
    final u = 1 - t;
    final tt = t * t;
    final uu = u * u;
    final uuu = uu * u;
    final ttt = tt * t;

    final x = uuu * p0.dx + 3 * uu * t * p1.dx + 3 * u * tt * p2.dx + ttt * p3.dx;
    final y = uuu * p0.dy + 3 * uu * t * p1.dy + 3 * u * tt * p2.dy + ttt * p3.dy;
    return Offset(x, y);
  }

  void _drawNode(
    Canvas canvas,
    Offset center,
    Q11Device device, {
    required bool isMaster,
  }) {
    final radius = isMaster ? 26.0 : 20.0;
    final statusColor = device.isOnline ? AppColors.success : AppColors.error;
    final isConnectedToYou = localConnectedNodeIp != null && device.ipAddress == localConnectedNodeIp;
    final isFlashing = flashingNodeIps.contains(device.ipAddress);

    // Flashing LED animation
    if (isFlashing) {
      final flashRadius = radius + (animationProgress * 20.0);
      final flashPaint = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: (1.0 - animationProgress).clamp(0.0, 0.9))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(center, flashRadius, flashPaint);
    }

    // Connected to user highlight ring
    if (isConnectedToYou) {
      final ringPaint = Paint()
        ..color = Colors.amber.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, radius + 9, ringPaint);
    }

    // Animated pulse wave around active node
    if (device.isOnline) {
      final pulseRadius = radius + (animationProgress * 12.0);
      final pulseAlpha = (1.0 - animationProgress).clamp(0.0, 0.7);
      final wavePaint = Paint()
        ..color = statusColor.withValues(alpha: pulseAlpha * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, pulseRadius, wavePaint);
    }

    // Outer glow
    final glowPaint = Paint()
      ..color = (isMaster ? AppColors.primaryLight : AppColors.secondary).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius + 6, glowPaint);

    // Node body circle
    final bodyPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bodyPaint);

    final borderPaint = Paint()
      ..color = isConnectedToYou
          ? Colors.amber
          : (isMaster ? AppColors.primaryLight : AppColors.primary)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius, borderPaint);

    // Status indicator dot
    final statusPaint = Paint()
      ..color = statusColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx + radius * 0.7, center.dy - radius * 0.7), 5.0, statusPaint);

    // Center icon/letter
    final textPainter = TextPainter(
      text: TextSpan(
        text: isMaster ? 'GW' : 'SAT',
        style: TextStyle(
          color: isConnectedToYou ? Colors.amber : (isMaster ? AppColors.primaryLight : AppColors.textPrimary),
          fontSize: isMaster ? 11 : 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );

    // Label under the node
    final labelPainter = TextPainter(
      text: TextSpan(
        text: device.name.isNotEmpty
            ? device.name
            : (isMaster ? 'Master' : device.ssidDefault),
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(
      canvas,
      Offset(center.dx - labelPainter.width / 2, center.dy + radius + 6),
    );

    // IP label under name
    final ipPainter = TextPainter(
      text: TextSpan(
        text: isConnectedToYou ? '${device.ipAddress} (You)' : device.ipAddress,
        style: TextStyle(
          color: isConnectedToYou ? Colors.amber : AppColors.textSecondary,
          fontSize: 10,
          fontWeight: isConnectedToYou ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    ipPainter.paint(
      canvas,
      Offset(center.dx - ipPainter.width / 2, center.dy + radius + 20),
    );
  }

  @override
  bool shouldRepaint(covariant TopologyCanvasPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.masterNode != masterNode ||
        oldDelegate.satellites != satellites ||
        oldDelegate.localConnectedNodeIp != localConnectedNodeIp ||
        oldDelegate.flashingNodeIps != flashingNodeIps;
  }
}

