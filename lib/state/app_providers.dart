import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/content_models.dart';
import '../data/models/progress_models.dart';
import '../data/repositories/repositories.dart';

/// Se sobrescribe en main() con la instancia ya inicializada.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences no inicializado'),
);

final contentRepositoryProvider =
    Provider<ContentRepository>((ref) => const ContentRepository());

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(ref.watch(sharedPreferencesProvider)),
);

final contentProvider = FutureProvider<AppContent>(
  (ref) => ref.watch(contentRepositoryProvider).load(),
);

/// Capa de estado (MVVM): la interfaz nunca escribe directamente en disco.
class ProgressNotifier extends StateNotifier<ProgressState> {
  ProgressNotifier(this._repository) : super(_repository.loadProgress());

  final ProgressRepository _repository;

  static const int _historyLimit = 120;

  Future<void> _persist() => _repository.saveProgress(state);

  /// Registra un intento sobre un ejercicio y actualiza habilidades,
  /// historial y contadores.
  Future<void> registerAttempt(
    Exercise exercise, {
    required bool solved,
    String? detail,
    bool countAttempt = true,
  }) async {
    final previous = state.progressFor(exercise.id);
    final wasCompleted = previous.completed;
    final attempts = countAttempt ? previous.attempts + 1 : previous.attempts;
    final fixedError =
        solved && !wasCompleted && exercise.kind == ExerciseKind.repair;

    final updated = previous.copyWith(
      completed: wasCompleted || solved,
      attempts: attempts,
      errorsFixed: previous.errorsFixed + (fixedError ? 1 : 0),
      lastAttempt: DateTime.now(),
    );

    final exercises = Map<String, ExerciseProgress>.from(state.exercises)
      ..[exercise.id] = updated;

    final skills = Map<String, int>.from(state.skillPractice);
    for (final concept in exercise.concepts) {
      skills[concept] = (skills[concept] ?? 0) + 1;
    }
    if (exercise.kind == ExerciseKind.repair) {
      skills['depuracion'] = (skills['depuracion'] ?? 0) + 1;
    }

    final history = [
      HistoryEntry(
        exerciseId: exercise.id,
        title: exercise.title,
        moduleId: exercise.moduleId,
        result: solved ? AttemptResult.resuelto : AttemptResult.intento,
        date: DateTime.now(),
        attempt: attempts,
        detail: detail,
      ),
      ...state.history,
    ];

    state = state.copyWith(
      exercises: exercises,
      skillPractice: skills,
      history: history.length > _historyLimit
          ? history.sublist(0, _historyLimit)
          : history,
      challengesSolved: state.challengesSolved +
          (solved && !wasCompleted && exercise.moduleId == 'retos' ? 1 : 0),
    );
    await _persist();
  }

  Future<void> reset() async {
    state = const ProgressState();
    await _repository.clearProgress();
  }
}

final progressProvider =
    StateNotifierProvider<ProgressNotifier, ProgressState>(
  (ref) => ProgressNotifier(ref.watch(progressRepositoryProvider)),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._repository) : super(_repository.loadThemeMode());

  final ProgressRepository _repository;

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _repository.saveThemeMode(mode);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(ref.watch(progressRepositoryProvider)),
);
