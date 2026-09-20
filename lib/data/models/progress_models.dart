/// Progreso local del estudiante. Todo se guarda en el dispositivo:
/// LogicAI funciona sin cuenta y sin conexión.
library;

class ExerciseProgress {
  const ExerciseProgress({
    required this.exerciseId,
    this.completed = false,
    this.attempts = 0,
    this.errorsFixed = 0,
    this.lastAttempt,
  });

  final String exerciseId;
  final bool completed;
  final int attempts;
  final int errorsFixed;
  final DateTime? lastAttempt;

  ExerciseProgress copyWith({
    bool? completed,
    int? attempts,
    int? errorsFixed,
    DateTime? lastAttempt,
  }) =>
      ExerciseProgress(
        exerciseId: exerciseId,
        completed: completed ?? this.completed,
        attempts: attempts ?? this.attempts,
        errorsFixed: errorsFixed ?? this.errorsFixed,
        lastAttempt: lastAttempt ?? this.lastAttempt,
      );

  Map<String, dynamic> toJson() => {
        'id': exerciseId,
        'completed': completed,
        'attempts': attempts,
        'errorsFixed': errorsFixed,
        'lastAttempt': lastAttempt?.toIso8601String(),
      };

  factory ExerciseProgress.fromJson(Map<String, dynamic> json) =>
      ExerciseProgress(
        exerciseId: json['id'] as String,
        completed: json['completed'] as bool? ?? false,
        attempts: json['attempts'] as int? ?? 0,
        errorsFixed: json['errorsFixed'] as int? ?? 0,
        lastAttempt: json['lastAttempt'] == null
            ? null
            : DateTime.tryParse(json['lastAttempt'] as String),
      );
}

enum AttemptResult { resuelto, intento, ejecucion }

extension AttemptResultX on AttemptResult {
  String get label => switch (this) {
        AttemptResult.resuelto => 'Resuelto',
        AttemptResult.intento => 'Intento',
        AttemptResult.ejecucion => 'Ejecución',
      };
}

class HistoryEntry {
  const HistoryEntry({
    required this.exerciseId,
    required this.title,
    required this.moduleId,
    required this.result,
    required this.date,
    required this.attempt,
    this.detail,
  });

  final String exerciseId;
  final String title;
  final String moduleId;
  final AttemptResult result;
  final DateTime date;
  final int attempt;
  final String? detail;

  Map<String, dynamic> toJson() => {
        'id': exerciseId,
        'title': title,
        'module': moduleId,
        'result': result.name,
        'date': date.toIso8601String(),
        'attempt': attempt,
        'detail': detail,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        exerciseId: json['id'] as String,
        title: json['title'] as String,
        moduleId: json['module'] as String? ?? '',
        result: AttemptResult.values.byName(
            json['result'] as String? ?? AttemptResult.intento.name),
        date: DateTime.tryParse(json['date'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        attempt: json['attempt'] as int? ?? 1,
        detail: json['detail'] as String?,
      );
}

class ProgressState {
  const ProgressState({
    this.exercises = const {},
    this.history = const [],
    this.skillPractice = const {},
    this.challengesSolved = 0,
  });

  final Map<String, ExerciseProgress> exercises;
  final List<HistoryEntry> history;

  /// Cuántas veces se ha practicado cada habilidad (variables, ciclos, ...).
  final Map<String, int> skillPractice;
  final int challengesSolved;

  ExerciseProgress progressFor(String id) =>
      exercises[id] ?? ExerciseProgress(exerciseId: id);

  bool isCompleted(String id) => exercises[id]?.completed ?? false;

  int get completedCount =>
      exercises.values.where((e) => e.completed).length;

  int get totalAttempts =>
      exercises.values.fold(0, (sum, e) => sum + e.attempts);

  int get errorsFixed =>
      exercises.values.fold(0, (sum, e) => sum + e.errorsFixed);

  ProgressState copyWith({
    Map<String, ExerciseProgress>? exercises,
    List<HistoryEntry>? history,
    Map<String, int>? skillPractice,
    int? challengesSolved,
  }) =>
      ProgressState(
        exercises: exercises ?? this.exercises,
        history: history ?? this.history,
        skillPractice: skillPractice ?? this.skillPractice,
        challengesSolved: challengesSolved ?? this.challengesSolved,
      );

  Map<String, dynamic> toJson() => {
        'exercises': exercises.values.map((e) => e.toJson()).toList(),
        'history': history.map((e) => e.toJson()).toList(),
        'skills': skillPractice,
        'challengesSolved': challengesSolved,
      };

  factory ProgressState.fromJson(Map<String, dynamic> json) {
    final exercises = <String, ExerciseProgress>{};
    for (final raw in (json['exercises'] as List<dynamic>? ?? [])) {
      final progress = ExerciseProgress.fromJson(raw as Map<String, dynamic>);
      exercises[progress.exerciseId] = progress;
    }
    return ProgressState(
      exercises: exercises,
      history: (json['history'] as List<dynamic>? ?? [])
          .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      skillPractice: (json['skills'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, value as int)),
      challengesSolved: json['challengesSolved'] as int? ?? 0,
    );
  }
}
