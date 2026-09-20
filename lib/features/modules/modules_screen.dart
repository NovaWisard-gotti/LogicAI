import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/models/content_models.dart';
import '../../state/app_providers.dart';
import '../../state/exercise_session.dart';
import 'module_detail_screen.dart';

/// Mapa de los siete modulos de fundamentos, en orden de dependencia.
class ModulesScreen extends ConsumerWidget {
  const ModulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(loadedContentProvider);
    final progress = ref.watch(progressProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Modulos de fundamentos')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'Cada modulo empieza por la idea, sigue con la observacion del '
            'programa en ejecucion y termina construyendo o reparando codigo.',
            style: context.texts.bodySmall,
          ),
          const SizedBox(height: 16),
          for (final module in content.modules)
            _ModuleCard(
              module: module,
              done: module.exerciseIds
                  .where((id) => progress.isCompleted(id))
                  .length,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ModuleDetailScreen(moduleId: module.id),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.module,
    required this.done,
    required this.onTap,
  });

  final LearningModule module;
  final int done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    final total = module.exerciseIds.length;
    final ratio = total == 0 ? 0.0 : done / total;
    final complete = total > 0 && done == total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SectionCard(
            borderColor: complete ? colors.success : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: colors.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      child: Icon(moduleIcon(module.icon),
                          size: 22, color: colors.accentOnSurface),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('${module.order}. ',
                                  style: context.texts.labelMedium),
                              Expanded(
                                child: Text(module.title,
                                    style: context.texts.titleSmall),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(module.subtitle,
                              style: context.texts.bodySmall),
                        ],
                      ),
                    ),
                    Icon(
                      complete ? Icons.check_circle : Icons.chevron_right,
                      color: complete ? colors.success : colors.lineNumber,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: ratio, minHeight: 6),
                ),
                const SizedBox(height: 8),
                Text('$done de $total ejercicios trabajados',
                    style: context.texts.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
