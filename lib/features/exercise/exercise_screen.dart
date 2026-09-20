import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/code_view.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/line_editor.dart';
import '../../data/models/content_models.dart';
import '../../state/app_providers.dart';
import '../../state/execution_controller.dart';
import '../../state/exercise_session.dart';
import 'widgets/blanks_panel.dart';
import 'widgets/block_builder.dart';
import 'widgets/comparison_panel.dart';
import 'widgets/feedback_panel.dart';
import 'widgets/memory_inspector.dart';
import 'widgets/output_panel.dart';
import 'widgets/predict_panel.dart';
import 'widgets/test_cases_panel.dart';
import 'widgets/tracer_panel.dart';

/// Pantalla de trabajo de un ejercicio.
///
/// Reune el ciclo educativo completo: leer el problema, razonar, construir o
/// reparar, ejecutar, observar la memoria, recibir explicacion y comparar.
class ExerciseScreen extends ConsumerStatefulWidget {
  const ExerciseScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  ConsumerState<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends ConsumerState<ExerciseScreen> {
  Exercise get exercise => widget.exercise;

  bool _reachedEnd = false;

  ExerciseTest get _activeTest => exercise.tests.first;

  void _run({ExerciseTest? test}) {
    final session = ref.read(exerciseSessionProvider(exercise).notifier);
    final execution =
        ref.read(executionControllerProvider(exercise.id).notifier);
    final chosen = test ?? _activeTest;
    execution.run(
      session.assembledCode,
      inputs: chosen.inputs,
      caseLabel: exercise.tests.length > 1 ? chosen.label : null,
    );
    setState(() => _reachedEnd = false);
  }

  Future<void> _check() async {
    final controller = ref.read(exerciseSessionProvider(exercise).notifier);
    final solved = controller.check();
    final state = ref.read(exerciseSessionProvider(exercise));

    if (exercise.kind != ExerciseKind.predict) {
      _run();
    }

    await ref.read(progressProvider.notifier).registerAttempt(
          exercise,
          solved: solved,
          detail: exercise.kind == ExerciseKind.predict
              ? (solved ? 'Prediccion correcta' : 'Prediccion incorrecta')
              : state.verification == null
                  ? null
                  : '${state.verification!.passedCount}/'
                      '${state.verification!.outcomes.length} casos',
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(solved
              ? 'Resuelto. Revisa la comparacion con la solucion de referencia.'
              : 'Aun no. Lee la explicacion y usa el trazador para localizar el fallo.'),
        ),
      );
  }

  Future<void> _completeTrace() async {
    final controller = ref.read(exerciseSessionProvider(exercise).notifier);
    if (ref.read(exerciseSessionProvider(exercise)).solved) return;
    controller.markTraced();
    await ref.read(progressProvider.notifier).registerAttempt(
          exercise,
          solved: true,
          detail: 'Recorrido completo',
        );
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(loadedContentProvider);
    final session = ref.watch(exerciseSessionProvider(exercise));
    final sessionController =
        ref.read(exerciseSessionProvider(exercise).notifier);
    final execution = ref.watch(executionControllerProvider(exercise.id));
    final executionController =
        ref.read(executionControllerProvider(exercise.id).notifier);
    final colors = context.logic;

    // Un ejercicio de trazado se da por trabajado cuando se recorre entero.
    if (exercise.kind == ExerciseKind.trace &&
        execution.hasRun &&
        execution.atEnd &&
        !_reachedEnd) {
      _reachedEnd = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _completeTrace());
    }

