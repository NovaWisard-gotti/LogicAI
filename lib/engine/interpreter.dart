import 'ast.dart';
import 'errors.dart';
import 'lexer.dart';
import 'values.dart';

enum ExecStatus { ok, stepLimit, runtimeError, syntaxError }

/// Una variable tal y como se muestra en el inspector de memoria.
class VarView {
  const VarView({
    required this.scope,
    required this.name,
    required this.value,
    required this.type,
    required this.changed,
  });

  final String scope;
  final String name;
  final String value;
  final String type;
  final bool changed;
}

/// Un paso de ejecución ya materializado: permite avanzar, retroceder y
/// reiniciar sin volver a ejecutar el programa.
class TraceStep {
  const TraceStep({
    required this.index,
    required this.line,
    required this.action,
    required this.note,
    required this.variables,
    required this.output,
    required this.scope,
  });

  final int index;
  final int line;
  final String action;
  final String note;
  final List<VarView> variables;
  final List<String> output;
  final String scope;
}

class ExecutionResult {
  ExecutionResult({
    required this.steps,
    required this.output,
    required this.status,
    this.message,
    this.errorLine = 0,
    this.hint,
    this.stepLimit = Interpreter.defaultMaxSteps,
  });

  final List<TraceStep> steps;
  final List<String> output;
  final ExecStatus status;
  final String? message;
  final int errorLine;
  final String? hint;
  final int stepLimit;

  bool get isOk => status == ExecStatus.ok;

  /// Línea donde se detuvo la ejecución (útil para el modo "¿Qué ocurrió?").
  int get stopLine =>
      errorLine != 0 ? errorLine : (steps.isEmpty ? 0 : steps.last.line);

  factory ExecutionResult.syntax(EduParseError error) => ExecutionResult(
        steps: const [],
        output: const [],
        status: ExecStatus.syntaxError,
        message: error.message,
        errorLine: error.line,
        hint: error.hint,
      );
}

class _Scope {
  _Scope(this.name);

  final String name;
  final Map<String, Object?> vars = {};
}

/// Intérprete educativo: ejecuta el programa completo y guarda un paso por
/// cada acción relevante. No ejecuta código arbitrario del sistema ni usa
/// servicios externos: todo ocurre dentro de este entorno controlado.
class Interpreter {
  Interpreter({List<Object?>? inputs, this.maxSteps = defaultMaxSteps})
      : _inputs = List<Object?>.from(inputs ?? const []);

  static const int defaultMaxSteps = 600;
  static const int maxCallDepth = 24;

  final int maxSteps;
  final List<Object?> _inputs;

  final List<TraceStep> _steps = [];
  final List<String> _output = [];
  final Map<String, FuncDeclStmt> _functions = {};
  final List<_Scope> _scopes = [_Scope('principal')];

  String? _changedScope;
  String? _changedName;
  int _depth = 0;

  Map<String, Object?> get _current => _scopes.last.vars;

  ExecutionResult run(List<Stmt> program) {
    try {
      for (final stmt in program) {
        if (stmt is FuncDeclStmt) _functions[stmt.name] = stmt;
      }
      _execBlock(program.where((s) => s is! FuncDeclStmt).toList());
      return ExecutionResult(
        steps: _steps,
        output: _output,
        status: ExecStatus.ok,
        stepLimit: maxSteps,
      );
    } on StepLimitSignal {
      return ExecutionResult(
        steps: _steps,
        output: _output,
        status: ExecStatus.stepLimit,
        stepLimit: maxSteps,
        message: 'La ejecución fue detenida porque el programa superó el '
            'límite de $maxSteps pasos. Revisa la condición del ciclo.',
        hint: 'Comprueba que algo dentro del ciclo modifique la variable de '
            'la condición.',
        errorLine: _steps.isEmpty ? 0 : _steps.last.line,
      );
    } on ReturnSignal {
      return ExecutionResult(
        steps: _steps,
        output: _output,
        status: ExecStatus.ok,
        stepLimit: maxSteps,
      );
    } on EduRuntimeError catch (error) {
      return ExecutionResult(
        steps: _steps,
        output: _output,
        status: ExecStatus.runtimeError,
        stepLimit: maxSteps,
        message: error.message,
        errorLine: error.line,
        hint: error.hint,
      );
    }
  }

