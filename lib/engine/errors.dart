/// Errores educativos del motor: siempre explican qué pasó y dónde.
library;

class EduError implements Exception {
  EduError(this.message, {this.line = 0, this.hint});

  final String message;
  final int line;
  final String? hint;

  @override
  String toString() => 'Línea $line: $message';
}

/// Error detectado al leer el programa (antes de ejecutar).
class EduParseError extends EduError {
  EduParseError(super.message, {super.line, super.hint});
}

/// Error detectado durante la ejecución.
class EduRuntimeError extends EduError {
  EduRuntimeError(super.message, {super.line, super.hint});
}

/// Señal interna: se alcanzó el límite de pasos (protección contra ciclos
/// infinitos). No es un error del estudiante, es una parada controlada.
class StepLimitSignal implements Exception {}

/// Señal interna de `retornar`.
class ReturnSignal implements Exception {
  ReturnSignal(this.value);

  final Object? value;
}
