import '../../engine/logic_engine.dart';

enum ExerciseKind { trace, predict, complete, repair, build }

enum Difficulty { fundamentos, aplicacion, desafio }

extension DifficultyX on Difficulty {
  String get label => switch (this) {
        Difficulty.fundamentos => 'Fundamentos',
        Difficulty.aplicacion => 'Aplicación',
        Difficulty.desafio => 'Desafío',
      };
}

extension ExerciseKindX on ExerciseKind {
  String get label => switch (this) {
        ExerciseKind.trace => 'Laboratorio guiado',
        ExerciseKind.predict => 'Predice la ejecución',
        ExerciseKind.complete => 'Completa la lógica',
        ExerciseKind.repair => 'Repara el programa',
        ExerciseKind.build => 'Construye la solución',
      };

  String get shortLabel => switch (this) {
        ExerciseKind.trace => 'Trazar',
        ExerciseKind.predict => 'Predecir',
        ExerciseKind.complete => 'Completar',
        ExerciseKind.repair => 'Reparar',
        ExerciseKind.build => 'Construir',
      };
}

class TheoryBlock {
  const TheoryBlock({required this.title, required this.body, this.code});

  final String title;
  final String body;
  final String? code;

  factory TheoryBlock.fromJson(Map<String, dynamic> json) => TheoryBlock(
        title: json['title'] as String,
        body: json['body'] as String,
        code: json['code'] as String?,
      );
}

class LearningModule {
  const LearningModule({
    required this.id,
    required this.order,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.theory,
    required this.exerciseIds,
  });

  final String id;
  final int order;
  final String title;
  final String subtitle;
  final String icon;
  final List<TheoryBlock> theory;
  final List<String> exerciseIds;

