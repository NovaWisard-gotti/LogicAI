import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logicai/core/theme/app_theme.dart';

/// Luminancia relativa segun WCAG 2.1.
double _luminance(Color color) {
  double channel(double value) =>
      value <= 0.03928 ? value / 12.92 : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

double contrast(Color foreground, Color background) {
  final a = _luminance(foreground);
  final b = _luminance(background);
  final high = math.max(a, b);
  final low = math.min(a, b);
  return (high + 0.05) / (low + 0.05);
}

void main() {
  final themes = {
    'claro': AppTheme.light(),
    'oscuro': AppTheme.dark(),
  };

  group('Los dos temas estan completos', () {
    themes.forEach((name, theme) {
      test('$name · expone LogicColors y un ColorScheme coherente', () {
        final colors = theme.extension<LogicColors>();
        expect(colors, isNotNull, reason: name);
        expect(theme.useMaterial3, isTrue);
        expect(theme.colorScheme.brightness, theme.brightness);
      });
    });

    test('el tema claro y el oscuro no comparten paleta', () {
      final light = themes['claro']!.extension<LogicColors>()!;
      final dark = themes['oscuro']!.extension<LogicColors>()!;
      expect(light.codeBackground, isNot(dark.codeBackground));
      expect(light.keyword, isNot(dark.keyword));
      expect(light.accentOnSurface, isNot(dark.accentOnSurface));
    });
  });

  group('El codigo es legible en ambos temas', () {
    themes.forEach((name, theme) {
      final colors = theme.extension<LogicColors>()!;

      test('$name · los colores de sintaxis superan 4.5:1', () {
        final tokens = <String, Color>{
          'keyword': colors.keyword,
          'builtin': colors.builtin,
          'number': colors.number,
          'text': colors.text,
          'comment': colors.comment,
          'operator': colors.operator,
          'identifier': colors.identifier,
        };
        tokens.forEach((token, color) {
          expect(contrast(color, colors.codeBackground),
              greaterThanOrEqualTo(4.5),
              reason: '$name/$token');
        });
      });

      test('$name · el numero de linea se distingue del margen', () {
        expect(contrast(colors.lineNumber, colors.codeGutter),
            greaterThanOrEqualTo(3.0),
            reason: name);
      });

      test('$name · la linea activa y la de error mantienen el texto legible',
          () {
        expect(contrast(colors.identifier, colors.activeLineBackground),
            greaterThanOrEqualTo(4.5),
            reason: name);
        expect(contrast(colors.identifier, colors.errorLineBackground),
            greaterThanOrEqualTo(4.5),
            reason: name);
      });
    });
  });

  group('La interfaz es legible en ambos temas', () {
    themes.forEach((name, theme) {
      final colors = theme.extension<LogicColors>()!;
      final scheme = theme.colorScheme;

      test('$name · texto principal sobre superficies', () {
        expect(contrast(scheme.onSurface, scheme.surface),
            greaterThanOrEqualTo(4.5),
            reason: name);
        expect(contrast(scheme.onSurface, scheme.surfaceContainer),
            greaterThanOrEqualTo(4.5),
            reason: name);
        expect(contrast(scheme.onSurfaceVariant, scheme.surfaceContainer),
            greaterThanOrEqualTo(4.5),
            reason: name);
      });

      test('$name · el resalte de memoria no tapa el texto', () {
        expect(contrast(scheme.onSurface, colors.memoryChanged),
            greaterThanOrEqualTo(4.5),
            reason: name);
        expect(contrast(colors.accentOnSurface, colors.memoryChanged),
            greaterThanOrEqualTo(4.5),
            reason: name);
      });

      test('$name · los colores de estado se leen sobre la tarjeta', () {
        final states = <String, Color>{
          'success': colors.success,
          'danger': colors.danger,
          'warning': colors.warning,
          'info': colors.info,
          'accento': colors.accentOnSurface,
        };
        states.forEach((label, color) {
          expect(contrast(color, colors.surfaceAlt), greaterThanOrEqualTo(4.5),
              reason: '$name/$label');
          expect(contrast(color, scheme.surfaceContainer),
              greaterThanOrEqualTo(4.5),
              reason: '$name/$label');
        });
      });

      test('$name · el acento lima se lee sobre su color de texto', () {
        expect(contrast(scheme.onPrimary, scheme.primary),
            greaterThanOrEqualTo(4.5),
            reason: name);
      });
    });
  });

  group('El codigo usa siempre tipografia monoespaciada', () {
    test('kCodeTextStyle declara familia y respaldos', () {
      expect(kCodeTextStyle.fontFamily, 'monospace');
      expect(kCodeTextStyle.fontFamilyFallback, isNotEmpty);
    });
  });
}
