import 'errors.dart';
import 'interpreter.dart';
import 'parser.dart';

export 'errors.dart';
export 'interpreter.dart';
export 'lexer.dart' show kBuiltins, kHardKeywords, kSoftWords;
export 'values.dart' show fmt, typeLabel;

/// Un caso de prueba educativo: entradas fijas y salida esperada.
class EngineTestCase {
  const EngineTestCase({
    required this.label,
    required this.inputs,
    required this.expected,
  });

  final String label;
  final List<Object?> inputs;
  final List<String> expected;
}

class TestCaseOutcome {
  const TestCaseOutcome({
    required this.testCase,
    required this.result,
  });

  final EngineTestCase testCase;
  final ExecutionResult result;

  List<String> get actual => result.output;

  bool get passed =>
      result.isOk && _sameOutput(result.output, testCase.expected);

  /// Índice de la primera línea de salida que difiere (-1 si coinciden).
  int get divergenceIndex {
    final expected = testCase.expected;
    final actual = result.output;
    final max = expected.length > actual.length ? expected.length : actual.length;
    for (var i = 0; i < max; i++) {
      final e = i < expected.length ? expected[i] : null;
      final a = i < actual.length ? actual[i] : null;
      if (e != a) return i;
    }
    return -1;
  }
}

class VerificationResult {
  const VerificationResult(this.outcomes);

  final List<TestCaseOutcome> outcomes;

  bool get passed => outcomes.isNotEmpty && outcomes.every((o) => o.passed);

  int get passedCount => outcomes.where((o) => o.passed).length;

  TestCaseOutcome get firstFailure =>
      outcomes.firstWhere((o) => !o.passed, orElse: () => outcomes.first);

  TestCaseOutcome get representative => passed ? outcomes.first : firstFailure;
}

bool _sameOutput(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].trim() != b[i].trim()) return false;
  }
  return true;
}

/// Ejecuta un programa y devuelve la traza completa.
///
/// Nunca lanza excepciones: cualquier problema se devuelve como un
/// [ExecutionResult] con estado de error y un mensaje educativo.
ExecutionResult runProgram(
  String source, {
  List<Object?> inputs = const [],
  int maxSteps = Interpreter.defaultMaxSteps,
}) {
  try {
    final program = parseProgram(source);
    return Interpreter(inputs: inputs, maxSteps: maxSteps).run(program);
  } on EduParseError catch (error) {
    return ExecutionResult.syntax(error);
  } on EduRuntimeError catch (error) {
    return ExecutionResult(
      steps: const [],
      output: const [],
      status: ExecStatus.runtimeError,
      message: error.message,
      errorLine: error.line,
      hint: error.hint,
    );
  }
}

/// Ejecuta el programa contra todos los casos de prueba del ejercicio.
VerificationResult verify(
  String source,
  List<EngineTestCase> cases, {
  int maxSteps = Interpreter.defaultMaxSteps,
}) {
  final outcomes = <TestCaseOutcome>[];
  for (final testCase in cases) {
    outcomes.add(TestCaseOutcome(
      testCase: testCase,
      result: runProgram(source,
          inputs: List<Object?>.from(testCase.inputs), maxSteps: maxSteps),
    ));
  }
  return VerificationResult(outcomes);
}

/// Mensaje educativo que explica por qué falló un caso, sin dar la solución.
String explainFailure(TestCaseOutcome outcome) {
  final result = outcome.result;
  switch (result.status) {
    case ExecStatus.syntaxError:
      return 'El programa no se pudo leer: ${result.message} '
          '(línea ${result.errorLine}).';
    case ExecStatus.runtimeError:
      return 'La ejecución se detuvo en la línea ${result.errorLine}: '
          '${result.message}';
    case ExecStatus.stepLimit:
      return result.message ?? 'La ejecución superó el límite de pasos.';
    case ExecStatus.ok:
      final index = outcome.divergenceIndex;
      if (index < 0) return 'El resultado coincide con el esperado.';
      final expected = index < outcome.testCase.expected.length
          ? outcome.testCase.expected[index]
          : '(nada más)';
      final actual =
          index < outcome.actual.length ? outcome.actual[index] : '(nada)';
      return 'La salida n.º ${index + 1} no coincide: se esperaba "$expected" '
          'y se obtuvo "$actual".';
  }
}
