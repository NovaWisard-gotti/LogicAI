import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../state/app_providers.dart';
import '../../state/exercise_session.dart';
import '../history/history_screen.dart';

/// Progreso entendido como evidencia de aprendizaje, no como puntuacion.
///
/// No hay monedas, vidas ni ranking: se muestra que se ha practicado, cuanto
/// se ha corregido y que queda por trabajar.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(loadedContentProvider);
    final progress = ref.watch(progressProvider);
    final colors = context.logic;
    final total = content.exercises.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi progreso'),
        actions: [
          IconButton(
            tooltip: 'Historial',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
            ),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: StatTile(
                  value: '${progress.completedCount}',
                  label: 'Resueltos de $total',
                  icon: Icons.task_alt,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  value: '${progress.totalAttempts}',
                  label: 'Intentos realizados',
                  icon: Icons.refresh,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  value: '${progress.errorsFixed}',
                  label: 'Errores corregidos',
                  icon: Icons.build_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Avance por modulo',
                    icon: Icons.school_outlined),
                const SizedBox(height: 12),
                for (final module in content.modules)
                  _ModuleProgress(
                    title: module.title,
                    icon: moduleIcon(module.icon),
                    done: module.exerciseIds
                        .where((id) => progress.isCompleted(id))
                        .length,
                    total: module.exerciseIds.length,
                  ),
                _ModuleProgress(
                  title: 'Retos',
                  icon: Icons.flag_outlined,
                  done: content.challengeIds
                      .where((id) => progress.isCompleted(id))
                      .length,
                  total: content.challengeIds.length,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Habilidades practicadas',
                    icon: Icons.insights_outlined),
                const SizedBox(height: 4),
                Text(
                  'Cuenta cuantas veces has trabajado cada competencia, '
                  'resolviendo o intentandolo.',
                  style: context.texts.bodySmall,
                ),
                const SizedBox(height: 12),
                if (progress.skillPractice.isEmpty)
                  Text('Todavia no hay practica registrada.',
                      style: context.texts.bodySmall)
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final skill in content.skills)
                        if ((progress.skillPractice[skill.id] ?? 0) > 0)
                          Pill(
                            '${skill.label} · ${progress.skillPractice[skill.id]}',
                            icon: Icons.bolt,
                            color: colors.accentOnSurface,
                          ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          InfoBanner(
            icon: Icons.privacy_tip_outlined,
            color: colors.info,
            text: 'Todo tu progreso se guarda solo en este dispositivo. '
                'LogicAI no necesita cuenta ni conexion.',
          ),
        ],
      ),
    );
  }
}

class _ModuleProgress extends StatelessWidget {
  const _ModuleProgress({
    required this.title,
    required this.icon,
    required this.done,
    required this.total,
  });

  final String title;
  final IconData icon;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    final ratio = total == 0 ? 0.0 : done / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.accentOnSurface),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.texts.bodyMedium),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: ratio, minHeight: 6),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text('$done/$total', style: context.texts.labelMedium),
        ],
      ),
    );
  }
}