  // ----------------------------------------------------------- utilidades
  Object? _getVar(String name, int line) {
    if (_current.containsKey(name)) return _current[name];
    throw EduRuntimeError('La variable "$name" se usa antes de recibir un valor.',
        line: line, hint: 'Asígnale un valor inicial antes de utilizarla.');
  }

  void _setVar(String name, Object? value) => _current[name] = value;

  List<VarView> _snapshot() {
    final views = <VarView>[];
    for (final scope in _scopes) {
      scope.vars.forEach((name, value) {
        views.add(VarView(
          scope: scope.name,
          name: name,
          value: fmt(value),
          type: typeLabel(value),
          changed: _changedScope == scope.name && _changedName == name,
        ));
      });
    }
    return views;
  }

  void _emit(int line, String action, String note) {
    if (_steps.length >= maxSteps) throw StepLimitSignal();
    _steps.add(TraceStep(
      index: _steps.length,
      line: line,
      action: action,
      note: note,
      variables: _snapshot(),
      output: List<String>.from(_output),
      scope: _scopes.last.name,
    ));
  }

  void _markChanged(String name) {
    _changedScope = _scopes.last.name;
    _changedName = name;
  }

  void _clearChanged() {
    _changedScope = null;
    _changedName = null;
  }

  // ---------------------------------------------------------- ejecución
  void _execBlock(List<Stmt> statements) {
    for (final stmt in statements) {
      _execStatement(stmt);
    }
  }

  void _execStatement(Stmt stmt) {
    _clearChanged();
    if (stmt is AssignStmt) {
      _execAssign(stmt);
    } else if (stmt is ArrayDeclStmt) {
      final size = _eval(stmt.size);
      if (size is! num || size is bool || size < 0 || size != size.round()) {
        throw EduRuntimeError(
            'El tamaño del arreglo debe ser un número entero positivo.',
            line: stmt.line);
      }
      final length = size.round();
      _setVar(stmt.name, List<Object?>.filled(length, 0, growable: true));
      _markChanged(stmt.name);
      _emit(stmt.line, 'arreglo ${stmt.name}[$length]',
          'Se crea un arreglo de $length posiciones con valor 0.');
    } else if (stmt is PrintStmt) {
      final text = stmt.args.map((a) => fmt(_eval(a))).join(' ');
      _output.add(text);
      _emit(stmt.line, 'mostrar', 'Salida: $text');
    } else if (stmt is ReadStmt) {
      if (_inputs.isEmpty) {
        throw EduRuntimeError(
            'No hay más datos de entrada para "leer ${stmt.name}".',
            line: stmt.line,
            hint: 'Cada ejercicio define una lista fija de entradas.');
      }
      final value = _inputs.removeAt(0);
      _setVar(stmt.name, value);
      _markChanged(stmt.name);
      _emit(stmt.line, 'leer ${stmt.name}', 'Se lee el valor ${fmt(value)}.');
    } else if (stmt is IfStmt) {
      final condition = _evalCondition(stmt.condition, stmt.line);
      _emit(
        stmt.line,
        'si',
        condition
            ? 'La condición es verdadera → se ejecuta el bloque.'
            : 'La condición es falsa → se omite el bloque.',
      );
      _execBlock(condition ? stmt.thenBranch : stmt.elseBranch);
    } else if (stmt is WhileStmt) {
      var iterations = 0;
      while (true) {
        final condition = _evalCondition(stmt.condition, stmt.line);
        if (condition) iterations++;
        _emit(
          stmt.line,
          'mientras',
          condition
              ? 'Condición verdadera → iteración $iterations.'
              : 'Condición falsa → el ciclo termina tras $iterations '
                  'iteración(es).',
        );
        if (!condition) break;
        _execBlock(stmt.body);
        _clearChanged();
      }
    } else if (stmt is ForStmt) {
      _execFor(stmt);
    } else if (stmt is ReturnStmt) {
      final value = stmt.value == null ? null : _eval(stmt.value!);
      _emit(stmt.line, 'retornar', 'Devuelve ${fmt(value)}.');
      throw ReturnSignal(value);
    } else if (stmt is ExprStmt) {
      final value = _eval(stmt.expr);
      final expr = stmt.expr;
      final isUserCall = expr is CallExpr && _functions.containsKey(expr.name);
      if (!isUserCall) {
        _emit(stmt.line, 'llamada', 'Resultado: ${fmt(value)}');
      }
    } else if (stmt is FuncDeclStmt) {
      _functions[stmt.name] = stmt;
    } else {
      throw EduRuntimeError('Instrucción no soportada.', line: stmt.line);
    }
  }

