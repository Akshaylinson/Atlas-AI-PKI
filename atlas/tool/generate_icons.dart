// Run with: dart run tool/generate_icons.dart
import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

void main() {
  const sizes = {
    'mipmap-mdpi':    48,
    'mipmap-hdpi':    72,
    'mipmap-xhdpi':   96,
    'mipmap-xxhdpi':  144,
    'mipmap-xxxhdpi': 192,
  };

  for (final entry in sizes.entries) {
    final size = entry.value;
    final image = _renderIcon(size);
    final path = 'android/app/src/main/res/${entry.key}/ic_launcher.png';
    File(path).writeAsBytesSync(img.encodePng(image));
    print('✓ $path  (${size}x$size)');
  }
  print('\nDone. Rebuild the app to pick up new icons.');
}

img.Image _renderIcon(int size) {
  final image = img.Image(width: size, height: size);

  // Dark rounded-rect background
  _fillRoundedRect(image, 0, 0, size, size, (size * 0.22).round(),
      img.ColorRgba8(10, 10, 10, 255));

  final cx = size / 2;
  final cy = size / 2;
  final nodeR = size * 0.29; // 0.58 * r, r = size/2
  final white = img.ColorRgba8(255, 255, 255, 255);

  // Outer ring — 4 arcs with gaps
  const gapAngle = 0.38;
  const arcSpan  = (math.pi / 2) - gapAngle;
  final outerR = nodeR;
  for (var i = 0; i < 4; i++) {
    final start = i * (math.pi / 2) + gapAngle / 2;
    _drawArc(image, cx, cy, outerR, start, arcSpan,
        (size * 0.045).round(), white);
  }

  // Spokes + orbital dots
  final orbitalAngles = [-math.pi / 2, 0.0, math.pi / 2, math.pi];
  final dotR = (size * 0.055).round();

  for (final angle in orbitalAngles) {
    final nx = cx + nodeR * math.cos(angle);
    final ny = cy + nodeR * math.sin(angle);
    _drawLine(image, cx, cy, nx, ny, (size * 0.04).round(), white);
    _fillCircle(image, nx.round(), ny.round(), dotR, white);
  }

  // Diagonal connectors
  for (var i = 0; i < 4; i++) {
    final a1 = orbitalAngles[i];
    final a2 = orbitalAngles[(i + 1) % 4];
    _drawLine(
      image,
      cx + nodeR * math.cos(a1), cy + nodeR * math.sin(a1),
      cx + nodeR * math.cos(a2), cy + nodeR * math.sin(a2),
      (size * 0.028).round(),
      white,
    );
  }

  // Central node
  final centralR = (size * 0.10).round();
  _fillCircle(image, cx.round(), cy.round(), centralR, white);
  // Inner ring (dark cutout)
  _drawCircleOutline(image, cx.round(), cy.round(), centralR,
      (size * 0.025).round(), img.ColorRgba8(10, 10, 10, 255));

  return image;
}

// ── Drawing helpers ───────────────────────────────────────────────────────────

void _fillRoundedRect(img.Image image, int x, int y, int w, int h,
    int radius, img.Color color) {
  for (var py = y; py < y + h; py++) {
    for (var px = x; px < x + w; px++) {
      if (_inRoundedRect(px, py, x, y, w, h, radius)) {
        image.setPixel(px, py, color);
      }
    }
  }
}

bool _inRoundedRect(int px, int py, int x, int y, int w, int h, int r) {
  final dx = (px < x + r)
      ? x + r - px
      : (px > x + w - r - 1)
          ? px - (x + w - r - 1)
          : 0;
  final dy = (py < y + r)
      ? y + r - py
      : (py > y + h - r - 1)
          ? py - (y + h - r - 1)
          : 0;
  return dx * dx + dy * dy <= r * r;
}

void _fillCircle(img.Image image, int cx, int cy, int r, img.Color color) {
  for (var py = cy - r; py <= cy + r; py++) {
    for (var px = cx - r; px <= cx + r; px++) {
      final dx = px - cx;
      final dy = py - cy;
      if (dx * dx + dy * dy <= r * r) {
        if (px >= 0 && py >= 0 && px < image.width && py < image.height) {
          image.setPixel(px, py, color);
        }
      }
    }
  }
}

void _drawCircleOutline(
    img.Image image, int cx, int cy, int r, int thickness, img.Color color) {
  final inner = r - thickness;
  for (var py = cy - r; py <= cy + r; py++) {
    for (var px = cx - r; px <= cx + r; px++) {
      final dx = px - cx;
      final dy = py - cy;
      final dist2 = dx * dx + dy * dy;
      if (dist2 <= r * r && dist2 >= inner * inner) {
        if (px >= 0 && py >= 0 && px < image.width && py < image.height) {
          image.setPixel(px, py, color);
        }
      }
    }
  }
}

void _drawLine(img.Image image, double x1, double y1, double x2, double y2,
    int thickness, img.Color color) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  final len = math.sqrt(dx * dx + dy * dy);
  final steps = (len * 2).ceil();
  for (var i = 0; i <= steps; i++) {
    final t = i / steps;
    final px = x1 + dx * t;
    final py = y1 + dy * t;
    _fillCircle(image, px.round(), py.round(), (thickness / 2).round(), color);
  }
}

void _drawArc(img.Image image, double cx, double cy, double r,
    double startAngle, double sweep, int thickness, img.Color color) {
  final steps = (r * sweep * 4).ceil();
  for (var i = 0; i <= steps; i++) {
    final angle = startAngle + sweep * i / steps;
    final px = cx + r * math.cos(angle);
    final py = cy + r * math.sin(angle);
    _fillCircle(
        image, px.round(), py.round(), (thickness / 2).round(), color);
  }
}
