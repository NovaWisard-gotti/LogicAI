import 'ast.dart';
import 'errors.dart';
import 'lexer.dart';

/// Analizador sintáctico descendente recursivo del pseudocódigo de LogicAI.
///
/// No es un compilador: reconoce únicamente las estructuras necesarias para
/// los módulos del MVP (variables, operadores, condicionales, ciclos,
/// funciones, arreglos y objetos básicos).
class Parser {
  Parser(this.tokens);

  final List<Token> tokens;
  int _pos = 0;

  Token get _peek => tokens[_pos];

  Token _advance() => tokens[_pos++];

  bool _atKeyword(List<String> words) =>
      _peek.type == TokenType.keyword && words.contains(_peek.value);

  bool _atWord(List<String> words) =>
      _peek.type == TokenType.identifier &&
      words.contains(_peek.word.toLowerCase());

  bool _atSymbol(List<String> symbols) =>
      _peek.type == TokenType.symbol && symbols.contains(_peek.value);

  Token _expectSymbol(String symbol) {
    final token = _advance();
    if (token.type != TokenType.symbol || token.value != symbol) {
      throw EduParseError('Se esperaba "$symbol".', line: token.line);
    }
    return token;
  }

  Token _expectKeyword(String keyword) {
    final token = _advance();
    if (token.type != TokenType.keyword || token.value != keyword) {
      throw EduParseError('Se esperaba "$keyword".', line: token.line);
    }
    return token;
  }

  Token _expectWord(String word) {
    final token = _advance();
    if (token.type != TokenType.identifier ||
        token.word.toLowerCase() != word) {
      throw EduParseError('Se esperaba "$word".', line: token.line);
    }
    return token;
  }

  Token _expectIdentifier() {
    final token = _advance();
    if (token.type != TokenType.identifier) {
      throw EduParseError('Se esperaba el nombre de una variable.',
          line: token.line);
    }
    return token;
  }

  void _skipNewlines() {
    while (_peek.type == TokenType.newline) {
      _advance();
    }
  }

  void _endOfStatement() {
    final token = _peek;
    if (token.type == TokenType.newline || token.type == TokenType.eof) return;
    throw EduParseError('Instrucción no reconocida cerca de "${token.value}".',
        line: token.line,
        hint: 'Escribe una instrucción por línea.');
  }

  List<Stmt> parseProgram() {
    final statements = <Stmt>[];
    _skipNewlines();
    if (_atKeyword(['inicio'])) {
      _advance();
      _skipNewlines();
    }
    while (true) {
      _skipNewlines();
      if (_peek.type == TokenType.eof) break;
      if (_atKeyword(['fin'])) {
        _advance();
        _skipNewlines();
        break;
      }
      statements.add(_parseStatement());
    }
    return statements;
  }

  List<Stmt> _parseBlock(List<String> terminators) {
    final statements = <Stmt>[];
    while (true) {
      _skipNewlines();
      if (_peek.type == TokenType.eof) {
        throw EduParseError(
            'El bloque no fue cerrado (falta ${terminators.join(" o ")}).',
            line: _peek.line);
      }
      if (_atKeyword(terminators)) break;
      statements.add(_parseStatement());
    }
    return statements;
  }