  void _execFor(ForStmt stmt) {
    final from = _eval(stmt.from);
    final to = _eval(stmt.to);
    final step = stmt.step == null ? 1 : _eval(stmt.step!);
    for (final value in [from, to, step]) {
      if (value is! num || value is bool) {
        throw EduRuntimeError('El ciclo "para" necesita valores numéricos.',
            line: stmt.line);
      }
    }
    final limit = to as num;
    final increment = step as num;
    if (increment == 0) {
      throw EduRuntimeError('El paso del ciclo "para" no puede ser 0.',
          line: stmt.line,
          hint: 'Con paso 0 la variable nunca avanzaría y el ciclo no '
              'terminaría.');
    }
    _setVar(stmt.variable, from);
    _markChanged(stmt.variable);
    _emit(
      stmt.line,
      'para',
      '${stmt.variable} inicia en ${fmt(from)} y avanza hasta ${fmt(limit)} '
          'de ${fmt(increment)} en ${fmt(increment)}.',
    );
    var iterations = 0;
    while (true) {
      final current = _current[stmt.variable];
      if (current is! num) {
        throw EduRuntimeError(
            'La variable del ciclo "para" dejó de ser numérica.',
            line: stmt.line);
      }
      final keepGoing = increment > 0 ? current <= limit : current >= limit;
      _clearChanged();
      if (!keepGoing) {
        _emit(
          stmt.line,
          'para',
          '${stmt.variable} = ${fmt(current)} ya no cumple el límite → el '
              'ciclo termina tras $iterations iteración(es).',
        );
        break;
      }
      iterations++;
      _emit(stmt.line, 'para',
          '${stmt.variable} = ${fmt(current)} → iteración $iterations.');
      _execBlock(stmt.body);
      final nextValue = (_current[stmt.variable] as num) + increment;
      _setVar(stmt.variable, nextValue);
      _markChanged(stmt.variable);
      _emit(stmt.line, 'para', '${stmt.variable} avanza a ${fmt(nextValue)}.');
    }
  }

  void _execAssign(AssignStmt stmt) {
    final value = _eval(stmt.value);
    final target = stmt.target;
    if (target is VarExpr) {
      final existed = _current.containsKey(target.name);
      final previous = _current[target.name];
      _setVar(target.name, value);
      _markChanged(target.name);
      _emit(
        stmt.line,
        '${target.name} = ...',
        existed
            ? '${target.name}: ${fmt(previous)} → ${fmt(value)}'
            : 'Se crea ${target.name} con el valor ${fmt(value)}.',
      );
      return;
    }
    if (target is IndexExpr) {
      final container = _eval(target.target);
      final rawIndex = _eval(target.index);
      if (container is! List) {
        throw EduRuntimeError('Solo se puede usar [ ] con un arreglo.',
            line: stmt.line);
      }
      final index = _checkIndex(rawIndex, container.length, stmt.line);
      final previous = container[index];
      container[index] = value;
      final name = _baseName(target);
      _markChanged(name);
      _emit(stmt.line, '$name[$index] = ...',
          '$name[$index]: ${fmt(previous)} → ${fmt(value)}');
      return;
    }
    if (target is FieldExpr) {
      final object = _eval(target.target);
      if (object is! ObjValue) {
        throw EduRuntimeError('Solo un objeto tiene atributos.',
            line: stmt.line);
      }
      final previous = object.fields[target.field];
      object.fields[target.field] = value;
      final name = _baseName(target);
      _markChanged(name);
      _emit(stmt.line, '$name.${target.field} = ...',
          '$name.${target.field}: ${fmt(previous)} → ${fmt(value)}');
      return;
    }
    throw EduRuntimeError('No se puede asignar a esa expresión.',
        line: stmt.line);
  }

