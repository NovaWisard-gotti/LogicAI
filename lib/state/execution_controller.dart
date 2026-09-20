import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/logic_engine.dart';

/// Estado del trazador: traza completa + posición actual.
class ExecutionViewState {
  const ExecutionViewState({
    this.result,
    this.index = 0,
    this.playing = false,
    this.source = '',
    this.caseLabel,
  });

  final ExecutionResult? result;
  final int index;
  final bool playing;
  final String source;
  final String? caseLabel;

  bool get hasRun => result != null;

  List<TraceStep> get steps => result?.steps ?? const [];

  TraceStep? get currentStep =>
      steps.isEmpty ? null : steps[index.clamp(0, steps.length - 1)];

  int get totalSteps => steps.length;

  bool get atStart => index <= 0;

  bool get atEnd => steps.isEmpty || index >= steps.length - 1;

  /// Línea que se resalta en el editor.
  int? get activeLine => currentStep?.line;

  int? get errorLine {
    final result = this.result;
    if (result == null) return null;
    if (result.status == ExecStatus.runtimeError ||
        result.status == ExecStatus.syntaxError) {
      return result.errorLine == 0 ? null : result.errorLine;
    }
    if (result.status == ExecStatus.stepLimit && atEnd) {
      return result.errorLine == 0 ? null : result.errorLine;
    }
    return null;
  }

  /// Salida visible en el paso actual: cada paso guarda la instantánea de la
  /// salida justo después de ejecutarse, así que crece al avanzar.
  List<String> get visibleOutput {
    final step = currentStep;
    if (step == null) return result?.output ?? const [];
    if (atEnd) return result?.output ?? step.output;
    return step.output;
  }

  ExecutionViewState copyWith({
    ExecutionResult? result,
    int? index,
    bool? playing,
    String? source,
    String? caseLabel,
    bool clearResult = false,
  }) =>
      ExecutionViewState(
        result: clearResult ? null : (result ?? this.result),
        index: index ?? this.index,
        playing: playing ?? this.playing,
        source: source ?? this.source,
        caseLabel: caseLabel ?? this.caseLabel,
      );
}

class ExecutionController extends StateNotifier<ExecutionViewState> {
  ExecutionController() : super(const ExecutionViewState());

  Timer? _timer;

  /// Ejecuta el programa completo y deja el trazador en el primer paso.
  ExecutionResult run(
    String source, {
    List<Object?> inputs = const [],
    String? caseLabel,
    bool jumpToEnd = false,
  }) {
    _stopTimer();
    final result = runProgram(source, inputs: inputs);
    state = ExecutionViewState(
      result: result,
      index: jumpToEnd && result.steps.isNotEmpty ? result.steps.length - 1 : 0,
      playing: false,
      source: source,
      caseLabel: caseLabel,
    );
    return result;
  }

  void next() {
    final steps = state.steps;
    if (steps.isEmpty) return;
    if (state.index >= steps.length - 1) {
      _stopTimer();
      state = state.copyWith(playing: false);
      return;
    }
    state = state.copyWith(index: state.index + 1);
  }

  void previous() {
    if (state.index <= 0) return;
    _stopTimer();
    state = state.copyWith(index: state.index - 1, playing: false);
  }

  void seek(int index) {
    if (state.steps.isEmpty) return;
    _stopTimer();
    state = state.copyWith(
      index: index.clamp(0, state.steps.length - 1),
      playing: false,
    );
  }

  void restart() {
    _stopTimer();
    state = state.copyWith(index: 0, playing: false);
  }

  void togglePlay() {
    if (state.playing) {
      _stopTimer();
      state = state.copyWith(playing: false);
      return;
    }
    if (state.steps.isEmpty) return;
    if (state.atEnd) state = state.copyWith(index: 0);
    state = state.copyWith(playing: true);
    _timer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (state.atEnd) {
        _stopTimer();
        state = state.copyWith(playing: false);
        return;
      }
      next();
    });
  }

  void clear() {
    _stopTimer();
    state = const ExecutionViewState();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

/// Un trazador independiente por pantalla/ejercicio.
final executionControllerProvider = StateNotifierProvider.family
    .autoDispose<ExecutionController, ExecutionViewState, String>(
  (ref, sessionId) => ExecutionController(),
);
