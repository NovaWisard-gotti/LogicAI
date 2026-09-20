import 'package:flutter/material.dart';

/// Identidad visual de LogicAI.
///
/// Base: negro azulado y gris acero, blanco frío, y verde lima eléctrico
/// usado SOLO como acento (nunca como fondo dominante). La estética evoca
/// lógica, ejecución y depuración sin imitar literalmente un terminal.
class LogicPalette {
  const LogicPalette._();

  // Neutros fríos
  static const Color inkBlack = Color(0xFF0A0F15); // negro azulado
  static const Color ink = Color(0xFF111A23);
  static const Color inkSoft = Color(0xFF18242F);
  static const Color steel = Color(0xFF5B6E80); // gris acero
  static const Color steelLight = Color(0xFF8DA2B5);
  static const Color coolWhite = Color(0xFFEFF4F8); // blanco frío
  static const Color cloud = Color(0xFFDDE5EC);

  // Acento
  static const Color lime = Color(0xFFB4F02A); // verde lima eléctrico
  static const Color limeDeep = Color(0xFF3F6212); // versión legible sobre claro
  static const Color limeSoft = Color(0xFFE8FBBF);

  // Semánticos (se combinan siempre con icono o texto, nunca solo color)
  static const Color successDark = Color(0xFF52D39A);
  static const Color successLight = Color(0xFF15734B);
  static const Color errorDark = Color(0xFFFF8A80);
  static const Color errorLight = Color(0xFFB3261E);
  static const Color warnDark = Color(0xFFF2C14E);
  static const Color warnLight = Color(0xFF8A5B00);
  static const Color infoDark = Color(0xFF7EC8F2);
  static const Color infoLight = Color(0xFF0B5B8A);
}

/// Colores adicionales (editor, memoria, estados) inyectados en el ThemeData
/// para que cada pantalla use el mismo contraste verificado en ambos modos.
@immutable
class LogicColors extends ThemeExtension<LogicColors> {
  const LogicColors({
    required this.codeBackground,
    required this.codeGutter,
    required this.lineNumber,
    required this.activeLineBackground,
    required this.activeLineBorder,
    required this.errorLineBackground,
    required this.errorLineBorder,
    required this.keyword,
    required this.builtin,
    required this.number,
    required this.text,
    required this.comment,
    required this.operator,
    required this.identifier,
    required this.success,
    required this.danger,
    required this.warning,
    required this.info,
    required this.accentOnSurface,
    required this.memoryChanged,
    required this.surfaceAlt,
    required this.border,
  });

  final Color codeBackground;
  final Color codeGutter;
  final Color lineNumber;
  final Color activeLineBackground;
  final Color activeLineBorder;
  final Color errorLineBackground;
  final Color errorLineBorder;
  final Color keyword;
  final Color builtin;
  final Color number;
  final Color text;
  final Color comment;
  final Color operator;
  final Color identifier;
  final Color success;
  final Color danger;
  final Color warning;
  final Color info;

  /// Verde lima ajustado para que siempre sea legible sobre la superficie.
  final Color accentOnSurface;

  /// Fondo de resalte para el estado que acaba de cambiar (inspector de
  /// memoria, opcion elegida). Es un tinte, nunca un color saturado: el texto
  /// encima sigue siendo el de la superficie.
  final Color memoryChanged;
  final Color surfaceAlt;
  final Color border;

  @override
  LogicColors copyWith({
    Color? codeBackground,
    Color? codeGutter,
    Color? lineNumber,
    Color? activeLineBackground,
    Color? activeLineBorder,
    Color? errorLineBackground,
    Color? errorLineBorder,
    Color? keyword,
    Color? builtin,
    Color? number,
    Color? text,
    Color? comment,
    Color? operator,
    Color? identifier,
    Color? success,
    Color? danger,
    Color? warning,
    Color? info,
    Color? accentOnSurface,
    Color? memoryChanged,
    Color? surfaceAlt,
    Color? border,
  }) {
    return LogicColors(
      codeBackground: codeBackground ?? this.codeBackground,
      codeGutter: codeGutter ?? this.codeGutter,
      lineNumber: lineNumber ?? this.lineNumber,
      activeLineBackground: activeLineBackground ?? this.activeLineBackground,
      activeLineBorder: activeLineBorder ?? this.activeLineBorder,
      errorLineBackground: errorLineBackground ?? this.errorLineBackground,
      errorLineBorder: errorLineBorder ?? this.errorLineBorder,
      keyword: keyword ?? this.keyword,
      builtin: builtin ?? this.builtin,
      number: number ?? this.number,
      text: text ?? this.text,
      comment: comment ?? this.comment,
      operator: operator ?? this.operator,
      identifier: identifier ?? this.identifier,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      accentOnSurface: accentOnSurface ?? this.accentOnSurface,
      memoryChanged: memoryChanged ?? this.memoryChanged,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
    );
  }

