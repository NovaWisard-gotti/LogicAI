import 'package:flutter_test/flutter_test.dart';
import 'package:logicai/engine/logic_engine.dart';

void main() {
  group('Ejecucion basica', () {
    test('asignacion y salida', () {
      final result = runProgram('inicio\n  x = 5\n  y = 2\n  x = x + y\n'
          '  mostrar x\nfin');
      expect(result.status, ExecStatus.ok);
      expect(result.output, ['7']);
    });

    test('el programa funciona sin inicio/fin', () {
      final result = runProgram('a = 2\nmostrar a * 3');
      expect(result.isOk, isTrue);
      expect(result.output, ['6']);
    });

    test('division exacta devuelve entero', () {
      final result = runProgram('mostrar 8 / 2\nmostrar 7 / 2');
      expect(result.output, ['4', '3.5']);
    });
  });

  group('Trazado', () {
    test('cada paso guarda linea, nota y memoria', () {
      final result = runProgram('x = 1\nx = x + 1\nmostrar x');
      expect(result.steps.length, 3);
      expect(result.steps.first.line, 1);
      expect(result.steps[1].line, 2);
      expect(result.steps.first.note, isNotEmpty);
      expect(result.steps.first.action, isNotEmpty);
    });

    test('la variable modificada queda marcada en el paso', () {
      final result = runProgram('x = 1\ny = 9\nx = 4');
      final last = result.steps.last;
      final x = last.variables.firstWhere((v) => v.name == 'x');
      final y = last.variables.firstWhere((v) => v.name == 'y');
      expect(x.value, '4');
      expect(x.changed, isTrue);
      expect(y.changed, isFalse);
    });

    test('la salida acumulada crece paso a paso', () {
      final result = runProgram('mostrar 1\nmostrar 2\nmostrar 3');
      expect(result.steps[0].output, ['1']);
      expect(result.steps[1].output, ['1', '2']);
      expect(result.steps[2].output, ['1', '2', '3']);
    });

    test('la traza es estable: recorrerla no la modifica', () {
      final result = runProgram('para i = 1 hasta 3\n  mostrar i\nfin_para');
      final firstPass = result.steps.map((s) => s.line).toList();
      final secondPass = result.steps.map((s) => s.line).toList();
      expect(firstPass, secondPass);
    });
  });

  group('Proteccion frente a ciclos infinitos', () {
    test('un ciclo sin avance se detiene con mensaje educativo', () {
      final result = runProgram('x = 1\nmientras x > 0 hacer\n'
          '  mostrar x\nfin_mientras');
      expect(result.status, ExecStatus.stepLimit);
      expect(result.steps.length, lessThanOrEqualTo(result.stepLimit));
      expect(result.message, contains('pasos'));
      expect(result.hint, isNotNull);
    });

    test('el limite de pasos es configurable', () {
      final result = runProgram(
        'x = 0\nmientras verdadero hacer\n  x = x + 1\nfin_mientras',
        maxSteps: 40,
      );
      expect(result.status, ExecStatus.stepLimit);
      expect(result.steps.length, lessThanOrEqualTo(40));
    });

    test('la recursion sin caso base no bloquea la aplicacion', () {
      final result = runProgram(
        'funcion f(n)\n  retornar f(n + 1)\nfin_funcion\nmostrar f(1)',
      );
      expect(result.isOk, isFalse);
    });
  });

  group('Errores educativos', () {
    test('error de sintaxis informa de la linea', () {
      final result = runProgram('x = 1\nsi x > 0 entonces\n  mostrar x');
      expect(result.status, ExecStatus.syntaxError);
      expect(result.message, isNotNull);
    });

    test('usar una variable inexistente es error de ejecucion', () {
      final result = runProgram('mostrar total');
      expect(result.status, ExecStatus.runtimeError);
      expect(result.errorLine, 1);
    });

    test('dividir entre cero se explica, no revienta', () {
      final result = runProgram('a = 4\nmostrar a / 0');
      expect(result.status, ExecStatus.runtimeError);
      expect(result.message, isNotNull);
    });

    test('indice fuera de rango se explica', () {
      final result = runProgram('datos = [1, 2]\nmostrar datos[5]');
      expect(result.status, ExecStatus.runtimeError);
    });
  });

  group('Estructuras del lenguaje', () {
    test('condicional con sino', () {
      final result = runProgram('nota = 10\nsi nota >= 11 entonces\n'
          '  mostrar "Aprobado"\nsino\n  mostrar "Desaprobado"\nfin_si');
      expect(result.output, ['Desaprobado']);
    });

    test('ciclo para con paso', () {
      final result =
          runProgram('para i = 0 hasta 6 paso 2\n  mostrar i\nfin_para');
      expect(result.output, ['0', '2', '4', '6']);
    });

    test('funcion con retorno', () {
      final result = runProgram('funcion doble(n)\n  retornar n * 2\n'
          'fin_funcion\nmostrar doble(21)');
      expect(result.output, ['42']);
    });

    test('arreglos y longitud', () {
      final result = runProgram('datos = [4, 9, 2]\nmostrar longitud(datos)\n'
          'datos[1] = 5\nmostrar datos[1]');
      expect(result.output, ['3', '5']);
    });

    test('objetos con acceso por punto', () {
      final result = runProgram('p = objeto(nombre: "Ana", edad: 20)\n'
          'p.edad = p.edad + 1\nmostrar p.nombre, p.edad');
      expect(result.output, ['Ana 21']);
    });

    test('leer toma las entradas del caso de prueba', () {
      final result = runProgram('leer n\nmostrar n * 2', inputs: [7]);
      expect(result.output, ['14']);
    });
  });

  group('Palabras contextuales', () {
    test('y, o, paso y hasta siguen siendo nombres validos', () {
      final result =
          runProgram('y = 2\npaso = 3\nhasta = 4\nmostrar y + paso + hasta');
      expect(result.isOk, isTrue);
      expect(result.output, ['9']);
    });

    test('y sigue funcionando como operador logico', () {
      final result =
          runProgram('a = verdadero\nb = falso\nmostrar a y b\nmostrar a o b');
      expect(result.output, ['falso', 'verdadero']);
    });
  });

  group('Verificacion por casos de prueba', () {
    const cases = [
      EngineTestCase(label: 'nota 11', inputs: [11], expected: ['Aprobado']),
      EngineTestCase(label: 'nota 10', inputs: [10], expected: ['Desaprobado']),
    ];

    const correcto = 'leer nota\nsi nota >= 11 entonces\n'
        '  mostrar "Aprobado"\nsino\n  mostrar "Desaprobado"\nfin_si';
    const incorrecto = 'leer nota\nsi nota > 11 entonces\n'
        '  mostrar "Aprobado"\nsino\n  mostrar "Desaprobado"\nfin_si';

    test('la solucion correcta supera todos los casos', () {
      final verification = verify(correcto, cases);
      expect(verification.passed, isTrue);
      expect(verification.passedCount, 2);
    });

    test('una solucion que acierta por casualidad falla en otro caso', () {
      final verification = verify(incorrecto, cases);
      expect(verification.passed, isFalse);
      expect(verification.passedCount, 1);
      expect(verification.firstFailure.testCase.label, 'nota 11');
    });

    test('explainFailure senala la divergencia sin dar la solucion', () {
      final verification = verify(incorrecto, cases);
      final message = explainFailure(verification.firstFailure);
      expect(message, isNotEmpty);
      expect(message.contains('>='), isFalse);
    });
  });
}
