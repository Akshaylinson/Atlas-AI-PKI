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
        ? Colors.green
        : confidence > 0.4
            ? Colors.orange
            : Colors.red;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: confidence,
            strokeWidth: 6,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Text(
            '${(confidence * 100).toStringAsFixed(0)}%',
            style: TextStyle(
                fontSize: size * 0.2, fontWeight: FontWeight.bold, color: color),
          ),
        ],
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