  Stmt _parseStatement() {
    final token = _peek;
    final line = token.line;

    if (token.type == TokenType.keyword) {
      switch (token.value) {
        case 'mostrar':
          _advance();
          final args = <Expr>[_parseExpression()];
          while (_atSymbol([','])) {
            _advance();
            args.add(_parseExpression());
          }
          _endOfStatement();
          return PrintStmt(line, args);
        case 'leer':
          _advance();
          final name = _expectIdentifier().word;
          _endOfStatement();
          return ReadStmt(line, name);
        case 'arreglo':
          _advance();
          final name = _expectIdentifier().word;
          _expectSymbol('[');
          final size = _parseExpression();
          _expectSymbol(']');
          _endOfStatement();
          return ArrayDeclStmt(line, name, size);
        case 'si':
          return _parseIf();
        case 'mientras':
          _advance();
          final condition = _parseExpression();
          if (_atWord(['hacer'])) _advance();
          _endOfStatement();
          final body = _parseBlock(['fin_mientras']);
          _expectKeyword('fin_mientras');
          _endOfStatement();
          return WhileStmt(line, condition, body);
        case 'para':
          _advance();
          final variable = _expectIdentifier().word;
          _expectSymbol('=');
          final from = _parseExpression();
          _expectWord('hasta');
          final to = _parseExpression();
          Expr? step;
          if (_atWord(['paso'])) {
            _advance();
            step = _parseExpression();
          }
          if (_atWord(['hacer'])) _advance();
          _endOfStatement();
          final body = _parseBlock(['fin_para']);
          _expectKeyword('fin_para');
          _endOfStatement();
          return ForStmt(line, variable, from, to, step, body);
        case 'funcion':
          _advance();
          final name = _expectIdentifier().word;
          final params = <String>[];
          _expectSymbol('(');
          if (!_atSymbol([')'])) {
            params.add(_expectIdentifier().word);
            while (_atSymbol([','])) {
              _advance();
              params.add(_expectIdentifier().word);
            }
          }
          _expectSymbol(')');
          _endOfStatement();
          final body = _parseBlock(['fin_funcion']);
          _expectKeyword('fin_funcion');
          _endOfStatement();
          return FuncDeclStmt(line, name, params, body);
        case 'retornar':
          _advance();
          Expr? value;
          if (_peek.type != TokenType.newline && _peek.type != TokenType.eof) {
            value = _parseExpression();
          }
          _endOfStatement();
          return ReturnStmt(line, value);
        default:
          throw EduParseError('No se esperaba "${token.value}" aquí.',
              line: line);
      }
    }

    if (token.type == TokenType.identifier) {
      final target = _parsePostfixTarget();
      if (_atSymbol(['='])) {
        _advance();
        final value = _parseExpression();
        _endOfStatement();
        return AssignStmt(line, target, value);
      }
      if (target is CallExpr) {
        _endOfStatement();
        return ExprStmt(line, target);
      }
      throw EduParseError('Se esperaba una asignación con "=".',
          line: line,
          hint: 'Por ejemplo: ${_describe(target)} = 10');
    }

    throw EduParseError('Instrucción no reconocida cerca de "${token.value}".',
        line: line);
  }

  String _describe(Expr expr) {
    if (expr is VarExpr) return expr.name;
    if (expr is IndexExpr) return '${_describe(expr.target)}[0]';
    if (expr is FieldExpr) return '${_describe(expr.target)}.${expr.field}';
    return 'variable';
  }

  Stmt _parseIf() {
    final line = _peek.line;
    _expectKeyword('si');
    final condition = _parseExpression();
    _expectKeyword('entonces');
    _endOfStatement();
    final thenBranch = _parseBlock(['sino', 'fin_si']);
    var elseBranch = <Stmt>[];
    if (_atKeyword(['sino'])) {
      _advance();
      if (_atKeyword(['si'])) {
        elseBranch = [_parseIf()];
        return IfStmt(line, condition, thenBranch, elseBranch);
      }
      _endOfStatement();
      elseBranch = _parseBlock(['fin_si']);
    }
    _expectKeyword('fin_si');
    _endOfStatement();
    return IfStmt(line, condition, thenBranch, elseBranch);
  }

  Expr _parsePostfixTarget() {
    final token = _expectIdentifier();
    return _parsePostfix(VarExpr(token.line, token.word));
  }

  Expr _parsePostfix(Expr node) {
    while (true) {
      if (_atSymbol(['['])) {
        _advance();
        final index = _parseExpression();
        _expectSymbol(']');
        node = IndexExpr(node.line, node, index);
      } else if (_atSymbol(['.'])) {
        _advance();
        final field = _expectIdentifier().word;
        node = FieldExpr(node.line, node, field);
      } else if (_atSymbol(['(']) && node is VarExpr) {
        _advance();
        final args = <Expr>[];
        if (!_atSymbol([')'])) {
          args.add(_parseExpression());
          while (_atSymbol([','])) {
            _advance();
            args.add(_parseExpression());
          }
        }
        _expectSymbol(')');
        node = CallExpr(node.line, node.name, args);
      } else {
        return node;
      }
    }
  }

