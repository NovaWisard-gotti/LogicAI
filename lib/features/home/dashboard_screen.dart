import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/models/content_models.dart';
import '../../state/app_providers.dart';
import '../../state/exercise_session.dart';
import '../challenges/debug_workshop_screen.dart';
import '../exercise/exercise_screen.dart';
import '../history/history_screen.dart';
import '../reference/reference_screen.dart';
import '../settings/settings_screen.dart';

/// Pantalla inicial: estado real del estudiante y siguiente paso concreto.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, this.onNavigate});

  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(loadedContentProvider);
    final progress = ref.watch(progressProvider);
    final colors = context.logic;

    final next = _nextExercise(content, progress.isCompleted);
    final totalExercises = content.exercises.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LogicAI'),
        actions: [
          IconButton(
            tooltip: 'Consulta rapida',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ReferenceScreen()),
            ),
            icon: const Icon(Icons.menu_book_outlined),
          ),
          IconButton(
            tooltip: 'Historial',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
            ),
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: 'Ajustes',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_tree_outlined,
                        color: colors.accentOnSurface),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Laboratorio de logica',
                          style: context.texts.titleMedium),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Aqui no se memoriza codigo: se construye, se ejecuta, se '
                  'observa lo que pasa en memoria y se corrige con evidencia.',
                  style: context.texts.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  value: '${progress.completedCount}/$totalExercises',
                  label: 'Ejercicios resueltos',
                  icon: Icons.task_alt,
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
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  value: '${progress.challengesSolved}',
                  label: 'Retos superados',
                  icon: Icons.flag_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (next != null) ...[
            Text('Continuar', style: context.texts.titleSmall),
            const SizedBox(height: 10),
            _ContinueCard(exercise: next, content: content),
            const SizedBox(height: 16),
          ],
          Text('Zonas de trabajo', style: context.texts.titleSmall),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.school_outlined,
            title: 'Modulos de fundamentos',
            subtitle:
                '${content.modules.length} modulos: de variables a objetos.',
            onTap: () => onNavigate?.call(1),
          ),
          _ActionCard(
            icon: Icons.science_outlined,
            title: 'Laboratorio de logica',
            subtitle: 'Escribe pseudocodigo libre y observa su ejecucion.',
            onTap: () => onNavigate?.call(2),
          ),
          _ActionCard(
            icon: Icons.build_outlined,
            title: 'Taller de depuracion',
            subtitle:
                '${content.debugWorkshopIds.length} programas con errores reales que localizar.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DebugWorkshopScreen(),
              ),
            ),
          ),
          _ActionCard(
            icon: Icons.flag_outlined,
            title: 'Retos',
            subtitle:
                '${content.challengeIds.length} problemas que combinan varios conceptos.',
            onTap: () => onNavigate?.call(3),
          ),
          _ActionCard(
            icon: Icons.menu_book_outlined,
            title: 'Consulta rapida',
            subtitle: 'Sintaxis del pseudocodigo siempre a mano.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ReferenceScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Exercise? _nextExercise(AppContent content, bool Function(String id) completed) {
    for (final module in content.modules) {
      for (final id in module.exerciseIds) {
        if (!completed(id)) return content.byId(id);
      }
    }
    for (final id in content.challengeIds) {
      if (!completed(id)) return content.byId(id);
    }
    return null;
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.exercise, required this.content});

  final Exercise exercise;
  final AppContent content;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    return SectionCard(
      borderColor: colors.accentOnSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Pill(content.moduleTitle(exercise.moduleId),
                  icon: Icons.folder_outlined, dense: true),
              Pill(exercise.kind.label,
                  icon: kindIcon(exercise.kind),
                  dense: true,
                  color: colors.accentOnSurface),
              DifficultyPill(exercise.difficulty, dense: true),
            ],
          ),
          const SizedBox(height: 10),
          Text(exercise.title, style: context.texts.titleSmall),
          const SizedBox(height: 6),
          Text(
            exercise.statement,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: context.texts.bodySmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ExerciseScreen(exercise: exercise),
                ),
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Continuar aqui'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(icon, color: colors.accentOnSurface),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.texts.titleSmall),
                      const SizedBox(height: 2),
                      Text(subtitle, style: context.texts.bodySmall),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.lineNumber),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
