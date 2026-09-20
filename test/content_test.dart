import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logicai/data/models/content_models.dart';
import 'package:logicai/engine/logic_engine.dart';

/// El contenido se valida como si fuera codigo: si un ejercicio no se puede
/// resolver, o si una opcion incorrecta resulta ser correcta, la prueba falla.
AppContent loadContent() {
  final file = File('assets/content/content.json');
  expect(file.existsSync(), isTrue,
      reason: 'Falta assets/content/content.json');
  return AppContent.fromJson(
      json.decode(file.readAsStringSync()) as Map<String, dynamic>);
}

String fillBlanks(Exercise exercise, Map<String, String> choices) {
  var code = exercise.code ?? '';
  for (final blank in exercise.blanks) {
    code = code.replaceAll('{{${blank.id}}}', choices[blank.id] ?? '____');
  }
  return code;
}

void main() {
  final content = loadContent();

  group('Estructura del catalogo', () {
    test('hay siete modulos ordenados', () {
      expect(content.modules.length, 7);
      for (var i = 0; i < content.modules.length; i++) {
        expect(content.modules[i].order, i + 1);
      }
    });

    test('todos los ejercicios referenciados existen', () {
      for (final module in content.modules) {
        expect(module.exerciseIds, isNotEmpty);
        for (final id in module.exerciseIds) {
          expect(content.exercises.containsKey(id), isTrue, reason: id);
        }
      }
      for (final id in [...content.challengeIds, ...content.debugWorkshopIds]) {
        expect(content.exercises.containsKey(id), isTrue, reason: id);
      }
    });

    test('cada ejercicio declara enunciado, conceptos y casos', () {
      for (final exercise in content.all) {
        expect(exercise.statement.trim(), isNotEmpty, reason: exercise.id);
        expect(exercise.concepts, isNotEmpty, reason: exercise.id);
        expect(exercise.tests, isNotEmpty, reason: exercise.id);
      }
    });

    test('los ejemplos del laboratorio se ejecutan sin errores', () {
      for (final sample in content.labSamples) {
        final result = runProgram(sample.code);
        expect(result.isOk, isTrue, reason: sample.title);
      }
    });

    test('la consulta rapida tiene secciones con ejemplos', () {
      expect(content.reference, isNotEmpty);
      for (final section in content.reference) {
        expect(section.items, isNotEmpty, reason: section.id);
      }
    });
  });

  group('Cada ejercicio es resoluble', () {
    for (final exercise in content.all) {
      test('${exercise.id} · la solucion de referencia supera todos los casos',
          () {
        final verification =
            verify(exercise.referenceSolution, exercise.engineCases);
        expect(verification.passed, isTrue,
            reason: '${exercise.id}: '
                '${explainFailure(verification.firstFailure)}');
      });
    }
  });

  group('Los ejercicios de reparacion parten de un programa que falla', () {
    for (final exercise
        in content.all.where((e) => e.kind == ExerciseKind.repair)) {
      test('${exercise.id} · el programa inicial no pasa los casos', () {
        final verification = verify(exercise.code!, exercise.engineCases);
        expect(verification.passed, isFalse, reason: exercise.id);
      });
    }
  });

  group('Los huecos tienen una unica respuesta valida', () {
    for (final exercise
        in content.all.where((e) => e.kind == ExerciseKind.complete)) {
      test('${exercise.id} · las respuestas correctas resuelven el programa',
          () {
        final correct = {
          for (final blank in exercise.blanks) blank.id: blank.answer
        };
        final verification =
            verify(fillBlanks(exercise, correct), exercise.engineCases);
        expect(verification.passed, isTrue, reason: exercise.id);
      });

      test('${exercise.id} · cada opcion incorrecta falla en algun caso', () {
        final correct = {
          for (final blank in exercise.blanks) blank.id: blank.answer
        };
        for (final blank in exercise.blanks) {
          expect(blank.options.contains(blank.answer), isTrue,
              reason: '${exercise.id}/${blank.id}');
          expect(blank.explanation.trim(), isNotEmpty,
              reason: '${exercise.id}/${blank.id}');
          for (final option in blank.options) {
            if (option == blank.answer) continue;
            final choices = Map<String, String>.from(correct)
              ..[blank.id] = option;
            final verification =
                verify(fillBlanks(exercise, choices), exercise.engineCases);
            expect(verification.passed, isFalse,
                reason: '${exercise.id}/${blank.id}: la opcion "$option" '
                    'tambien resuelve el ejercicio');
          }
        }
      });
    }
  });

  group('Los bloques construyen exactamente la solucion', () {
    for (final exercise
        in content.all.where((e) => e.kind == ExerciseKind.build)) {
      test('${exercise.id} · el orden declarado resuelve el ejercicio', () {
        final byId = {for (final block in exercise.blocks) block.id: block};
        final assembled =
            exercise.order.map((id) => byId[id]!.rendered).join('\n');
        final verification = verify(assembled, exercise.engineCases);
        expect(verification.passed, isTrue, reason: exercise.id);
      });

      test('${exercise.id} · hay distractores y ninguno esta en la solucion',
          () {
        final distractors =
            exercise.blocks.where((b) => b.distractor).map((b) => b.id);
        expect(distractors, isNotEmpty, reason: exercise.id);
        for (final id in distractors) {
          expect(exercise.order.contains(id), isFalse, reason: id);
        }
      });
    }
  });

  group('Las predicciones coinciden con la ejecucion real', () {
    for (final exercise
        in content.all.where((e) => e.kind == ExerciseKind.predict)) {
      test('${exercise.id} · la opcion correcta es la salida real', () {
        final question = exercise.question!;
        expect(question.answer, greaterThanOrEqualTo(0));
        expect(question.answer, lessThan(question.options.length));
        expect(question.explanation.trim(), isNotEmpty);

        final result = runProgram(exercise.referenceSolution,
            inputs: exercise.tests.first.inputs);
        expect(result.isOk, isTrue, reason: exercise.id);
        expect(question.options[question.answer], result.output.join('\n'),
            reason: exercise.id);
      });
    }
  });

  group('Los ejercicios con varios casos evitan el acierto por casualidad', () {
    test('al menos un ejercicio se comprueba con varias entradas', () {
      final multi = content.all.where((e) => e.tests.length > 1).toList();
      expect(multi, isNotEmpty);
      for (final exercise in multi) {
        final outputs =
            exercise.tests.map((t) => t.expected.join('|')).toSet();
        expect(outputs.length, greaterThan(1),
            reason: '${exercise.id}: todos los casos esperan lo mismo, '
                'no distinguen una solucion valida de una casual');
      }
    });
  });

  group('Ningun programa del catalogo se queda sin terminar', () {
    for (final exercise in content.all) {
      test('${exercise.id} · la solucion termina dentro del limite de pasos',
          () {
        for (final testCase in exercise.engineCases) {
          final result = runProgram(exercise.referenceSolution,
              inputs: testCase.inputs);
          expect(result.status, isNot(ExecStatus.stepLimit),
              reason: '${exercise.id}/${testCase.label}');
        }
      });
    }
  });
}