  String _baseName(Expr expr) {
    var node = expr;
    while (node is! VarExpr) {
      if (node is IndexExpr) {
        node = node.target;
      } else if (node is FieldExpr) {
        node = node.target;
      } else {
        return 'valor';
      }
    }
    return node.name;
  }

  int _checkIndex(Object? raw, int length, int line) {
    if (raw is! num || raw is bool || raw != raw.round()) {
      throw EduRuntimeError('El índice debe ser un número entero.', line: line);
    }
    final index = raw.round();
    if (index < 0 || index >= length) {
      throw EduRuntimeError(
          'El índice $index está fuera del arreglo (posiciones válidas: 0 a '
          '${length - 1}).',
          line: line,
          hint: 'Recuerda que la primera posición es 0 y la última es '
              'longitud - 1.');
    }
    return index;
  }

  bool _evalCondition(Expr expr, int line) {
    final value = _eval(expr);
    if (value is! bool) {
      throw EduRuntimeError('La condición debe dar verdadero o falso.',
          line: line,
          hint: 'Usa comparaciones como >=, ==, < o valores lógicos.');
    }
    return value;
  }

  // ---------------------------------------------------------- expresiones
  Object? _eval(Expr expr) {
    if (expr is NumLit) return expr.value;
    if (expr is TextLit) return expr.value;
    if (expr is BoolLit) return expr.value;
    if (expr is VarExpr) return _getVar(expr.name, expr.line);
    if (expr is ArrayLit) {
      return expr.items.map(_eval).toList(growable: true);
    }
    if (expr is ObjectLit) {
      final fields = <String, Object?>{};
      for (final pair in expr.pairs) {
        fields[pair.key] = _eval(pair.value);
      }
      return ObjValue(fields);
    }
    if (expr is IndexExpr) {
      final container = _eval(expr.target);
      if (container is! List) {
        throw EduRuntimeError('Solo se puede usar [ ] con un arreglo.',
            line: expr.line);
      }
      final index = _checkIndex(_eval(expr.index), container.length, expr.line);
      return container[index];
    }
    if (expr is FieldExpr) {
      final object = _eval(expr.target);
      if (object is! ObjValue) {
        throw EduRuntimeError('Solo un objeto tiene atributos.',
            line: expr.line);
      }
      if (!object.fields.containsKey(expr.field)) {
        throw EduRuntimeError('El objeto no tiene el atributo "${expr.field}".',
            line: expr.line,
            hint: 'Atributos disponibles: '
                '${object.fields.keys.join(", ")}.');
      }
      return object.fields[expr.field];
    }
    if (expr is UnaryExpr) {
      final value = _eval(expr.expr);
      if (expr.op == '-') {
        _requireNumber(value, expr.line);
        return -(value as num);
      }
      if (value is! bool) {
        throw EduRuntimeError('"no" solo se aplica a valores lógicos.',
            line: expr.line);
      }
      return !value;
    }
    if (expr is BinaryExpr) return _evalBinary(expr);
    if (expr is CallExpr) return _call(expr);
    throw EduRuntimeError('Expresión no soportada.', line: expr.line);
  }

  void _requireNumber(Object? value, int line) {
    if (value is! num || value is bool) {
      throw EduRuntimeError('Se esperaba un valor numérico.',
          line: line,
          hint: 'Revisa si estás operando con un texto o un valor lógico.');
    }
  }

