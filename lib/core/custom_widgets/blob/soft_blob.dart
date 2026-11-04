import 'dart:math';

import 'package:flutter/material.dart';

/// Soft organic blob, used as a backdrop behind the brain.
class SoftBlob extends StatelessWidget {
  const SoftBlob({super.key, required this.size, required this.color, this.child});

  final double size;
  final Color color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _BlobPainter(color),
        child: child == null ? null : Center(child: child),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    const n = 8;
    // Fixed wobble per point so the shape is stable between frames.
    const wobble = [0.96, 1.0, 0.93, 0.99, 0.95, 1.0, 0.92, 0.98];
    final pts = [for (var i = 0; i < n; i++) c + Offset(cos(2 * pi * i / n), sin(2 * pi * i / n)) * r * wobble[i]];
    final path = Path()..moveTo((pts[0].dx + pts[1].dx) / 2, (pts[0].dy + pts[1].dy) / 2);
    for (var i = 1; i <= n; i++) {
      final p = pts[i % n];
      final next = pts[(i + 1) % n];
      path.quadraticBezierTo(p.dx, p.dy, (p.dx + next.dx) / 2, (p.dy + next.dy) / 2);
    }
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.color != color;
}