    final assembled = sessionController.assembledCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.title, overflow: TextOverflow.ellipsis),
        actions: [
          if (exercise.kind != ExerciseKind.trace)
            IconButton(
              tooltip: 'Reiniciar mi trabajo',
              onPressed: () {
                sessionController.resetWork();
                executionController.clear();
                setState(() => _reachedEnd = false);
              },
              icon: const Icon(Icons.restart_alt),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          _Header(exercise: exercise, content: content, solved: session.solved),
          const SizedBox(height: 12),
          ..._workArea(session, sessionController, execution, assembled),
          const SizedBox(height: 12),
          if (exercise.kind != ExerciseKind.predict || session.checked) ...[
            TracerPanel(
              code: assembled.trim().isEmpty
                  ? 'inicio\n    // todavia no hay instrucciones\nfin'
                  : assembled,
              state: execution,
              controller: executionController,
            ),
            const SizedBox(height: 12),
            MemoryInspector(state: execution),
            const SizedBox(height: 12),
            OutputPanel(state: execution, expected: _activeTest.expected),
            const SizedBox(height: 12),
          ],
          if (session.checked && session.verification != null) ...[
            FeedbackPanel(
              exercise: exercise,
              verification: session.verification!,
              content: content,
            ),
            const SizedBox(height: 12),
            WhatHappenedPanel(outcome: session.verification!.representative),
            const SizedBox(height: 12),
          ],
          if (exercise.kind != ExerciseKind.trace &&
              exercise.kind != ExerciseKind.predict) ...[
            TestCasesPanel(
              exercise: exercise,
              verification: session.verification,
              onRunCase: (test) => _run(test: test),
            ),
            const SizedBox(height: 12),
          ],
          _HelpSection(
            exercise: exercise,
            session: session,
            onHint: sessionController.revealHint,
            onSolution: sessionController.revealSolution,
          ),
          if (session.solved || session.solutionRevealed) ...[
            const SizedBox(height: 12),
            if (exercise.kind == ExerciseKind.complete ||
                exercise.kind == ExerciseKind.repair ||
                exercise.kind == ExerciseKind.build)
              ComparisonPanel(exercise: exercise, myCode: assembled),
          ],
          const SizedBox(height: 12),
          if (session.solved)
            InfoBanner(
              icon: Icons.emoji_objects_outlined,
              color: colors.success,
              title: 'Ejercicio superado',
              text: exercise.focus ??
                  'Has comprobado el comportamiento del programa con evidencia, '
                      'no por intuicion.',
            ),
        ],
      ),
      bottomNavigationBar: _ActionBar(
        exercise: exercise,
        session: session,
        execution: execution,
        onRun: () => _run(),
        onCheck: _check,
        ready: sessionController.isReadyToCheck,
      ),
    );
  }

  List<Widget> _workArea(
    ExerciseSessionState session,
    ExerciseSessionController controller,
    ExecutionViewState execution,
    String assembled,
  ) {
    switch (exercise.kind) {
      case ExerciseKind.trace:
        return const [];
      case ExerciseKind.predict:
        return [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Programa', icon: Icons.code),
                const SizedBox(height: 10),
                CodeView(code: exercise.code ?? ''),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PredictPanel(
            question: exercise.question!,
            choice: session.predictionChoice,
            checked: session.checked,
            onChoose: controller.choosePrediction,
          ),
        ];
      case ExerciseKind.complete:
        return [
          BlanksPanel(
            exercise: exercise,
            choices: session.blankChoices,
            onChoose: controller.chooseBlank,
            showExplanations: session.checked,
          ),
        ];
      case ExerciseKind.build:
        return [
          BlockBuilder(
            exercise: exercise,
            chosen: session.chosenBlocks,
            onAdd: controller.addBlock,
            onRemove: controller.removeBlock,
            onMove: controller.moveBlock,
            onClear: controller.clearBlocks,
          ),
        ];
      case ExerciseKind.repair:
        return [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Taller de depuracion',
                    icon: Icons.build_outlined),
                const SizedBox(height: 4),
                Text(
                  'Este programa se ejecuta, pero no hace lo que deberia. '
                  'Localiza el fallo, corrigelo y vuelve a comprobar.',
                  style: context.texts.bodySmall,
                ),
                const SizedBox(height: 12),
                LineCodeEditor(
                  code: session.code,
                  onChanged: controller.setCode,
                  errorLine: execution.errorLine,
                  activeLine: execution.activeLine,
                ),
              ],
            ),
          ),
        ];
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.exercise,
    required this.content,
    required this.solved,
  });

  final Exercise exercise;
  final AppContent content;
  final bool solved;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    return SectionCard(
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
              if (solved)
                Pill('Resuelto',
                    icon: Icons.check_circle_outline,
                    dense: true,
                    color: colors.success),
            ],
          ),
          const SizedBox(height: 12),
          Text(exercise.title, style: context.texts.titleMedium),
          const SizedBox(height: 8),
          Text(exercise.statement, style: context.texts.bodyMedium),
          if (exercise.concepts.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final concept in exercise.concepts)
                  Pill(content.skillLabel(concept), dense: true),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({
    required this.exercise,
    required this.session,
    required this.onHint,
    required this.onSolution,
  });

  final Exercise exercise;
  final ExerciseSessionState session;
  final VoidCallback onHint;
  final VoidCallback onSolution;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    final canRevealSolution = session.localAttempts >= 2 || session.solved;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Apoyo', icon: Icons.support_outlined),
          const SizedBox(height: 10),
          if (exercise.hint != null) ...[
            if (session.hintRevealed)
              InfoBanner(
                icon: Icons.tips_and_updates_outlined,
                color: colors.info,
                title: 'Pista',
                text: exercise.hint!,
              )
            else
              OutlinedButton.icon(
                onPressed: onHint,
                icon: const Icon(Icons.tips_and_updates_outlined, size: 18),
                label: const Text('Ver pista'),
              ),
            const SizedBox(height: 10),
          ],
          if (exercise.kind != ExerciseKind.trace &&
              exercise.kind != ExerciseKind.predict)
            session.solutionRevealed
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Solucion de referencia',
                          style: context.texts.labelMedium),
                      const SizedBox(height: 6),
                      CodeView(code: exercise.referenceSolution),
                    ],
                  )
                : OutlinedButton.icon(
                    onPressed: canRevealSolution ? onSolution : null,
                    icon: const Icon(Icons.lightbulb_outline, size: 18),
                    label: Text(canRevealSolution
                        ? 'Ver solucion de referencia'
                        : 'La solucion se abre tras dos intentos'),
                  ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.exercise,
    required this.session,
    required this.execution,
    required this.onRun,
    required this.onCheck,
    required this.ready,
  });

  final Exercise exercise;
  final ExerciseSessionState session;
  final ExecutionViewState execution;
  final VoidCallback onRun;
  final Future<void> Function() onCheck;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final isTrace = exercise.kind == ExerciseKind.trace;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onRun,
              icon: const Icon(Icons.play_arrow),
              label: Text(execution.hasRun ? 'Volver a ejecutar' : 'Ejecutar'),
            ),
          ),
          if (!isTrace) ...[
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: ready ? () => onCheck() : null,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Comprobar'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
