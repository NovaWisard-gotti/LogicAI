import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/models/progress_models.dart';
import '../../state/app_providers.dart';
import '../../state/exercise_session.dart';
import '../exercise/exercise_screen.dart';

/// Historial de trabajo: permite volver sobre un intento anterior.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(loadedContentProvider);
    final history = ref.watch(progressProvider).history;

    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: history.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: EmptyState(
                icon: Icons.history_toggle_off,
                title: 'Aun no hay actividad',
                message:
                    'Cuando resuelvas o intentes un ejercicio apareceran aqui '
                    'tus intentos, con la fecha y el resultado.',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final entry = history[index];
                return _HistoryTile(
                  entry: entry,
                  moduleTitle: content.moduleTitle(entry.moduleId),
                  onTap: content.exercises.containsKey(entry.exerciseId)
                      ? () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ExerciseScreen(
                                exercise: content.byId(entry.exerciseId),
                              ),
                            ),
                          )
                      : null,
                );
              },
            ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.entry,
    required this.moduleTitle,
    required this.onTap,
  });

  final HistoryEntry entry;
  final String moduleTitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    final solved = entry.result == AttemptResult.resuelto;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(
                  solved ? Icons.check_circle_outline : Icons.replay_outlined,
                  color: solved ? colors.success : colors.warning,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.title, style: context.texts.bodyMedium),
                      const SizedBox(height: 4),
                      Text(
                        '$moduleTitle · ${entry.result.label} · intento '
                        '${entry.attempt} · ${_formatDate(entry.date)}'
                        '${entry.detail == null ? '' : ' · ${entry.detail}'}',
                        style: context.texts.labelSmall,
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.chevron_right, color: colors.lineNumber),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }
}
