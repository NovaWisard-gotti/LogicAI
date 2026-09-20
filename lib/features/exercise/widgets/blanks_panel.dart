import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/code_view.dart';
import '../../../core/widgets/common.dart';
import '../../../data/models/content_models.dart';

/// Modo "Completa la logica": el estudiante elige la pieza que falta.
class BlanksPanel extends StatelessWidget {
  const BlanksPanel({
    super.key,
    required this.exercise,
    required this.choices,
    required this.onChoose,
    required this.showExplanations,
  });

  final Exercise exercise;
  final Map<String, String> choices;
  final void Function(String blankId, String option) onChoose;
  final bool showExplanations;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle('Completa la logica', icon: Icons.extension_outlined),
          const SizedBox(height: 4),
          Text(
            'Elige la pieza que falta y despues ejecuta el programa para '
            'comprobar tu razonamiento.',
            style: context.texts.bodySmall,
          ),
          const SizedBox(height: 12),
          CodeView(code: _preview()),
          const SizedBox(height: 14),
          for (final blank in exercise.blanks) ...[
            Row(
              children: [
                Icon(Icons.crop_square, size: 15, color: colors.accentOnSurface),
                const SizedBox(width: 6),
                Text('Hueco ${blank.id}', style: context.texts.labelMedium),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in blank.options)
                  _OptionChip(
                    label: option,
                    selected: choices[blank.id] == option,
                    onTap: () => onChoose(blank.id, option),
                  ),
              ],
            ),
            if (showExplanations && choices[blank.id] != null) ...[
              const SizedBox(height: 8),
              InfoBanner(
                icon: choices[blank.id] == blank.answer
                    ? Icons.check_circle_outline
                    : Icons.info_outline,
                color: choices[blank.id] == blank.answer
                    ? colors.success
                    : colors.warning,
                text: blank.explanation,
              ),
            ],
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  String _preview() {
    var code = exercise.code ?? '';
    for (final blank in exercise.blanks) {
      final choice = choices[blank.id];
      code = code.replaceAll('{{${blank.id}}}', choice ?? '____');
    }
    return code;
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    return Material(
      color: selected ? colors.memoryChanged : colors.surfaceAlt,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? colors.accentOnSurface : colors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                size: 16,
                color: selected ? colors.accentOnSurface : colors.lineNumber,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: kCodeTextStyle.copyWith(
                  fontSize: 13.5,
                  color: context.scheme.onSurface,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
