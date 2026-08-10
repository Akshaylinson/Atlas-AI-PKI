import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/utils.dart';

// ── Stat Card ─────────────────────────────────────────────────────────────────

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: c, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: c)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.6))),
        ],
      ),
    );
  }
}

// ── Confidence Gauge ──────────────────────────────────────────────────────────

class ConfidenceGauge extends StatelessWidget {
  final double confidence; // 0.0 - 1.0
  final double size;

  const ConfidenceGauge({super.key, required this.confidence, this.size = 80});

  @override
  Widget build(BuildContext context) {
    final color = confidence > 0.7
        ? const Color(0xFF16A34A)
        : confidence > 0.4
            ? const Color(0xFFD97706)
            : const Color(0xFFDC2626);
    return SizedBox(
      width: size,
      height: size * 0.65,
      child: CustomPaint(
        painter: _ArcGaugePainter(value: confidence, color: color),
        child: Align(
          alignment: const Alignment(0, 0.6),
          child: Text(
            '${(confidence * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: size * 0.18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  final double value;
  final Color color;
  const _ArcGaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.9;
    final r = size.width * 0.44;
    const startAngle = math.pi;
    const sweepAngle = math.pi;
    final strokeW = size.width * 0.09;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    canvas.drawArc(
      rect, startAngle, sweepAngle, false,
      Paint()
        ..color = color.withOpacity(0.15)
        ..strokeWidth = strokeW
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      rect, startAngle, sweepAngle * value.clamp(0.0, 1.0), false,
      Paint()
        ..color = color
        ..strokeWidth = strokeW
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcGaugePainter old) => old.value != value || old.color != color;
}

// ── Activity Heatmap ──────────────────────────────────────────────────────────

class ActivityHeatmap extends StatelessWidget {
  /// Map of date string 'yyyy-MM-dd' → count
  final Map<String, int> dayCounts;
  /// Number of weeks to show (columns)
  final int weeks;

  const ActivityHeatmap({super.key, required this.dayCounts, this.weeks = 12});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final maxCount = dayCounts.values.fold(0, math.max);
    final cellSize = 14.0;
    final gap = 3.0;

    // Build grid: weeks columns × 7 rows
    final totalDays = weeks * 7;
    final startDay = now.subtract(Duration(days: totalDays - 1));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(weeks, (w) {
          return Padding(
            padding: EdgeInsets.only(right: gap),
            child: Column(
              children: List.generate(7, (d) {
                final day = startDay.add(Duration(days: w * 7 + d));
                final key =
                    '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                final count = dayCounts[key] ?? 0;
                final intensity = maxCount > 0 ? count / maxCount : 0.0;
                final color = intensity == 0
                    ? scheme.outline.withOpacity(0.2)
                    : scheme.primary.withOpacity(0.15 + intensity * 0.85);
                return Padding(
                  padding: EdgeInsets.only(bottom: gap),
                  child: Tooltip(
                    message: '$key: $count',
                    child: Container(
                      width: cellSize,
                      height: cellSize,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

// ── Mood Chip ─────────────────────────────────────────────────────────────────

class MoodChip extends StatelessWidget {
  final String mood;
  final bool selected;
  final VoidCallback? onTap;

  const MoodChip({super.key, required this.mood, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = moodColors[mood] ?? Colors.grey;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(moodEmojis[mood] ?? '😐', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              mood[0].toUpperCase() + mood.substring(1),
              style: TextStyle(
                color: selected ? Colors.white : color,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Importance Selector ───────────────────────────────────────────────────────

class ImportanceSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const ImportanceSelector({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final level = i + 1;
        final color = importanceColors[level] ?? Colors.grey;
        return GestureDetector(
          onTap: () => onChanged(level),
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              level <= value ? Icons.star_rounded : Icons.star_outline_rounded,
              color: level <= value ? color : Colors.grey.shade300,
              size: 28,
            ),
          ),
        );
      }),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: scheme.primary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: TextStyle(color: scheme.onSurface.withOpacity(0.6)),
                textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

// ── Tag Chip ──────────────────────────────────────────────────────────────────

class TagChip extends StatelessWidget {
  final String tag;
  final VoidCallback? onDelete;

  const TagChip({super.key, required this.tag, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      label: Text(tag, style: const TextStyle(fontSize: 12)),
      deleteIcon: onDelete != null ? const Icon(Icons.close, size: 14) : null,
      onDeleted: onDelete,
      backgroundColor: scheme.primaryContainer,
      labelStyle: TextStyle(color: scheme.onPrimaryContainer),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

// ── Risk Badge ────────────────────────────────────────────────────────────────

class RiskBadge extends StatelessWidget {
  final String riskLevel;

  const RiskBadge({super.key, required this.riskLevel});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (riskLevel) {
      case 'Low Risk':
        color = Colors.green;
        break;
      case 'Medium Risk':
        color = Colors.orange;
        break;
      default:
        color = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(riskLevel,
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}

// ── Loading Overlay ───────────────────────────────────────────────────────────

class LoadingOverlay extends StatelessWidget {
  final String? message;

  const LoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(message!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
