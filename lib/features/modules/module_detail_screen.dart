import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/code_view.dart';
import '../../core/widgets/common.dart';
import '../../data/models/content_models.dart';
import '../../state/app_providers.dart';
import '../../state/exercise_session.dart';
import '../exercise/exercise_tile.dart';

/// Detalle de un modulo: primero la idea, despues la practica.
///
/// La teoria es deliberadamente breve: LogicAI no es un libro digital, el
/// aprendizaje ocurre ejecutando y observando.
class ModuleDetailScreen extends ConsumerWidget {
  const ModuleDetailScreen({super.key, required this.moduleId});

  final String moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(loadedContentProvider);
    final progress = ref.watch(progressProvider);
    final module = content.moduleById(moduleId)!;
    final exercises =
        module.exerciseIds.map((id) => content.byId(id)).toList();
    final done =
        module.exerciseIds.where((id) => progress.isCompleted(id)).length;

    return Scaffold(
      appBar: AppBar(title: Text(module.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(moduleIcon(module.icon),
                        color: context.logic.accentOnSurface),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(module.subtitle,
                          style: context.texts.bodyMedium),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Pill('$done de ${exercises.length} ejercicios trabajados',
                    icon: Icons.insights_outlined),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('La idea', style: context.texts.titleSmall),
          const SizedBox(height: 10),
          for (final block in module.theory) ...[
            _TheoryCard(block: block),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          Text('Practica', style: context.texts.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Ordenados de la observacion a la construccion.',
            style: context.texts.bodySmall,
          ),
          const SizedBox(height: 12),
          for (final exercise in exercises) ExerciseTile(exercise: exercise),
        ],
      ),
    );
  }
}

class _TheoryCard extends StatelessWidget {
  const _TheoryCard({required this.block});

  final TheoryBlock block;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(block.title, style: context.texts.titleSmall),
          const SizedBox(height: 6),
          Text(block.body, style: context.texts.bodyMedium),
          if (block.code != null) ...[
            const SizedBox(height: 10),
            CodeView(code: block.code!, fontSize: 13.5),
          ],
        ],
      ),
    );
  }
}