  Object? _evalBinary(BinaryExpr expr) {
    if (expr.op == 'y' || expr.op == 'o') {
      final left = _eval(expr.left);
      if (left is! bool) {
        throw EduRuntimeError('"${expr.op}" necesita valores lógicos.',
            line: expr.line);
      }
      if (expr.op == 'y' && !left) return false;
      if (expr.op == 'o' && left) return true;
      final right = _eval(expr.right);
      if (right is! bool) {
        throw EduRuntimeError('"${expr.op}" necesita valores lógicos.',
            line: expr.line);
      }
      return right;
    }

    final a = _eval(expr.left);
    final b = _eval(expr.right);

    switch (expr.op) {
      case '==':
        return valuesEqual(a, b);
      case '!=':
        return !valuesEqual(a, b);
      case '<':
      case '<=':
      case '>':
      case '>=':
        if (a is String && b is String) {
          final c = a.compareTo(b);
          switch (expr.op) {
            case '<':
              return c < 0;
            case '<=':
              return c <= 0;
            case '>':
              return c > 0;
            default:
              return c >= 0;
          }
        }
        _requireNumber(a, expr.line);
        _requireNumber(b, expr.line);
        final x = a as num;
        final y = b as num;
        switch (expr.op) {
          case '<':
            return x < y;
          case '<=':
            return x <= y;
          case '>':
            return x > y;
          default:
            return x >= y;
        }
      case '+':
        if (a is String || b is String) return '${fmt(a)}${fmt(b)}';
        _requireNumber(a, expr.line);
        _requireNumber(b, expr.line);
        return (a as num) + (b as num);
      case '-':
        _requireNumber(a, expr.line);
        _requireNumber(b, expr.line);
        return (a as num) - (b as num);
      case '*':
        _requireNumber(a, expr.line);
        _requireNumber(b, expr.line);
        return (a as num) * (b as num);
      case '/':
        _requireNumber(a, expr.line);
        _requireNumber(b, expr.line);
        if ((b as num) == 0) {
          throw EduRuntimeError('No se puede dividir entre cero.',
              line: expr.line,
              hint: 'Comprueba el divisor antes de hacer la división.');
        }
        final left = a as num;
        if (left is int && b is int && left % b == 0) return left ~/ b;
        return left / b;
      case '%':
        _requireNumber(a, expr.line);
        _requireNumber(b, expr.line);
        if ((b as num) == 0) {
          throw EduRuntimeError('No se puede calcular el residuo entre cero.',
              line: expr.line);
        }
        return (a as num) % b;
      default:
        throw EduRuntimeError('Operador no soportado: ${expr.op}',
            line: expr.line);
    }
  }

  Object? _call(CallExpr expr) {
    if (_functions.containsKey(expr.name)) return _callUser(expr);
    if (!kBuiltins.contains(expr.name)) {
      throw EduRuntimeError('La función "${expr.name}" no existe.',
          line: expr.line,
          hint: 'Revisa el nombre o defínela con "funcion".');
    }
    final args = expr.args.map(_eval).toList();
    void need(int count) {
      if (args.length != count) {
        throw EduRuntimeError(
            '"${expr.name}" necesita $count argumento(s) y recibió '
            '${args.length}.',
            line: expr.line);
      }
    }

    switch (expr.name) {
      case 'longitud':
        need(1);
        final value = args[0];
        if (value is List) return value.length;
        if (value is String) return value.length;
        throw EduRuntimeError('"longitud" se usa con arreglos o textos.',
            line: expr.line);
      case 'entero':
        need(1);
        _requireNumber(args[0], expr.line);
        return (args[0] as num).truncate();
      case 'redondear':
        need(1);
        _requireNumber(args[0], expr.line);
        return (args[0] as num).round();
      case 'absoluto':
        need(1);
        _requireNumber(args[0], expr.line);
        return (args[0] as num).abs();
      case 'maximo':
        need(2);
        _requireNumber(args[0], expr.line);
        _requireNumber(args[1], expr.line);
        return (args[0] as num) >= (args[1] as num) ? args[0] : args[1];
      case 'minimo':
        need(2);
        _requireNumber(args[0], expr.line);
        _requireNumber(args[1], expr.line);
        return (args[0] as num) <= (args[1] as num) ? args[0] : args[1];
      case 'texto':
        need(1);
        return fmt(args[0]);
      case 'numero':
        need(1);
        final parsed = num.tryParse(fmt(args[0]));
        if (parsed == null) {
          throw EduRuntimeError('No se pudo convertir "${fmt(args[0])}" a '
              'número.', line: expr.line);
        }
        return parsed;
      case 'residuo':
        need(2);
        _requireNumber(args[0], expr.line);
        _requireNumber(args[1], expr.line);
        if ((args[1] as num) == 0) {
          throw EduRuntimeError('No se puede calcular el residuo entre cero.',
              line: expr.line);
        }
        return (args[0] as num) % (args[1] as num);
      case 'potencia':
        need(2);
        _requireNumber(args[0], expr.line);
        _requireNumber(args[1], expr.line);
        final result = _pow(args[0] as num, args[1] as num);
        return result;
      default:
        throw EduRuntimeError('La función "${expr.name}" no existe.',
            line: expr.line);
    }
  }

