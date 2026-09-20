import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/models/content_models.dart';
import '../../state/app_providers.dart';
import '../../state/exercise_session.dart';
import '../exercise/exercise_tile.dart';
import 'debug_workshop_screen.dart';

/// Retos: problemas que combinan varios conceptos y exigen decidir el camino.
class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> {
  Difficulty? _difficulty;
  String? _skill;
  bool _onlyPending = false;

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(loadedContentProvider);
    final progress = ref.watch(progressProvider);
    final colors = context.logic;

    final all = content.challenges;
    final skills = <String>{for (final e in all) ...e.concepts}.toList()..sort();

    final filtered = all.where((exercise) {
      if (_difficulty != null && exercise.difficulty != _difficulty) {
        return false;
      }
      if (_skill != null && !exercise.concepts.contains(_skill)) return false;
      if (_onlyPending && progress.isCompleted(exercise.id)) return false;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Retos'),
        actions: [
          IconButton(
            tooltip: 'Taller de depuracion',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DebugWorkshopScreen(),
              ),
            ),
            icon: const Icon(Icons.build_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(
            'Aqui no hay un unico concepto aislado: cada reto exige decidir '
            'que estructura usar y justificarlo con la ejecucion.',
            style: context.texts.bodySmall,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Solo pendientes'),
                selected: _onlyPending,
                onSelected: (value) => setState(() => _onlyPending = value),
              ),
              for (final difficulty in Difficulty.values)
                FilterChip(
                  label: Text(difficulty.label),
                  selected: _difficulty == difficulty,
                  onSelected: (value) => setState(
                      () => _difficulty = value ? difficulty : null),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final skill in skills)
                FilterChip(
                  label: Text(content.skillLabel(skill)),
                  selected: _skill == skill,
                  onSelected: (value) =>
                      setState(() => _skill = value ? skill : null),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Pill(
            '${filtered.length} de ${all.length} retos',
            icon: Icons.filter_alt_outlined,
            color: colors.info,
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const EmptyState(
              icon: Icons.search_off,
              title: 'Sin retos con estos filtros',
              message: 'Prueba a quitar algun filtro para ver mas problemas.',
            )
          else
            for (final exercise in filtered)
              ExerciseTile(exercise: exercise),
        ],
      ),
    );
  }
}