  // ------------------------------------------------------------ expresiones
  Expr _parseExpression() => _parseOr();

  Expr _parseOr() {
    var left = _parseAnd();
    while (_atWord(['o'])) {
      final line = _advance().line;
      left = BinaryExpr(line, 'o', left, _parseAnd());
    }
    return left;
  }

  Expr _parseAnd() {
    var left = _parseNot();
    while (_atWord(['y'])) {
      final line = _advance().line;
      left = BinaryExpr(line, 'y', left, _parseNot());
    }
    return left;
  }

  Expr _parseNot() {
    if (_atWord(['no'])) {
      final line = _advance().line;
      return UnaryExpr(line, 'no', _parseNot());
    }
    return _parseComparison();
  }

  Expr _parseComparison() {
    var left = _parseAdditive();
    while (_atSymbol(['==', '!=', '<', '<=', '>', '>='])) {
      final token = _advance();
      left = BinaryExpr(
          token.line, token.value as String, left, _parseAdditive());
    }
    return left;
  }

  Expr _parseAdditive() {
    var left = _parseMultiplicative();
    while (_atSymbol(['+', '-'])) {
      final token = _advance();
      left = BinaryExpr(
          token.line, token.value as String, left, _parseMultiplicative());
    }
    return left;
  }

  Expr _parseMultiplicative() {
    var left = _parseUnary();
    while (_atSymbol(['*', '/', '%']) || _atWord(['mod'])) {
      final token = _advance();
      final raw = token.value.toString().toLowerCase();
      final op = raw == 'mod' ? '%' : raw;
      left = BinaryExpr(token.line, op, left, _parseUnary());
    }
    return left;
  }

  Expr _parseUnary() {
    if (_atSymbol(['-'])) {
      final token = _advance();
      return UnaryExpr(token.line, '-', _parseUnary());
    }
    return _parsePrimary();
  }

  Expr _parsePrimary() {
    final token = _peek;
    switch (token.type) {
      case TokenType.number:
        _advance();
        return NumLit(token.line, token.value as num);
      case TokenType.text:
        _advance();
        return TextLit(token.line, token.value as String);
      case TokenType.keyword:
        if (token.value == 'verdadero' || token.value == 'falso') {
          _advance();
          return BoolLit(token.line, token.value == 'verdadero');
        }
        if (token.value == 'objeto') {
          _advance();
          _expectSymbol('(');
          final pairs = <MapEntry<String, Expr>>[];
          if (!_atSymbol([')'])) {
            while (true) {
              final key = _expectIdentifier().word;
              _expectSymbol(':');
              pairs.add(MapEntry(key, _parseExpression()));
              if (_atSymbol([','])) {
                _advance();
                continue;
              }
              break;
            }
          }
          _expectSymbol(')');
          return ObjectLit(token.line, pairs);
        }
        throw EduParseError('Expresión no válida cerca de "${token.value}".',
            line: token.line);
      case TokenType.symbol:
        if (token.value == '(') {
          _advance();
          final expr = _parseExpression();
          _expectSymbol(')');
          return expr;
        }
        if (token.value == '[') {
          _advance();
          final items = <Expr>[];
          if (!_atSymbol([']'])) {
            items.add(_parseExpression());
            while (_atSymbol([','])) {
              _advance();
              items.add(_parseExpression());
            }
          }
          _expectSymbol(']');
          return ArrayLit(token.line, items);
        }
        throw EduParseError('Expresión no válida cerca de "${token.value}".',
            line: token.line);
      case TokenType.identifier:
        return _parsePostfixTarget();
      case TokenType.newline:
      case TokenType.eof:
        throw EduParseError('Falta una expresión.',
            line: token.line,
            hint: 'Revisa si una instrucción quedó incompleta.');
    }
  }
}

List<Stmt> parseProgram(String source) => Parser(tokenize(source)).parseProgram();
