import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/code_view.dart';
import '../../../core/widgets/common.dart';
import '../../../data/models/content_models.dart';
import '../../../engine/logic_engine.dart';

/// Comparacion "mi solucion" frente a la "solucion de referencia".
///
/// Nunca declara incorrecta una solucion distinta si produce el resultado
/// correcto dentro del alcance del ejercicio.
class ComparisonPanel extends StatelessWidget {
  const ComparisonPanel({
    super.key,
    required this.exercise,
    required this.myCode,
  });

  final Exercise exercise;
  final String myCode;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    final reference = exercise.referenceSolution;
    final mine = _measure(myCode, exercise.engineCases);
    final theirs = _measure(reference, exercise.engineCases);
    final identical = _normalize(myCode) == _normalize(reference);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle('Comparar con la solucion de referencia',
              icon: Icons.compare_outlined),
          const SizedBox(height: 4),
          Text(
            identical
                ? 'Tu solucion coincide con la de referencia.'
                : 'Tu solucion es distinta a la de referencia. Si ambas '
                    'producen el resultado correcto, ambas son validas: lo '
                    'que cambia es el camino.',
            style: context.texts.bodySmall,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text('Indicador', style: context.texts.labelMedium),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Mia',
                      textAlign: TextAlign.end,
                      style: context.texts.labelMedium),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Referencia',
                      textAlign: TextAlign.end,
                      style: context.texts.labelMedium),
                ),
              ],
            ),
          ),
          _MetricRow(
            label: 'Lineas con instrucciones',
            mine: '${mine.lines}',
            theirs: '${theirs.lines}',
          ),
          _MetricRow(
            label: 'Pasos ejecutados',
            mine: '${mine.steps}',
            theirs: '${theirs.steps}',
          ),
          _MetricRow(
            label: 'Decisiones (si)',
            mine: '${mine.conditionals}',
            theirs: '${theirs.conditionals}',
          ),
          _MetricRow(
            label: 'Ciclos (mientras / para)',
            mine: '${mine.loops}',
            theirs: '${theirs.loops}',
          ),
          _MetricRow(
            label: 'Funciones declaradas',
            mine: '${mine.functions}',
            theirs: '${theirs.functions}',
          ),
          _MetricRow(
            label: 'Resultado correcto',
            mine: mine.correct ? 'si' : 'no',
            theirs: theirs.correct ? 'si' : 'no',
          ),
          const SizedBox(height: 12),
          if (mine.correct && !identical)
            InfoBanner(
              icon: Icons.insights_outlined,
              color: colors.info,
              text: mine.steps == theirs.steps
                  ? 'Ambas soluciones recorren el mismo numero de pasos.'
                  : mine.steps < theirs.steps
                      ? 'Tu solucion llega al mismo resultado en '
                          '${theirs.steps - mine.steps} pasos menos.'
                      : 'La referencia llega al mismo resultado en '
                          '${mine.steps - theirs.steps} pasos menos. '
                          'Compara la estructura para ver por que.',
            ),
          const SizedBox(height: 12),
          Text('Solucion de referencia', style: context.texts.labelMedium),
          const SizedBox(height: 6),
          CodeView(code: reference),
          const SizedBox(height: 12),
          Text('Mi solucion', style: context.texts.labelMedium),
          const SizedBox(height: 6),
          CodeView(code: myCode.trim().isEmpty ? '(sin codigo)' : myCode),
        ],
      ),
    );
  }

  static String _normalize(String code) => code
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .join('\n');

  static _Measurement _measure(String code, List<EngineTestCase> cases) {
    final lines = _normalize(code).split('\n').where((l) => l.isNotEmpty);
    var conditionals = 0;
    var loops = 0;
    var functions = 0;
    for (final line in lines) {
      final words = line.toLowerCase().split(RegExp(r'[^a-z_]+'));
      if (words.contains('si')) conditionals++;
      if (words.contains('mientras') || words.contains('para')) loops++;
      if (words.contains('funcion')) functions++;
    }
    final verification = verify(code, cases);
    final steps = verification.outcomes.isEmpty
        ? 0
        : verification.outcomes.first.result.steps.length;
    return _Measurement(
      lines: lines.length,
      steps: steps,
      conditionals: conditionals,
      loops: loops,
      functions: functions,
      correct: verification.passed,
    );
  }
}

class _Measurement {
  const _Measurement({
    required this.lines,
    required this.steps,
    required this.conditionals,
    required this.loops,
    required this.functions,
    required this.correct,
  });

  final int lines;
  final int steps;
  final int conditionals;
  final int loops;
  final int functions;
  final bool correct;
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.mine,
    required this.theirs,
  });

  final String label;
  final String mine;
  final String theirs;

  @override
  Widget build(BuildContext context) {
    final different = mine != theirs;
    final colors = context.logic;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text(label, style: context.texts.bodySmall)),
          Expanded(
            flex: 2,
            child: Text(
              mine,
              textAlign: TextAlign.end,
              style: context.texts.bodyMedium?.copyWith(
                fontWeight: different ? FontWeight.w700 : FontWeight.w500,
                color: different
                    ? colors.accentOnSurface
                    : context.scheme.onSurface,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              theirs,
              textAlign: TextAlign.end,
              style: context.texts.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