  num _pow(num base, num exponent) {
    final result = _powDouble(base.toDouble(), exponent.toDouble());
    if (base is int && exponent is int && exponent >= 0 && result.isFinite) {
      return result.round();
    }
    return result;
  }

  double _powDouble(double base, double exponent) {
    var result = 1.0;
    if (exponent == exponent.roundToDouble() && exponent >= 0) {
      for (var i = 0; i < exponent.round(); i++) {
        result *= base;
      }
      return result;
    }
    // Exponentes no enteros: aproximación sencilla suficiente para el MVP.
    return _expApprox(exponent * _lnApprox(base));
  }

  double _lnApprox(double x) {
    if (x <= 0) return double.nan;
    var y = (x - 1) / (x + 1);
    var y2 = y * y;
    var sum = 0.0;
    var term = y;
    for (var i = 0; i < 12; i++) {
      sum += term / (2 * i + 1);
      term *= y2;
    }
    return 2 * sum;
  }

  double _expApprox(double x) {
    var sum = 1.0;
    var term = 1.0;
    for (var i = 1; i < 20; i++) {
      term *= x / i;
      sum += term;
    }
    return sum;
  }

  Object? _callUser(CallExpr expr) {
    final declaration = _functions[expr.name]!;
    if (expr.args.length != declaration.params.length) {
      throw EduRuntimeError(
          'La función "${expr.name}" espera ${declaration.params.length} '
          'parámetro(s) y recibió ${expr.args.length}.',
          line: expr.line);
    }
    final args = expr.args.map(_eval).toList();
    if (_depth >= maxCallDepth) {
      throw EduRuntimeError('Demasiadas llamadas anidadas de funciones.',
          line: expr.line,
          hint: 'Revisa si la función se llama a sí misma sin condición de '
              'salida.');
    }
    final scope = _Scope(expr.name);
    for (var i = 0; i < args.length; i++) {
      scope.vars[declaration.params[i]] = args[i];
    }
    _scopes.add(scope);
    _depth++;
    _clearChanged();
    _emit(
      expr.line,
      'llamar ${expr.name}',
      scope.vars.isEmpty
          ? 'La función se ejecuta sin parámetros.'
          : 'Parámetros: ${scope.vars.entries.map((e) => '${e.key} = '
              '${fmt(e.value)}').join(', ')}',
    );
    Object? returned;
    try {
      _execBlock(declaration.body);
    } on ReturnSignal catch (signal) {
      returned = signal.value;
    } finally {
      _scopes.removeLast();
      _depth--;
    }
    _clearChanged();
    _emit(
      expr.line,
      'fin de ${expr.name}',
      returned == null
          ? 'La función ${expr.name} termina sin devolver un valor.'
          : 'La función devuelve ${fmt(returned)}.',
    );
    return returned;
  }
}
