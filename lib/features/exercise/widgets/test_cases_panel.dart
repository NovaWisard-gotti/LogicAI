import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../data/models/content_models.dart';
import '../../../engine/logic_engine.dart';

/// Casos de prueba del ejercicio.
///
/// Varios casos evitan que una respuesta acierte por casualidad: la logica
/// tiene que funcionar con entradas distintas, no solo con el ejemplo.
class TestCasesPanel extends StatelessWidget {
  const TestCasesPanel({
    super.key,
    required this.exercise,
    required this.verification,
    required this.onRunCase,
  });

  final Exercise exercise;
  final VerificationResult? verification;
  final void Function(ExerciseTest test) onRunCase;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    final tests = exercise.tests;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle('Casos de prueba', icon: Icons.checklist_rtl),
          const SizedBox(height: 4),
          Text(
            tests.length == 1
                ? 'Este ejercicio se comprueba con un caso.'
                : 'Este ejercicio se comprueba con ${tests.length} casos: la '
                    'logica debe funcionar con todos.',
            style: context.texts.bodySmall,
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < tests.length; i++)
            _TestRow(
              test: tests[i],
              outcome: verification != null && i < verification!.outcomes.length
                  ? verification!.outcomes[i]
                  : null,
              onRun: () => onRunCase(tests[i]),
            ),
          if (verification != null) ...[
            const SizedBox(height: 4),
            Pill(
              '${verification!.passedCount} de ${verification!.outcomes.length} casos correctos',
              icon: Icons.summarize_outlined,
              color: verification!.passed ? colors.success : colors.warning,
            ),
          ],
        ],
      ),
    );
  }
}

class _TestRow extends StatelessWidget {
  const _TestRow({
    required this.test,
    required this.outcome,
    required this.onRun,
  });

  final ExerciseTest test;
  final TestCaseOutcome? outcome;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    final passed = outcome?.passed;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: passed == null
              ? colors.border
              : (passed ? colors.success : colors.danger),
        ),
      ),
      child: Row(
        children: [
          Icon(
            passed == null
                ? Icons.radio_button_unchecked
                : (passed ? Icons.check_circle_outline : Icons.cancel_outlined),
            size: 18,
            color: passed == null
                ? colors.lineNumber
                : (passed ? colors.success : colors.danger),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(test.label, style: context.texts.labelMedium),
                const SizedBox(height: 2),
                Text(
                  test.inputs.isEmpty
                      ? 'Sin entradas · espera ${_join(test.expected)}'
                      : 'Entradas ${test.inputs.join(', ')} · espera '
                          '${_join(test.expected)}',
                  style: kCodeTextStyle.copyWith(
                    fontSize: 12.5,
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
                if (outcome != null && passed == false) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Obtenido: ${_join(outcome!.actual)}',
                    style: kCodeTextStyle.copyWith(
                      fontSize: 12.5,
                      color: colors.danger,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Trazar este caso',
            onPressed: onRun,
            icon: const Icon(Icons.play_circle_outline, size: 20),
          ),
        ],
      ),
    );
  }

  static String _join(List<String> values) =>
      values.isEmpty ? '(sin salida)' : values.join(' | ');
}
