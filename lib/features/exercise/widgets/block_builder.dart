import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/code_view.dart';
import '../../../core/widgets/common.dart';
import '../../../data/models/content_models.dart';

/// Constructor de algoritmos: el estudiante ordena bloques logicos.
///
/// En movil, tocar para anadir y mover arriba/abajo resulta mas fiable que
/// depender de arrastrar y soltar dentro de una pantalla con desplazamiento,
/// asi que la interaccion se basa en toques y botones de mover.
class BlockBuilder extends StatelessWidget {
  const BlockBuilder({
    super.key,
    required this.exercise,
    required this.chosen,
    required this.onAdd,
    required this.onRemove,
    required this.onMove,
    required this.onClear,
  });

  final Exercise exercise;
  final List<String> chosen;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final void Function(int index, int delta) onMove;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    final byId = {for (final block in exercise.blocks) block.id: block};
    final available =
        exercise.blocks.where((b) => !chosen.contains(b.id)).toList();

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle('Constructor de algoritmos',
              icon: Icons.construction_outlined,
              trailing: chosen.isEmpty
                  ? null
                  : TextButton.icon(
                      onPressed: onClear,
                      icon: const Icon(Icons.layers_clear, size: 16),
                      label: const Text('Vaciar'),
                    )),
          const SizedBox(height: 4),
          Text(
            'Toca un bloque para anadirlo. Despues ordenalo: no todos los '
            'bloques disponibles forman parte de la solucion.',
            style: context.texts.bodySmall,
          ),
          const SizedBox(height: 12),
          Text('Mi algoritmo', style: context.texts.labelMedium),
          const SizedBox(height: 6),
          if (chosen.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                'Aun no has anadido ningun bloque.',
                textAlign: TextAlign.center,
                style: context.texts.bodySmall,
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: colors.codeBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  for (var i = 0; i < chosen.length; i++)
                    _ChosenBlock(
                      index: i,
                      total: chosen.length,
                      text: byId[chosen[i]]?.rendered ?? chosen[i],
                      onUp: i == 0 ? null : () => onMove(i, -1),
                      onDown:
                          i == chosen.length - 1 ? null : () => onMove(i, 1),
                      onRemove: () => onRemove(chosen[i]),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Text('Bloques disponibles', style: context.texts.labelMedium),
          const SizedBox(height: 6),
          if (available.isEmpty)
            Text('Has usado todos los bloques disponibles.',
                style: context.texts.bodySmall)
          else
            Column(
              children: [
                for (final block in available)
                  _AvailableBlock(
                    text: block.rendered,
                    onTap: () => onAdd(block.id),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ChosenBlock extends StatelessWidget {
  const _ChosenBlock({
    required this.index,
    required this.total,
    required this.text,
    required this.onUp,
    required this.onDown,
    required this.onRemove,
  });

  final int index;
  final int total;
  final String text;
  final VoidCallback? onUp;
  final VoidCallback? onDown;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${index + 1}',
              textAlign: TextAlign.right,
              style: kCodeTextStyle.copyWith(
                fontSize: 12.5,
                color: colors.lineNumber,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: RichText(
                text: TextSpan(
                  children: highlightLine(
                    text,
                    colors,
                    base: kCodeTextStyle.copyWith(fontSize: 13.5),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onUp,
            tooltip: 'Subir',
            icon: const Icon(Icons.keyboard_arrow_up, size: 20),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onDown,
            tooltip: 'Bajar',
            icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
            tooltip: 'Quitar',
            icon: Icon(Icons.close, size: 18, color: colors.danger),
          ),
        ],
      ),
    );
  }
}

class _AvailableBlock extends StatelessWidget {
  const _AvailableBlock({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline,
                    size: 17, color: colors.accentOnSurface),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: RichText(
                      text: TextSpan(
                        children: highlightLine(
                          text,
                          colors,
                          base: kCodeTextStyle.copyWith(fontSize: 13.5),
                        ),
                      ),
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
