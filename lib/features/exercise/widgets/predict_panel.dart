import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../data/models/content_models.dart';

/// Predictor de ejecucion: mecanica secundaria. Tras responder, el estudiante
/// puede ejecutar el programa paso a paso para comprobar su prediccion.
class PredictPanel extends StatelessWidget {
  const PredictPanel({
    super.key,
    required this.question,
    required this.choice,
    required this.checked,
    required this.onChoose,
  });

  final PredictQuestion question;
  final int? choice;
  final bool checked;
  final ValueChanged<int> onChoose;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle('Predice antes de ejecutar',
              icon: Icons.psychology_alt_outlined),
          const SizedBox(height: 8),
          Text(question.prompt, style: context.texts.bodyMedium),
          const SizedBox(height: 12),
          for (var i = 0; i < question.options.length; i++)
            _Option(
              text: question.options[i],
              selected: choice == i,
              state: !checked
                  ? _OptionState.neutral
                  : i == question.answer
                      ? _OptionState.correct
                      : (choice == i ? _OptionState.wrong : _OptionState.neutral),
              onTap: () => onChoose(i),
            ),
          if (checked) ...[
            const SizedBox(height: 8),
            InfoBanner(
              icon: choice == question.answer
                  ? Icons.check_circle_outline
                  : Icons.lightbulb_outline,
              color: choice == question.answer ? colors.success : colors.warning,
              title: choice == question.answer
                  ? 'Prediccion correcta'
                  : 'Prediccion distinta al resultado real',
              text: question.explanation,
            ),
            const SizedBox(height: 8),
            Text(
              'Ejecuta ahora el programa paso a paso y observa en que momento '
              'se decide ese resultado.',
              style: context.texts.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

enum _OptionState { neutral, correct, wrong }

class _Option extends StatelessWidget {
  const _Option({
    required this.text,
    required this.selected,
    required this.state,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    final (border, icon, iconColor) = switch (state) {
      _OptionState.correct => (
          colors.success,
          Icons.check_circle,
          colors.success,
        ),
      _OptionState.wrong => (colors.danger, Icons.cancel, colors.danger),
      _OptionState.neutral => (
          selected ? colors.accentOnSurface : colors.border,
          selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          selected ? colors.accentOnSurface : colors.lineNumber,
        ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? colors.memoryChanged : colors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: border,
                width: state == _OptionState.neutral && !selected ? 1 : 1.6,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: kCodeTextStyle.copyWith(
                      fontSize: 13.5,
                      color: context.scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
