import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'code_view.dart';

/// Editor de pseudocódigo pensado para pantallas pequeñas.
///
/// En lugar de un editor libre difícil de usar en móvil, el estudiante toca
/// la línea que quiere modificar y la edita en su sitio; también puede
/// insertar, borrar y mover líneas.
class LineCodeEditor extends StatefulWidget {
  const LineCodeEditor({
    super.key,
    required this.code,
    required this.onChanged,
    this.errorLine,
    this.activeLine,
    this.enabled = true,
  });

  final String code;
  final ValueChanged<String> onChanged;
  final int? errorLine;
  final int? activeLine;
  final bool enabled;

  @override
  State<LineCodeEditor> createState() => _LineCodeEditorState();
}

class _LineCodeEditorState extends State<LineCodeEditor> {
  late List<String> _lines = widget.code.split('\n');
  int? _selected;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void didUpdateWidget(covariant LineCodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.code != oldWidget.code && widget.code != _lines.join('\n')) {
      setState(() {
        _lines = widget.code.split('\n');
        if (_selected != null && _selected! >= _lines.length) _selected = null;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(_lines.join('\n'));

  void _select(int index) {
    if (!widget.enabled) return;
    setState(() {
      _selected = index;
      _controller.text = _lines[index];
      _controller.selection =
          TextSelection.collapsed(offset: _controller.text.length);
    });
    _focusNode.requestFocus();
  }

  void _updateSelected(String value) {
    if (_selected == null) return;
    _lines[_selected!] = value;
    _emit();
    setState(() {});
  }

  void _insertBelow() {
    final index = _selected ?? _lines.length - 1;
    final indent = RegExp(r'^\s*').stringMatch(_lines[index]) ?? '';
    setState(() {
      _lines.insert(index + 1, indent);
      _selected = index + 1;
      _controller.text = indent;
      _controller.selection =
          TextSelection.collapsed(offset: _controller.text.length);
    });
    _emit();
    _focusNode.requestFocus();
  }

  void _deleteSelected() {
    if (_selected == null || _lines.length <= 1) return;
    setState(() {
      _lines.removeAt(_selected!);
      _selected = null;
    });
    _emit();
  }

  void _move(int delta) {
    if (_selected == null) return;
    final target = _selected! + delta;
    if (target < 0 || target >= _lines.length) return;
    setState(() {
      final line = _lines.removeAt(_selected!);
      _lines.insert(target, line);
      _selected = target;
    });
    _emit();
  }

  void _insertToken(String token) {
    if (_selected == null) return;
    final selection = _controller.selection;
    final text = _controller.text;
    final offset = selection.isValid ? selection.end : text.length;
    final updated = text.replaceRange(offset, offset, token);
    _controller.text = updated;
    _controller.selection =
        TextSelection.collapsed(offset: offset + token.length);
    _updateSelected(updated);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    final scheme = context.scheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.codeBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < _lines.length; i++)
                _EditableLine(
                  number: i + 1,
                  text: _lines[i],
                  colors: colors,
                  isSelected: _selected == i,
                  isError: widget.errorLine == i + 1,
                  isActive: widget.activeLine == i + 1,
                  enabled: widget.enabled,
                  controller: _controller,
                  focusNode: _focusNode,
                  onTap: () => _select(i),
                  onChanged: _updateSelected,
                  onSubmitted: (_) => _insertBelow(),
                ),
            ],
          ),
        ),
        if (widget.enabled) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final token in const [
                  '=', '==', '<=', '>=', '<', '>', '+', '-', '*', 'mod', '"'
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(token,
                          style: kCodeTextStyle.copyWith(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      visualDensity: VisualDensity.compact,
                      onPressed:
                          _selected == null ? null : () => _insertToken(token),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _EditorAction(
                icon: Icons.add,
                label: 'Línea',
                onTap: _insertBelow,
              ),
              _EditorAction(
                icon: Icons.arrow_upward,
                label: 'Subir',
                onTap: _selected == null ? null : () => _move(-1),
              ),
              _EditorAction(
                icon: Icons.arrow_downward,
                label: 'Bajar',
                onTap: _selected == null ? null : () => _move(1),
              ),
              _EditorAction(
                icon: Icons.delete_outline,
                label: 'Borrar',
                danger: true,
                onTap: _selected == null || _lines.length <= 1
                    ? null
                    : _deleteSelected,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _selected == null
                ? 'Toca una línea para editarla.'
                : 'Editando la línea ${_selected! + 1}.',
            style: context.texts.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _EditableLine extends StatelessWidget {
  const _EditableLine({
    required this.number,
    required this.text,
    required this.colors,
    required this.isSelected,
    required this.isError,
    required this.isActive,
    required this.enabled,
    required this.controller,
    required this.focusNode,
    required this.onTap,
    required this.onChanged,
    required this.onSubmitted,
  });

  final int number;
  final String text;
  final LogicColors colors;
  final bool isSelected;
  final bool isError;
  final bool isActive;
  final bool enabled;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onTap;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    Color background = Colors.transparent;
    Color marker = Colors.transparent;
    IconData? icon;
    if (isError) {
      background = colors.errorLineBackground;
      marker = colors.errorLineBorder;
      icon = Icons.error_outline;
    } else if (isActive) {
      background = colors.activeLineBackground;
      marker = colors.activeLineBorder;
      icon = Icons.play_arrow_rounded;
    } else if (isSelected) {
      background = colors.surfaceAlt;
      marker = colors.info;
      icon = Icons.edit_outlined;
    }

    final style = kCodeTextStyle.copyWith(fontSize: 14.5);

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: background,
          border: Border(left: BorderSide(color: marker, width: 3)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 46,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (icon != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: Icon(icon, size: 13, color: marker),
                    ),
                  Text('$number',
                      style: style.copyWith(
                        fontSize: 13,
                        color: isSelected || isError || isActive
                            ? marker
                            : colors.lineNumber,
                        fontWeight: isSelected || isError || isActive
                            ? FontWeight.w800
                            : FontWeight.w500,
                      )),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: isSelected
                  ? TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: style.copyWith(color: colors.identifier),
                      cursorColor: colors.accentOnSurface,
                      maxLines: 1,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                      ),
                      onChanged: onChanged,
                      onSubmitted: onSubmitted,
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text.rich(
                          TextSpan(
                              children:
                                  highlightLine(text, colors, base: style)),
                          softWrap: false,
                          maxLines: 1,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _EditorAction extends StatelessWidget {
  const _EditorAction({
    required this.icon,
    required this.label,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            foregroundColor: danger ? colors.danger : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
