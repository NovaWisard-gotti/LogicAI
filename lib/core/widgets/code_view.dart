import 'package:flutter/material.dart';

import '../../engine/lexer.dart';
import '../theme/app_theme.dart';

/// Resalta una línea de pseudocódigo.
///
/// El resaltado nunca es la única señal: la línea activa y la línea con error
/// se marcan además con icono, borde y número en negrita.
List<TextSpan> highlightLine(String line, LogicColors colors,
    {TextStyle? base}) {
  final style = base ?? kCodeTextStyle;
  var commentIndex = -1;
  var inString = false;
  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (c == '"') inString = !inString;
    if (!inString && c == '/' && i + 1 < line.length && line[i + 1] == '/') {
      commentIndex = i;
      break;
    }
  }
  final codePart = commentIndex >= 0 ? line.substring(0, commentIndex) : line;
  final commentPart = commentIndex >= 0 ? line.substring(commentIndex) : '';

  final spans = <TextSpan>[];
  try {
    final tokens = tokenize(codePart);
    var cursor = 0;
    for (final token in tokens) {
      if (token.type == TokenType.eof || token.type == TokenType.newline) {
        continue;
      }
      if (token.start > cursor) {
        spans.add(TextSpan(
            text: codePart.substring(cursor, token.start), style: style));
      }
      final text = codePart.substring(token.start, token.end);
      spans.add(TextSpan(
        text: text,
        style: style.copyWith(
          color: _colorFor(token, colors),
          fontWeight: token.type == TokenType.keyword ||
                  (token.type == TokenType.identifier &&
                      kSoftWords.contains(token.word.toLowerCase()))
              ? FontWeight.w700
              : FontWeight.w400,
        ),
      ));
      cursor = token.end;
    }
    if (cursor < codePart.length) {
      spans.add(TextSpan(text: codePart.substring(cursor), style: style));
    }
  } catch (_) {
    // Si la línea aún no es válida (el estudiante la está escribiendo) se
    // muestra sin resaltar, nunca invisible.
    spans.add(TextSpan(
        text: codePart, style: style.copyWith(color: colors.identifier)));
  }
  if (commentPart.isNotEmpty) {
    spans.add(TextSpan(
      text: commentPart,
      style: style.copyWith(
          color: colors.comment, fontStyle: FontStyle.italic),
    ));
  }
  if (spans.isEmpty) {
    spans.add(TextSpan(text: ' ', style: style));
  }
  return spans;
}

Color _colorFor(Token token, LogicColors colors) {
  switch (token.type) {
    case TokenType.keyword:
      return colors.keyword;
    case TokenType.number:
      return colors.number;
    case TokenType.text:
      return colors.text;
    case TokenType.symbol:
      return colors.operator;
    case TokenType.identifier:
      final word = token.word.toLowerCase();
      if (kSoftWords.contains(word)) return colors.keyword;
      if (kBuiltins.contains(word)) return colors.builtin;
      return colors.identifier;
    case TokenType.newline:
    case TokenType.eof:
      return colors.identifier;
  }
}

/// Visor de código con numeración, resaltado y marcadores de ejecución.
class CodeView extends StatelessWidget {
  const CodeView({
    super.key,
    required this.code,
    this.activeLine,
    this.errorLine,
    this.showLineNumbers = true,
    this.onTapLine,
    this.selectedLine,
    this.fontSize = 14.5,
    this.padding = const EdgeInsets.symmetric(vertical: 10),
  });

  final String code;
  final int? activeLine;
  final int? errorLine;
  final bool showLineNumbers;
  final ValueChanged<int>? onTapLine;
  final int? selectedLine;
  final double fontSize;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    final lines = code.split('\n');
    final style = kCodeTextStyle.copyWith(fontSize: fontSize);
    final gutterWidth = showLineNumbers ? 46.0 : 10.0;

    return Container(
      decoration: BoxDecoration(
        color: colors.codeBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < lines.length; i++)
                      _CodeLine(
                        number: i + 1,
                        text: lines[i],
                        style: style,
                        colors: colors,
                        gutterWidth: gutterWidth,
                        showLineNumbers: showLineNumbers,
                        isActive: activeLine == i + 1,
                        isError: errorLine == i + 1,
                        isSelected: selectedLine == i + 1,
                        onTap: onTapLine == null ? null : () => onTapLine!(i + 1),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CodeLine extends StatelessWidget {
  const _CodeLine({
    required this.number,
    required this.text,
    required this.style,
    required this.colors,
    required this.gutterWidth,
    required this.showLineNumbers,
    required this.isActive,
    required this.isError,
    required this.isSelected,
    this.onTap,
  });

  final int number;
  final String text;
  final TextStyle style;
  final LogicColors colors;
  final double gutterWidth;
  final bool showLineNumbers;
  final bool isActive;
  final bool isError;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color background = Colors.transparent;
    Color marker = Colors.transparent;
    IconData? icon;
    String? semantics;

    if (isError) {
      background = colors.errorLineBackground;
      marker = colors.errorLineBorder;
      icon = Icons.error_outline;
      semantics = 'Línea $number con error';
    } else if (isActive) {
      background = colors.activeLineBackground;
      marker = colors.activeLineBorder;
      icon = Icons.play_arrow_rounded;
      semantics = 'Línea $number en ejecución';
    } else if (isSelected) {
      background = colors.surfaceAlt;
      marker = colors.info;
      icon = Icons.edit_outlined;
      semantics = 'Línea $number seleccionada';
    }

    final content = Container(
      decoration: BoxDecoration(
        color: background,
        border: Border(left: BorderSide(color: marker, width: 3)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: gutterWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Icon(icon, size: 13, color: marker),
                  ),
                if (showLineNumbers)
                  Text(
                    '$number',
                    style: style.copyWith(
                      color: isActive || isError
                          ? marker
                          : colors.lineNumber,
                      fontWeight: isActive || isError
                          ? FontWeight.w800
                          : FontWeight.w500,
                      fontSize: style.fontSize! - 1.5,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text.rich(
            TextSpan(children: highlightLine(text, colors, base: style)),
            softWrap: false,
            maxLines: 1,
            overflow: TextOverflow.visible,
          ),
          const SizedBox(width: 16),
        ],
      ),
    );

    final wrapped = semantics == null
        ? content
        : Semantics(label: semantics, child: content);

    if (onTap == null) return wrapped;
    return InkWell(onTap: onTap, child: wrapped);
  }
}
