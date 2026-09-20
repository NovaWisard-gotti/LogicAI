import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../data/models/content_models.dart';
import '../../../engine/logic_engine.dart';

/// Retroalimentacion explicativa: nunca dice solo "incorrecto".
///
/// Explica que ocurrio, en que paso, que variable estaba implicada y que
/// concepto conviene revisar, sin revelar la solucion.
class FeedbackPanel extends StatelessWidget {
  const FeedbackPanel({
    super.key,
    required this.exercise,
    required this.verification,
    required this.content,
  });

  final Exercise exercise;
  final VerificationResult verification;
  final AppContent content;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    final passed = verification.passed;
    final outcome = verification.representative;

    return SectionCard(
      color: passed
          ? colors.success.withValues(alpha: 0.10)
          : colors.warning.withValues(alpha: 0.10),
      borderColor: passed ? colors.success : colors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(passed ? Icons.verified_outlined : Icons.report_outlined,
                  color: passed ? colors.success : colors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  passed
                      ? 'Resuelto: la logica produce el resultado esperado'
                      : 'Todavia no: veamos que ocurrio',
                  style: context.texts.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            passed
                ? 'Se comprobaron ${verification.outcomes.length} '
                    '${verification.outcomes.length == 1 ? 'caso' : 'casos'} y '
                    'todos coinciden con la salida esperada.'
                : explainFailure(outcome),
            style: context.texts.bodyMedium,
          ),
          if (!passed) ...[
            const SizedBox(height: 12),
            ..._diagnosis(context, outcome),
            const SizedBox(height: 12),
            _ConceptsToReview(exercise: exercise, content: content),
          ],
          if (passed && exercise.focus != null) ...[
            const SizedBox(height: 10),
            InfoBanner(
              icon: Icons.lightbulb_outline,
              color: colors.accentOnSurface,
              title: 'Idea clave',
              text: exercise.focus!,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _diagnosis(BuildContext context, TestCaseOutcome outcome) {
    final colors = context.logic;
    final result = outcome.result;
    final steps = result.steps;
    final lastStep = steps.isEmpty ? null : steps.last;

    final items = <Widget>[];

    if (outcome.testCase.inputs.isNotEmpty) {
      items.add(_Line(
        icon: Icons.input,
        label: 'Caso comprobado',
        value: '${outcome.testCase.label} · entradas '
            '${outcome.testCase.inputs.join(', ')}',
      ));
    }

    if (result.stopLine > 0) {
      items.add(_Line(
        icon: Icons.my_location,
        label: 'Donde se detuvo',
        value: 'Linea ${result.stopLine}'
            '${steps.isEmpty ? '' : ' (paso ${steps.length} de ${steps.length})'}',
      ));
    }

    if (lastStep != null) {
      items.add(_Line(
        icon: Icons.play_arrow_outlined,
        label: 'Ultima instruccion ejecutada',
        value: lastStep.action,
        mono: true,
      ));
      final changed = lastStep.variables.where((v) => v.changed).toList();
      if (changed.isNotEmpty) {
        items.add(_Line(
          icon: Icons.bolt,
          label: 'Variable implicada',
          value: changed
              .map((v) => '${v.name} = ${v.value}')
              .join(' · '),
          mono: true,
        ));
      } else if (lastStep.variables.isNotEmpty) {
        items.add(_Line(
          icon: Icons.memory_outlined,
          label: 'Estado final de la memoria',
          value: lastStep.variables
              .map((v) => '${v.name} = ${v.value}')
              .join(' · '),
          mono: true,
        ));
      }
    }

    if (result.hint != null) {
      items.add(_Line(
        icon: Icons.tips_and_updates_outlined,
        label: 'Pista del motor',
        value: result.hint!,
      ));
    }

    if (result.status == ExecStatus.ok) {
      items.add(_Line(
        icon: Icons.compare_arrows,
        label: 'Esperado frente a obtenido',
        value: 'Esperado: ${outcome.testCase.expected.isEmpty ? '(sin salida)' : outcome.testCase.expected.join(' | ')}'
            '\nObtenido: ${outcome.actual.isEmpty ? '(sin salida)' : outcome.actual.join(' | ')}',
        mono: true,
      ));
    }

    items.add(Padding(
      padding: const EdgeInsets.only(top: 4),
      child: InfoBanner(
        icon: Icons.play_circle_outline,
        color: colors.info,
        text: 'Usa el trazador para recorrer el programa y localizar el paso '
            'exacto donde el estado deja de ser el que esperabas.',
      ),
    ));

    return items;
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: context.logic.accentOnSurface),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.texts.labelMedium),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: mono
                      ? kCodeTextStyle.copyWith(
                          fontSize: 13, color: context.scheme.onSurface)
                      : context.texts.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConceptsToReview extends StatelessWidget {
  const _ConceptsToReview({required this.exercise, required this.content});

  final Exercise exercise;
  final AppContent content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Conceptos que conviene revisar',
            style: context.texts.labelMedium),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final concept in exercise.concepts)
              Pill(content.skillLabel(concept),
                  icon: Icons.school_outlined, dense: true),
          ],
        ),
      ],
    );
  }
}

/// Modo "Que ocurrio": compara esperado y obtenido y senala el punto exacto
/// donde la ejecucion se separo de lo previsto.
class WhatHappenedPanel extends StatelessWidget {
  const WhatHappenedPanel({super.key, required this.outcome});

  final TestCaseOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    final expected = outcome.testCase.expected;
    final actual = outcome.actual;
    final divergence = outcome.divergenceIndex;
    final max = expected.length > actual.length ? expected.length : actual.length;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle('Que ocurrio', icon: Icons.fact_check_outlined),
          const SizedBox(height: 4),
          Text(
            'Depuracion por evidencia: compara linea a linea lo previsto con '
            'lo que realmente produjo el programa.',
            style: context.texts.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text('Esperado', style: context.texts.labelMedium),
              ),
              Expanded(
                child: Text('Obtenido', style: context.texts.labelMedium),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (max == 0)
            Text('El ejercicio no produce salida escrita.',
                style: context.texts.bodySmall)
          else
            for (var i = 0; i < max; i++)
              _ComparisonRow(
                expected: i < expected.length ? expected[i] : '(nada)',
                actual: i < actual.length ? actual[i] : '(nada)',
                diverging: i == divergence,
              ),
          if (divergence >= 0) ...[
            const SizedBox(height: 10),
            InfoBanner(
              icon: Icons.alt_route,
              color: colors.warning,
              title: 'Punto de divergencia',
              text: 'La diferencia empieza en la salida n.o ${divergence + 1}. '
                  'Retrocede el trazador hasta el paso que produce esa linea '
                  'y observa el estado justo antes.',
            ),
          ],
          if (outcome.result.stopLine > 0) ...[
            const SizedBox(height: 10),
            Pill('La ejecucion termino en la linea ${outcome.result.stopLine}',
                icon: Icons.stop_circle_outlined),
          ],
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.expected,
    required this.actual,
    required this.diverging,
  });

  final String expected;
  final String actual;
  final bool diverging;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    final style = kCodeTextStyle.copyWith(
      fontSize: 13,
      color: context.scheme.onSurface,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: diverging
            ? colors.warning.withValues(alpha: 0.14)
            : colors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: diverging ? colors.warning : colors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (diverging)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(Icons.priority_high, size: 15, color: colors.warning),
            ),
          Expanded(child: Text(expected, style: style)),
          const SizedBox(width: 8),
          Expanded(child: Text(actual, style: style)),
        ],
      ),
    );
  }
}
