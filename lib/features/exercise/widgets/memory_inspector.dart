import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../engine/logic_engine.dart';
import '../../../state/execution_controller.dart';

/// Inspector de memoria: abstraccion educativa del estado del programa.
///
/// Muestra nombre, tipo educativo, valor actual y, cuando corresponde, el
/// cambio producido en el paso actual con la forma `3 -> 4`.
class MemoryInspector extends StatelessWidget {
  const MemoryInspector({super.key, required this.state});

  final ExecutionViewState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    final step = state.currentStep;
    final previous =
        state.index > 0 && state.steps.length > state.index
            ? state.steps[state.index - 1]
            : null;

    final variables = step?.variables ?? const <VarView>[];

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle('Inspector de memoria', icon: Icons.memory_outlined),
          const SizedBox(height: 4),
          Text(
            'Representacion educativa de las variables vivas en este paso.',
            style: context.texts.bodySmall,
          ),
          const SizedBox(height: 12),
          if (!state.hasRun)
            InfoBanner(
              icon: Icons.visibility_outlined,
              color: colors.info,
              text: 'Al ejecutar veras aqui el valor de cada variable en el '
                  'momento exacto en que cambia.',
            )
          else if (variables.isEmpty)
            InfoBanner(
              icon: Icons.inbox_outlined,
              color: colors.warning,
              text: 'Todavia no existe ninguna variable en este punto del '
                  'programa.',
            )
          else
            Column(
              children: [
                for (final variable in variables)
                  _VariableRow(
                    variable: variable,
                    previousValue: _previousValue(previous, variable),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  String? _previousValue(TraceStep? previous, VarView variable) {
    if (previous == null) return null;
    for (final old in previous.variables) {
      if (old.scope == variable.scope && old.name == variable.name) {
        return old.value == variable.value ? null : old.value;
      }
    }
    return null;
  }
}

class _VariableRow extends StatelessWidget {
  const _VariableRow({required this.variable, required this.previousValue});

  final VarView variable;
  final String? previousValue;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    final changed = variable.changed;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: changed ? colors.memoryChanged : colors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: changed ? colors.accentOnSurface : colors.border,
          width: changed ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                changed ? Icons.bolt : Icons.circle_outlined,
                size: 16,
                color: changed ? colors.accentOnSurface : colors.lineNumber,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  variable.name,
                  style: kCodeTextStyle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.scheme.onSurface,
                  ),
                ),
              ),
              Pill(variable.type, dense: true),
              if (variable.scope != 'principal') ...[
                const SizedBox(width: 6),
                Pill(variable.scope, dense: true, color: colors.info),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (previousValue != null) ...[
                Flexible(
                  child: Text(
                    previousValue!,
                    style: kCodeTextStyle.copyWith(
                      fontSize: 13.5,
                      color: colors.lineNumber,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_right_alt,
                      size: 18, color: colors.accentOnSurface),
                ),
              ],
              Flexible(
                child: Text(
                  variable.value,
                  style: kCodeTextStyle.copyWith(
                    fontSize: 14,
                    fontWeight: changed ? FontWeight.w700 : FontWeight.w500,
                    color: changed
                        ? colors.accentOnSurface
                        : context.scheme.onSurface,
                  ),
                ),
              ),
              if (changed) ...[
                const SizedBox(width: 8),
                Text('cambio aqui',
                    style: context.texts.labelSmall
                        ?.copyWith(color: colors.accentOnSurface)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
