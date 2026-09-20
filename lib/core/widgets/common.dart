import 'package:flutter/material.dart';

import '../../data/models/content_models.dart';
import '../theme/app_theme.dart';

IconData moduleIcon(String key) => switch (key) {
      'box' => Icons.data_object,
      'calc' => Icons.calculate_outlined,
      'branch' => Icons.call_split,
      'loop' => Icons.loop,
      'func' => Icons.functions,
      'array' => Icons.view_list_outlined,
      'object' => Icons.widgets_outlined,
      _ => Icons.circle_outlined,
    };

IconData kindIcon(ExerciseKind kind) => switch (kind) {
      ExerciseKind.trace => Icons.play_circle_outline,
      ExerciseKind.predict => Icons.psychology_alt_outlined,
      ExerciseKind.complete => Icons.extension_outlined,
      ExerciseKind.repair => Icons.build_outlined,
      ExerciseKind.build => Icons.construction_outlined,
    };

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? context.scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? colors.border),
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.icon, this.trailing});

  final String text;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: context.logic.accentOnSurface),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            text,
            style: context.texts.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Etiqueta compacta. Siempre combina color con texto (y opcionalmente icono)
/// para no depender únicamente del color.
class Pill extends StatelessWidget {
  const Pill(
    this.text, {
    super.key,
    this.icon,
    this.color,
    this.background,
    this.dense = false,
  });

  final String text;
  final IconData? icon;
  final Color? color;
  final Color? background;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? context.scheme.onSurfaceVariant;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: dense ? 7 : 9, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(
        color: background ?? fg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 11 : 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: dense ? 10.5 : 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    this.title,
    this.trailing,
  });

  final String text;
  final String? title;
  final IconData icon;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      title!,
                      style: context.texts.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                Text(text,
                    style: context.texts.bodyMedium?.copyWith(height: 1.35)),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: context.scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: colors.accentOnSurface),
          const SizedBox(height: 8),
          Text(value,
              style: context.texts.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: context.texts.bodySmall
                  ?.copyWith(color: context.scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class DifficultyPill extends StatelessWidget {
  const DifficultyPill(this.difficulty, {super.key, this.dense = false});

  final Difficulty difficulty;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    final (color, icon) = switch (difficulty) {
      Difficulty.fundamentos => (colors.info, Icons.looks_one_outlined),
      Difficulty.aplicacion => (colors.accentOnSurface, Icons.looks_two_outlined),
      Difficulty.desafio => (colors.warning, Icons.looks_3_outlined),
    };
    return Pill(difficulty.label, icon: icon, color: color, dense: dense);
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: context.scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(title,
                style: context.texts.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.texts.bodyMedium
                  ?.copyWith(color: context.scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
