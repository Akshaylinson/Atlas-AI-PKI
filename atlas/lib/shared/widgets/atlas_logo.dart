import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ── Atlas Logo Mark ───────────────────────────────────────────────────────────
// Abstract symbol: central node + 4 orbital nodes connected by arcs,
// with a subtle compass-cross overlay. Reads as "interconnected intelligence".

class AtlasLogo extends StatelessWidget {
  final double size;
  final bool dark; // true = ink-on-paper, false = paper-on-ink

  const AtlasLogo({super.key, this.size = 48, this.dark = true});

  @override
  Widget build(BuildContext context) {
    final bg = dark ? AtlasColors.ink : AtlasColors.paper;
    final fg = dark ? AtlasColors.paper : AtlasColors.ink;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AtlasLogoPainter(foreground: fg, background: bg),
      ),
    );
  }
}

class _AtlasLogoPainter extends CustomPainter {
  final Color foreground;
  final Color background;

  const _AtlasLogoPainter({required this.foreground, required this.background});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Background circle
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = background,
    );

    final strokeThin = Paint()
      ..color = foreground
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045
      ..strokeCap = StrokeCap.round;

    final strokeThick = Paint()
      ..color = foreground
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = foreground
      ..style = PaintingStyle.fill;

    // Outer ring (partial arcs — 4 quadrant arcs with gaps)
    final outerR = r * 0.72;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: outerR);
    const gapAngle = 0.38; // radians gap between arcs
    const arcSpan = (math.pi / 2) - gapAngle;
    for (var i = 0; i < 4; i++) {
      final startAngle = i * (math.pi / 2) + gapAngle / 2;
      canvas.drawArc(rect, startAngle, arcSpan, false, strokeThin);
    }

    // 4 orbital nodes at cardinal positions on the outer ring
    final orbitalAngles = [
      -math.pi / 2, // top
      0.0,          // right
      math.pi / 2,  // bottom
      math.pi,      // left
    ];
    final nodeR = r * 0.72;
    final dotR = size.width * 0.055;

    for (final angle in orbitalAngles) {
      final nx = cx + nodeR * math.cos(angle);
      final ny = cy + nodeR * math.sin(angle);
      // Spoke from center to node
      canvas.drawLine(
        Offset(cx, cy),
        Offset(nx, ny),
        strokeThin,
      );
      // Node dot
      canvas.drawCircle(Offset(nx, ny), dotR, dotPaint);
    }

    // 4 diagonal connector lines between adjacent orbital nodes
    for (var i = 0; i < 4; i++) {
      final a1 = orbitalAngles[i];
      final a2 = orbitalAngles[(i + 1) % 4];
      final x1 = cx + nodeR * math.cos(a1);
      final y1 = cy + nodeR * math.sin(a1);
      final x2 = cx + nodeR * math.cos(a2);
      final y2 = cy + nodeR * math.sin(a2);
      canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        strokeThin..strokeWidth = size.width * 0.03,
      );
    }

    // Central node — larger, prominent
    canvas.drawCircle(Offset(cx, cy), size.width * 0.10, dotPaint);

    // Tiny center highlight ring
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.10,
      Paint()
        ..color = background
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.025,
    );
  }

  @override
  bool shouldRepaint(_AtlasLogoPainter old) =>
      old.foreground != foreground || old.background != background;
}

// ── Atlas Wordmark ────────────────────────────────────────────────────────────

class AtlasWordmark extends StatelessWidget {
  final double fontSize;
  final Color? color;

  const AtlasWordmark({super.key, this.fontSize = 24, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AtlasColors.ink;
    return Text(
      'ATLAS',
      style: AtlasTextStyles.headingSm.copyWith(
        fontSize: fontSize,
        letterSpacing: fontSize * 0.12,
        fontWeight: FontWeight.w600,
        color: c,
      ),
    );
  }
}

// ── Atlas Logo + Wordmark combined ────────────────────────────────────────────

class AtlasBrand extends StatelessWidget {
  final double logoSize;
  final double fontSize;
  final bool dark;
  final Axis axis;

  const AtlasBrand({
    super.key,
    this.logoSize = 40,
    this.fontSize = 20,
    this.dark = true,
    this.axis = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    final color = dark ? AtlasColors.ink : AtlasColors.paper;
    final children = [
      AtlasLogo(size: logoSize, dark: dark),
      axis == Axis.horizontal
          ? SizedBox(width: logoSize * 0.3)
          : SizedBox(height: logoSize * 0.2),
      AtlasWordmark(fontSize: fontSize, color: color),
    ];
    return axis == Axis.horizontal
        ? Row(mainAxisSize: MainAxisSize.min, children: children)
        : Column(mainAxisSize: MainAxisSize.min, children: children);
  }
}
