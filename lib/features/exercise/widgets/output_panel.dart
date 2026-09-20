import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../state/execution_controller.dart';

/// Salida producida por `mostrar` hasta el paso actual.
class OutputPanel extends StatelessWidget {
  const OutputPanel({super.key, required this.state, this.expected});

  final ExecutionViewState state;
  final List<String>? expected;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    final lines = state.hasRun ? state.visibleOutput : const <String>[];

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle('Salida del programa', icon: Icons.terminal_outlined),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.codeBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: lines.isEmpty
                ? Text(
                    state.hasRun
                        ? 'Sin salida hasta este paso.'
                        : 'Todavia no se ha ejecutado el programa.',
                    style: context.texts.bodySmall
                        ?.copyWith(color: colors.lineNumber),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < lines.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${i + 1}  ',
                                  style: kCodeTextStyle.copyWith(
                                    fontSize: 13,
                                    color: colors.lineNumber,
                                  ),
                                ),
                                Text(
                                  lines[i],
                                  style: kCodeTextStyle.copyWith(
                                    fontSize: 13.5,
                                    color: context.scheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
          if (expected != null && expected!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Salida esperada del ejercicio',
                style: context.texts.labelMedium),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final line in expected!)
                  Pill(line, dense: true, color: colors.info),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