  @override
  LogicColors lerp(ThemeExtension<LogicColors>? other, double t) {
    if (other is! LogicColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return LogicColors(
      codeBackground: mix(codeBackground, other.codeBackground),
      codeGutter: mix(codeGutter, other.codeGutter),
      lineNumber: mix(lineNumber, other.lineNumber),
      activeLineBackground: mix(activeLineBackground, other.activeLineBackground),
      activeLineBorder: mix(activeLineBorder, other.activeLineBorder),
      errorLineBackground: mix(errorLineBackground, other.errorLineBackground),
      errorLineBorder: mix(errorLineBorder, other.errorLineBorder),
      keyword: mix(keyword, other.keyword),
      builtin: mix(builtin, other.builtin),
      number: mix(number, other.number),
      text: mix(text, other.text),
      comment: mix(comment, other.comment),
      operator: mix(operator, other.operator),
      identifier: mix(identifier, other.identifier),
      success: mix(success, other.success),
      danger: mix(danger, other.danger),
      warning: mix(warning, other.warning),
      info: mix(info, other.info),
      accentOnSurface: mix(accentOnSurface, other.accentOnSurface),
      memoryChanged: mix(memoryChanged, other.memoryChanged),
      surfaceAlt: mix(surfaceAlt, other.surfaceAlt),
      border: mix(border, other.border),
    );
  }

  static const LogicColors dark = LogicColors(
    codeBackground: Color(0xFF0D141B),
    codeGutter: Color(0xFF141F29),
    lineNumber: Color(0xFF6D8093),
    activeLineBackground: Color(0xFF1E3313),
    activeLineBorder: LogicPalette.lime,
    errorLineBackground: Color(0xFF3A1A1A),
    errorLineBorder: Color(0xFFFF8A80),
    keyword: Color(0xFFBDF25F),
    builtin: Color(0xFF7EC8F2),
    number: Color(0xFFF2C14E),
    text: Color(0xFFFFB59B),
    comment: Color(0xFF7C8FA1),
    operator: Color(0xFFCBD9E5),
    identifier: Color(0xFFEFF4F8),
    success: LogicPalette.successDark,
    danger: LogicPalette.errorDark,
    warning: LogicPalette.warnDark,
    info: LogicPalette.infoDark,
    accentOnSurface: LogicPalette.lime,
    memoryChanged: Color(0xFF1E3313),
    surfaceAlt: Color(0xFF16222D),
    border: Color(0xFF26333F),
  );

  static const LogicColors light = LogicColors(
    codeBackground: Color(0xFFF3F6F9),
    codeGutter: Color(0xFFE6ECF2),
    lineNumber: Color(0xFF64798C),
    activeLineBackground: Color(0xFFE3F5C2),
    activeLineBorder: Color(0xFF4F7D12),
    errorLineBackground: Color(0xFFFBE3E1),
    errorLineBorder: Color(0xFFB3261E),
    keyword: Color(0xFF2F6F0E),
    builtin: Color(0xFF0B5B8A),
    number: Color(0xFF9A5400),
    text: Color(0xFFA32F5B),
    comment: Color(0xFF62717E),
    operator: Color(0xFF33414E),
    identifier: Color(0xFF16222D),
    success: LogicPalette.successLight,
    danger: LogicPalette.errorLight,
    warning: LogicPalette.warnLight,
    info: LogicPalette.infoLight,
    accentOnSurface: LogicPalette.limeDeep,
    memoryChanged: Color(0xFFE3F5C2),
    surfaceAlt: Color(0xFFEDF2F6),
    border: Color(0xFFC9D5DF),
  );
}

/// Tipografías: el código siempre en monoespaciada con respaldos seguros.
const List<String> kMonoFallback = <String>[
  'RobotoMono',
  'DroidSansMono',
  'Courier New',
  'monospace',
];

const TextStyle kCodeTextStyle = TextStyle(
  fontFamily: 'monospace',
  fontFamilyFallback: kMonoFallback,
  fontSize: 14.5,
  height: 1.45,
  letterSpacing: 0.2,
);

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final extra = isDark ? LogicColors.dark : LogicColors.light;

