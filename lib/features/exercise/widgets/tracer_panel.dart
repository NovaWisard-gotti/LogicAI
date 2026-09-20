import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/code_view.dart';
import '../../../core/widgets/common.dart';
import '../../../engine/logic_engine.dart';
import '../../../state/execution_controller.dart';

/// Trazador de ejecucion: codigo resaltado + controles + descripcion del paso.
class TracerPanel extends StatelessWidget {
  const TracerPanel({
    super.key,
    required this.code,
    required this.state,
    required this.controller,
    this.title = 'Trazador de ejecucion',
  });

  final String code;
  final ExecutionViewState state;
  final ExecutionController controller;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    final step = state.currentStep;
    final total = state.totalSteps;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title, icon: Icons.play_circle_outline),
          const SizedBox(height: 12),
          CodeView(
            code: code,
            activeLine: state.activeLine,
            errorLine: state.errorLine,
          ),
          const SizedBox(height: 12),
          if (!state.hasRun)
            InfoBanner(
              icon: Icons.touch_app_outlined,
              color: colors.info,
              text: 'Ejecuta el programa para recorrerlo instruccion por '
                  'instruccion y observar como cambia la memoria.',
            )
          else ...[
            _StepHeader(state: state, step: step, total: total),
            const SizedBox(height: 10),
            _Controls(state: state, controller: controller),
            if (total > 1) ...[
              const SizedBox(height: 4),
              Slider(
                value: state.index.toDouble().clamp(0, (total - 1).toDouble()),
                min: 0,
                max: (total - 1).toDouble(),
                divisions: total > 1 ? total - 1 : null,
                label: 'Paso ${state.index + 1}',
                onChanged: (value) => controller.seek(value.round()),
              ),
            ],
            if (state.result!.status == ExecStatus.stepLimit)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: InfoBanner(
                  icon: Icons.all_inclusive,
                  color: colors.warning,
                  title: 'Ejecucion detenida',
                  text: state.result!.message ??
                      'El programa supero el limite de pasos.',
                ),
              ),
            if (state.result!.status == ExecStatus.syntaxError ||
                state.result!.status == ExecStatus.runtimeError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: InfoBanner(
                  icon: Icons.error_outline,
                  color: colors.danger,
                  title: state.result!.status == ExecStatus.syntaxError
                      ? 'No se pudo leer el programa'
                      : 'Error durante la ejecucion',
                  text: '${state.result!.message ?? 'Error'}'
                      '${state.result!.errorLine > 0 ? ' (linea ${state.result!.errorLine})' : ''}'
                      '${state.result!.hint != null ? '\n${state.result!.hint}' : ''}',
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.state,
    required this.step,
    required this.total,
  });

  final ExecutionViewState state;
  final TraceStep? step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    if (step == null) {
      return InfoBanner(
        icon: Icons.info_outline,
        color: colors.warning,
        text: 'El programa no produjo ningun paso ejecutable.',
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Pill('Paso ${state.index + 1} de $total',
                  icon: Icons.linear_scale, dense: true),
              Pill('Linea ${step!.line}',
                  icon: Icons.numbers, dense: true, color: colors.info),
              if (step!.scope != 'principal')
                Pill(step!.scope,
                    icon: Icons.functions,
                    dense: true,
                    color: colors.accentOnSurface),
              if (state.caseLabel != null)
                Pill(state.caseLabel!,
                    icon: Icons.label_outline, dense: true),
            ],
          ),
          const SizedBox(height: 8),
          Text(step!.action,
              style: kCodeTextStyle.copyWith(
                fontSize: 13.5,
                color: context.scheme.onSurface,
              )),
          const SizedBox(height: 6),
          Text(step!.note, style: context.texts.bodySmall),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.state, required this.controller});

  final ExecutionViewState state;
  final ExecutionController controller;

  @override
  Widget build(BuildContext context) {
    final hasSteps = state.totalSteps > 0;
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: hasSteps ? controller.restart : null,
          tooltip: 'Reiniciar',
          icon: const Icon(Icons.replay),
        ),
        const SizedBox(width: 6),
        IconButton.filledTonal(
          onPressed: hasSteps && !state.atStart ? controller.previous : null,
          tooltip: 'Paso anterior',
          icon: const Icon(Icons.chevron_left),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: FilledButton.icon(
            onPressed: hasSteps ? controller.togglePlay : null,
            icon: Icon(state.playing ? Icons.pause : Icons.play_arrow),
            label: Text(state.playing ? 'Pausar' : 'Automatico'),
          ),
        ),
        const SizedBox(width: 6),
        IconButton.filledTonal(
          onPressed: hasSteps && !state.atEnd ? controller.next : null,
          tooltip: 'Paso siguiente',
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