  factory LearningModule.fromJson(Map<String, dynamic> json) => LearningModule(
        id: json['id'] as String,
        order: json['order'] as int,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        icon: json['icon'] as String? ?? 'box',
        theory: (json['theory'] as List<dynamic>)
            .map((e) => TheoryBlock.fromJson(e as Map<String, dynamic>))
            .toList(),
        exerciseIds: (json['exercises'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
      );
}

class Blank {
  const Blank({
    required this.id,
    required this.options,
    required this.answer,
    required this.explanation,
  });

  final String id;
  final List<String> options;
  final String answer;
  final String explanation;

  factory Blank.fromJson(Map<String, dynamic> json) => Blank(
        id: json['id'] as String,
        options:
            (json['options'] as List<dynamic>).map((e) => e as String).toList(),
        answer: json['answer'] as String,
        explanation: json['explanation'] as String,
      );
}

class CodeBlock {
  const CodeBlock({
    required this.id,
    required this.text,
    required this.indent,
    required this.distractor,
  });

  final String id;
  final String text;
  final int indent;
  final bool distractor;

  String get rendered => '${'    ' * indent}$text';

  factory CodeBlock.fromJson(Map<String, dynamic> json) => CodeBlock(
        id: json['id'] as String,
        text: json['text'] as String,
        indent: json['indent'] as int? ?? 0,
        distractor: json['distractor'] as bool? ?? false,
      );
}

class PredictQuestion {
  const PredictQuestion({
    required this.prompt,
    required this.options,
    required this.answer,
    required this.explanation,
  });

  final String prompt;
  final List<String> options;
  final int answer;
  final String explanation;

  factory PredictQuestion.fromJson(Map<String, dynamic> json) =>
      PredictQuestion(
        prompt: json['prompt'] as String,
        options:
            (json['options'] as List<dynamic>).map((e) => e as String).toList(),
        answer: json['answer'] as int,
        explanation: json['explanation'] as String,
      );
}

class ExerciseTest {
  const ExerciseTest({
    required this.label,
    required this.inputs,
    required this.expected,
  });

  final String label;
  final List<Object?> inputs;
  final List<String> expected;

  EngineTestCase toEngineCase() =>
      EngineTestCase(label: label, inputs: inputs, expected: expected);
}

class Exercise {
  const Exercise({
    required this.id,
    required this.moduleId,
    required this.kind,
    required this.difficulty,
    required this.title,
    required this.statement,
    required this.concepts,
    required this.tests,
    this.code,
    this.solution,
    this.blanks = const [],
    this.blocks = const [],
    this.order = const [],
    this.question,
    this.hint,
    this.focus,
  });

  final String id;
  final String moduleId;
  final ExerciseKind kind;
  final Difficulty difficulty;
  final String title;
  final String statement;
  final List<String> concepts;
  final List<ExerciseTest> tests;
  final String? code;
  final String? solution;
  final List<Blank> blanks;
  final List<CodeBlock> blocks;
  final List<String> order;
  final PredictQuestion? question;
  final String? hint;
  final String? focus;

  List<String> get expected => tests.first.expected;

  List<EngineTestCase> get engineCases =>
      tests.map((t) => t.toEngineCase()).toList();

  /// Programa inicial que ve el estudiante.
  String get startingCode => code ?? solution ?? '';

  /// Solución de referencia (para comparar, nunca se revela antes de tiempo).
  String get referenceSolution => solution ?? code ?? '';

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final expectedByTest = (json['expectedByTest'] as List<dynamic>?)
            ?.map((e) => (e as List<dynamic>).map((x) => x as String).toList())
            .toList() ??
        [
          (json['expected'] as List<dynamic>? ?? [])
              .map((e) => e as String)
              .toList()
        ];
    final rawTests = (json['tests'] as List<dynamic>? ?? []);
    final tests = <ExerciseTest>[];
    for (var i = 0; i < expectedByTest.length; i++) {
      final raw = i < rawTests.length
          ? rawTests[i] as Map<String, dynamic>
          : <String, dynamic>{};
      tests.add(ExerciseTest(
        label: raw['label'] as String? ?? 'Caso ${i + 1}',
        inputs: (raw['inputs'] as List<dynamic>? ?? const []).toList(),
        expected: expectedByTest[i],
      ));
    }

    return Exercise(
      id: json['id'] as String,
      moduleId: json['module'] as String,
      kind: ExerciseKind.values.byName(json['kind'] as String),
      difficulty: Difficulty.values.byName(json['difficulty'] as String),
      title: json['title'] as String,
      statement: json['statement'] as String,
      concepts: (json['concepts'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      tests: tests,
      code: json['code'] as String?,
      solution: json['solution'] as String?,
      blanks: (json['blanks'] as List<dynamic>? ?? [])
          .map((e) => Blank.fromJson(e as Map<String, dynamic>))
          .toList(),
      blocks: (json['blocks'] as List<dynamic>? ?? [])
          .map((e) => CodeBlock.fromJson(e as Map<String, dynamic>))
          .toList(),
      order:
          (json['order'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
      question: json['question'] == null
          ? null
          : PredictQuestion.fromJson(json['question'] as Map<String, dynamic>),
      hint: json['hint'] as String?,
      focus: json['focus'] as String?,
    );
  }
}

class ReferenceItem {
  const ReferenceItem({required this.text, required this.code});

  final String text;
  final String code;

  factory ReferenceItem.fromJson(Map<String, dynamic> json) => ReferenceItem(
        text: json['text'] as String,
        code: json['code'] as String,
      );
}

class ReferenceSection {
  const ReferenceSection({
    required this.id,
    required this.title,
    required this.summary,
    required this.items,
  });

  final String id;
  final String title;
  final String summary;
  final List<ReferenceItem> items;

  factory ReferenceSection.fromJson(Map<String, dynamic> json) =>
      ReferenceSection(
        id: json['id'] as String,
        title: json['title'] as String,
        summary: json['summary'] as String,
        items: (json['items'] as List<dynamic>)
            .map((e) => ReferenceItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class LabSample {
  const LabSample({required this.title, required this.code});

  final String title;
  final String code;

  factory LabSample.fromJson(Map<String, dynamic> json) => LabSample(
        title: json['title'] as String,
        code: json['code'] as String,
      );
}

class SkillInfo {
  const SkillInfo({required this.id, required this.label});

  final String id;
  final String label;

  factory SkillInfo.fromJson(Map<String, dynamic> json) =>
      SkillInfo(id: json['id'] as String, label: json['label'] as String);
}

class AppContent {
  AppContent({
    required this.modules,
    required this.exercises,
    required this.challengeIds,
    required this.debugWorkshopIds,
    required this.labSamples,
    required this.reference,
    required this.skills,
  });

  final List<LearningModule> modules;
  final Map<String, Exercise> exercises;
  final List<String> challengeIds;
  final List<String> debugWorkshopIds;
  final List<LabSample> labSamples;
  final List<ReferenceSection> reference;
  final List<SkillInfo> skills;

  Exercise byId(String id) => exercises[id]!;

  List<Exercise> get all => exercises.values.toList();

  List<Exercise> get challenges =>
      challengeIds.map((id) => exercises[id]!).toList();

  List<Exercise> get debugWorkshop =>
      debugWorkshopIds.map((id) => exercises[id]!).toList();

  List<Exercise> forModule(String moduleId) =>
      exercises.values.where((e) => e.moduleId == moduleId).toList();

  LearningModule? moduleById(String id) {
    for (final module in modules) {
      if (module.id == id) return module;
    }
    return null;
  }

  String moduleTitle(String id) =>
      id == 'retos' ? 'Retos' : (moduleById(id)?.title ?? id);

  String skillLabel(String id) {
    for (final skill in skills) {
      if (skill.id == id) return skill.label;
    }
    return id;
  }

  factory AppContent.fromJson(Map<String, dynamic> json) {
    final exercises = <String, Exercise>{};
    for (final raw in json['exercises'] as List<dynamic>) {
      final exercise = Exercise.fromJson(raw as Map<String, dynamic>);
      exercises[exercise.id] = exercise;
    }
    final modules = (json['modules'] as List<dynamic>)
        .map((e) => LearningModule.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return AppContent(
      modules: modules,
      exercises: exercises,
      challengeIds: (json['challenges'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      debugWorkshopIds: (json['debugWorkshop'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      labSamples: (json['labSamples'] as List<dynamic>)
          .map((e) => LabSample.fromJson(e as Map<String, dynamic>))
          .toList(),
      reference: (json['reference'] as List<dynamic>)
          .map((e) => ReferenceSection.fromJson(e as Map<String, dynamic>))
          .toList(),
      skills: (json['skills'] as List<dynamic>)
          .map((e) => SkillInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
