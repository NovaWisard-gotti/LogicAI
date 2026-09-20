import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/models/content_models.dart';
import '../../state/app_providers.dart';
import 'exercise_screen.dart';

/// Acceso a un ejercicio con su estado de progreso.
class ExerciseTile extends ConsumerWidget {
  const ExerciseTile({super.key, required this.exercise, this.showModule = false});

  final Exercise exercise;
  final bool showModule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.logic;
    final progress = ref.watch(progressProvider).progressFor(exercise.id);
    final content = ref.watch(contentProvider).valueOrNull;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ExerciseScreen(exercise: exercise),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: progress.completed ? colors.success : colors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  progress.completed
                      ? Icons.check_circle
                      : kindIcon(exercise.kind),
                  color: progress.completed
                      ? colors.success
                      : colors.accentOnSurface,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exercise.title, style: context.texts.titleSmall),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Pill(exercise.kind.shortLabel, dense: true),
                          DifficultyPill(exercise.difficulty, dense: true),
                          if (showModule && content != null)
                            Pill(content.moduleTitle(exercise.moduleId),
                                dense: true, color: colors.info),
                          if (progress.attempts > 0 && !progress.completed)
                            Pill('${progress.attempts} intentos',
                                dense: true, color: colors.warning),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: colors.lineNumber),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