    final scheme = isDark
        ? const ColorScheme(
            brightness: Brightness.dark,
            primary: LogicPalette.lime,
            onPrimary: Color(0xFF16240A),
            primaryContainer: Color(0xFF2C4610),
            onPrimaryContainer: Color(0xFFE4FFB0),
            secondary: LogicPalette.steelLight,
            onSecondary: Color(0xFF0A0F15),
            secondaryContainer: Color(0xFF26333F),
            onSecondaryContainer: LogicPalette.coolWhite,
            tertiary: LogicPalette.infoDark,
            onTertiary: Color(0xFF07202E),
            error: Color(0xFFFF8A80),
            onError: Color(0xFF3A0B08),
            errorContainer: Color(0xFF5A1C18),
            onErrorContainer: Color(0xFFFFD9D4),
            surface: LogicPalette.ink,
            onSurface: LogicPalette.coolWhite,
            surfaceContainerLowest: LogicPalette.inkBlack,
            surfaceContainerLow: Color(0xFF0E1720),
            surfaceContainer: Color(0xFF16222D),
            surfaceContainerHigh: Color(0xFF1C2A36),
            surfaceContainerHighest: Color(0xFF223140),
            onSurfaceVariant: Color(0xFFB4C4D2),
            outline: Color(0xFF3C4C5A),
            outlineVariant: Color(0xFF26333F),
            inverseSurface: LogicPalette.coolWhite,
            onInverseSurface: LogicPalette.ink,
            inversePrimary: LogicPalette.limeDeep,
            shadow: Colors.black,
            scrim: Colors.black,
          )
        : const ColorScheme(
            brightness: Brightness.light,
            primary: Color(0xFF3F6212),
            onPrimary: Colors.white,
            primaryContainer: Color(0xFFDCF7A6),
            onPrimaryContainer: Color(0xFF1B2D06),
            secondary: Color(0xFF41566A),
            onSecondary: Colors.white,
            secondaryContainer: Color(0xFFDCE6EF),
            onSecondaryContainer: Color(0xFF16222D),
            tertiary: Color(0xFF0B5B8A),
            onTertiary: Colors.white,
            error: Color(0xFFB3261E),
            onError: Colors.white,
            errorContainer: Color(0xFFFBDAD6),
            onErrorContainer: Color(0xFF410E0B),
            surface: Color(0xFFFAFCFE),
            onSurface: Color(0xFF16222D),
            surfaceContainerLowest: Colors.white,
            surfaceContainerLow: Color(0xFFF5F8FB),
            surfaceContainer: Color(0xFFEDF2F6),
            surfaceContainerHigh: Color(0xFFE6ECF2),
            surfaceContainerHighest: Color(0xFFDEE6ED),
            onSurfaceVariant: Color(0xFF41566A),
            outline: Color(0xFF7D8D9C),
            outlineVariant: Color(0xFFC9D5DF),
            inverseSurface: Color(0xFF16222D),
            onInverseSurface: Color(0xFFEFF4F8),
            inversePrimary: LogicPalette.lime,
            shadow: Colors.black,
            scrim: Colors.black,
          );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor:
          isDark ? LogicPalette.inkBlack : const Color(0xFFF7FAFC),
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[extra],
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? LogicPalette.inkBlack : const Color(0xFFF7FAFC),
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: extra.border),
        ),
      ),
      dividerTheme: DividerThemeData(color: extra.border, space: 1, thickness: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF0E1720) : Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: isDark
            ? const Color(0xFF2C4610)
            : const Color(0xFFDCF7A6),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(
          base.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 23,
            color: selected
                ? (isDark ? LogicPalette.lime : const Color(0xFF2F6F0E))
                : scheme.onSurfaceVariant,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: extra.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: extra.accentOnSurface,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        side: BorderSide(color: extra.border),
        labelStyle: base.textTheme.labelMedium
            ?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: extra.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: extra.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: extra.accentOnSurface, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF223140) : const Color(0xFF16222D),
        contentTextStyle: const TextStyle(
            color: LogicPalette.coolWhite, fontWeight: FontWeight.w600),
        actionTextColor: LogicPalette.lime,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: extra.accentOnSurface,
        thumbColor: extra.accentOnSurface,
        inactiveTrackColor: extra.border,
        overlayColor: extra.accentOnSurface.withValues(alpha: 0.15),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: extra.accentOnSurface,
        linearTrackColor: extra.border,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
    );
  }
}

extension LogicColorsX on BuildContext {
  LogicColors get logic => Theme.of(this).extension<LogicColors>()!;

  ColorScheme get scheme => Theme.of(this).colorScheme;

  TextTheme get texts => Theme.of(this).textTheme;
}
