import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../state/app_providers.dart';
import '../../state/exercise_session.dart';
import '../exercise/exercise_tile.dart';

/// Taller de depuracion: programas que se ejecutan pero se comportan mal.
///
/// Depurar es una competencia profesional propia, no un castigo por fallar.
class DebugWorkshopScreen extends ConsumerWidget {
  const DebugWorkshopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(loadedContentProvider);
    final progress = ref.watch(progressProvider);
    final exercises = content.debugWorkshop;
    final fixed =
        exercises.where((e) => progress.isCompleted(e.id)).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Taller de depuracion')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          InfoBanner(
            icon: Icons.bug_report_outlined,
            color: context.logic.warning,
            title: 'Programas que funcionan mal',
            text: 'Cada programa aqui tiene un fallo real: unos producen un '
                'resultado incorrecto, otros se detienen o no terminan nunca. '
                'Ejecuta, observa la memoria y localiza el paso donde el '
                'estado deja de ser el esperado.',
          ),
          const SizedBox(height: 12),
          Pill('$fixed de ${exercises.length} programas reparados',
              icon: Icons.handyman_outlined),
          const SizedBox(height: 16),
          for (final exercise in exercises)
            ExerciseTile(exercise: exercise, showModule: true),
        ],
      ),
    );
  }
}
