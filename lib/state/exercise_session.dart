import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/content_models.dart';
import '../engine/logic_engine.dart';
import 'app_providers.dart';

/// Estado de trabajo del estudiante dentro de un ejercicio.
class ExerciseSessionState {
  const ExerciseSessionState({
    required this.code,
    this.blankChoices = const {},
    this.chosenBlocks = const [],
    this.predictionChoice,
    this.verification,
    this.solved = false,
    this.checked = false,
    this.hintRevealed = false,
    this.solutionRevealed = false,
    this.localAttempts = 0,
  });

  final String code;
  final Map<String, String> blankChoices;
  final List<String> chosenBlocks;
  final int? predictionChoice;
  final VerificationResult? verification;
  final bool solved;
  final bool checked;
  final bool hintRevealed;
  final bool solutionRevealed;
  final int localAttempts;

  ExerciseSessionState copyWith({
    String? code,
    Map<String, String>? blankChoices,
    List<String>? chosenBlocks,
    int? predictionChoice,
    VerificationResult? verification,
    bool? solved,
    bool? checked,
    bool? hintRevealed,
    bool? solutionRevealed,
    int? localAttempts,
    bool clearVerification = false,
  }) =>
      ExerciseSessionState(
        code: code ?? this.code,
        blankChoices: blankChoices ?? this.blankChoices,
        chosenBlocks: chosenBlocks ?? this.chosenBlocks,
        predictionChoice: predictionChoice ?? this.predictionChoice,
        verification:
            clearVerification ? null : (verification ?? this.verification),
        solved: solved ?? this.solved,
        checked: checked ?? this.checked,
        hintRevealed: hintRevealed ?? this.hintRevealed,
        solutionRevealed: solutionRevealed ?? this.solutionRevealed,
        localAttempts: localAttempts ?? this.localAttempts,
      );
}

class ExerciseSessionController extends StateNotifier<ExerciseSessionState> {
  ExerciseSessionController(this.exercise)
      : super(ExerciseSessionState(code: exercise.startingCode));

  final Exercise exercise;

  /// Programa que se va a ejecutar según el tipo de ejercicio.
  String get assembledCode {
    switch (exercise.kind) {
      case ExerciseKind.complete:
        var code = exercise.code ?? '';
        for (final blank in exercise.blanks) {
          final choice = state.blankChoices[blank.id];
          code = code.replaceAll('{{${blank.id}}}', choice ?? '____');
        }
        return code;
      case ExerciseKind.build:
        final byId = {for (final block in exercise.blocks) block.id: block};
        return state.chosenBlocks
            .map((id) => byId[id]?.rendered ?? '')
            .join('\n');
      case ExerciseKind.repair:
        return state.code;
      case ExerciseKind.trace:
      case ExerciseKind.predict:
        return exercise.code ?? '';
    }
  }

  bool get isReadyToCheck {
    switch (exercise.kind) {
      case ExerciseKind.complete:
        return exercise.blanks
            .every((blank) => state.blankChoices.containsKey(blank.id));
      case ExerciseKind.build:
        return state.chosenBlocks.isNotEmpty;
      case ExerciseKind.repair:
        return state.code.trim().isNotEmpty;
      case ExerciseKind.predict:
        return state.predictionChoice != null;
      case ExerciseKind.trace:
        return true;
    }
  }

  void setCode(String code) {
    state = state.copyWith(code: code, clearVerification: true, checked: false);
  }

  void chooseBlank(String blankId, String option) {
    final choices = Map<String, String>.from(state.blankChoices)
      ..[blankId] = option;
    state = state.copyWith(
        blankChoices: choices, clearVerification: true, checked: false);
  }

  void addBlock(String blockId) {
    if (state.chosenBlocks.contains(blockId)) return;
    state = state.copyWith(
      chosenBlocks: [...state.chosenBlocks, blockId],
      clearVerification: true,
      checked: false,
    );
  }

  void removeBlock(String blockId) {
    state = state.copyWith(
      chosenBlocks: state.chosenBlocks.where((id) => id != blockId).toList(),
      clearVerification: true,
      checked: false,
    );
  }

  void moveBlock(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= state.chosenBlocks.length) return;
    final blocks = [...state.chosenBlocks];
    final block = blocks.removeAt(index);
    blocks.insert(target, block);
    state = state.copyWith(
        chosenBlocks: blocks, clearVerification: true, checked: false);
  }

  void clearBlocks() {
    state = state.copyWith(
        chosenBlocks: const [], clearVerification: true, checked: false);
  }

  void choosePrediction(int index) {
    state = state.copyWith(
        predictionChoice: index, clearVerification: true, checked: false);
  }

  void revealHint() => state = state.copyWith(hintRevealed: true);

  void revealSolution() => state = state.copyWith(solutionRevealed: true);

  /// Comprueba la respuesta ejecutando todos los casos de prueba.
  /// Devuelve `true` si el ejercicio quedó resuelto.
  bool check() {
    if (exercise.kind == ExerciseKind.predict) {
      final correct = state.predictionChoice == exercise.question!.answer;
      state = state.copyWith(
        checked: true,
        solved: state.solved || correct,
        localAttempts: state.localAttempts + 1,
      );
      return correct;
    }
    final result = verify(assembledCode, exercise.engineCases);
    state = state.copyWith(
      verification: result,
      checked: true,
      solved: state.solved || result.passed,
      localAttempts: state.localAttempts + 1,
    );
    return result.passed;
  }

  /// Marca como completado un ejercicio de trazado tras recorrerlo entero.
  void markTraced() {
    if (state.solved) return;
    state = state.copyWith(solved: true, checked: true);
  }

  void resetWork() {
    state = ExerciseSessionState(
      code: exercise.startingCode,
      hintRevealed: state.hintRevealed,
    );
  }
}

/// Una sesión por ejercicio; se conserva mientras la app esté abierta para no
/// perder el trabajo al navegar.
final exerciseSessionProvider = StateNotifierProvider.family<
    ExerciseSessionController, ExerciseSessionState, Exercise>(
  (ref, exercise) => ExerciseSessionController(exercise),
);

/// Atajo para leer el contenido ya cargado dentro de las pantallas.
final loadedContentProvider = Provider<AppContent>((ref) {
  return ref.watch(contentProvider).requireValue;
});
