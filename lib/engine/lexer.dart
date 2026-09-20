import 'errors.dart';

enum TokenType { keyword, identifier, number, text, symbol, newline, eof }

class Token {
  Token(this.type, this.value, this.line, {this.start = 0, this.end = 0});

  final TokenType type;
  final Object? value;
  final int line;
  final int start;
  final int end;

  String get word => value is String ? value as String : '';

  @override
  String toString() => '${type.name}:$value@$line';
}

/// Palabras reservadas duras: no pueden usarse como nombre de variable.
const Set<String> kHardKeywords = {
  'inicio', 'fin', 'si', 'entonces', 'sino', 'fin_si', 'mientras',
  'fin_mientras', 'para', 'fin_para', 'funcion', 'retornar', 'fin_funcion',
  'mostrar', 'leer', 'arreglo', 'verdadero', 'falso', 'objeto',
};

/// Palabras contextuales: son operadores o marcadores solo en la posición
/// adecuada, de modo que `y = 2` o `paso = 3` siguen siendo válidas.
const Set<String> kSoftWords = {'y', 'o', 'no', 'mod', 'hasta', 'paso', 'hacer'};

const List<String> kBuiltins = [
  'longitud', 'entero', 'redondear', 'absoluto', 'maximo', 'minimo',
  'texto', 'numero', 'residuo', 'potencia',
];

const List<String> _symbols = [
  '==', '!=', '<=', '>=', '<', '>', '=', '+', '-', '*', '/', '%',
  '(', ')', '[', ']', ',', ':', '.',
];

const String _letters =
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_áéíóúñÁÉÍÓÚÑüÜ';
const String _digits = '0123456789';

bool _isLetter(String c) => _letters.contains(c);
bool _isDigit(String c) => _digits.contains(c);

/// Convierte el pseudocódigo en tokens. Las nuevas líneas son significativas:
/// separan instrucciones.
List<Token> tokenize(String source) {
  final tokens = <Token>[];
  var i = 0;
  var line = 1;
  final n = source.length;

  while (i < n) {
    final c = source[i];
    if (c == '\n') {
      tokens.add(Token(TokenType.newline, '\n', line, start: i, end: i + 1));
      line++;
      i++;
      continue;
    }
    if (c == ' ' || c == '\t' || c == '\r') {
      i++;
      continue;
    }
    if (c == '/' && i + 1 < n && source[i + 1] == '/') {
      while (i < n && source[i] != '\n') {
        i++;
      }
      continue;
    }
    if (c == '"') {
      final start = i;
      i++;
      final buffer = StringBuffer();
      while (i < n && source[i] != '"') {
        if (source[i] == '\n') {
          throw EduParseError('Falta cerrar las comillas del texto.',
              line: line, hint: 'Cada texto debe abrir y cerrar con ".');
        }
        buffer.write(source[i]);
        i++;
      }
      if (i >= n) {
        throw EduParseError('Falta cerrar las comillas del texto.',
            line: line, hint: 'Cada texto debe abrir y cerrar con ".');
      }
      i++;
      tokens.add(Token(TokenType.text, buffer.toString(), line,
          start: start, end: i));
      continue;
    }
    if (_isDigit(c)) {
      final start = i;
      final buffer = StringBuffer();
      var dots = 0;
      while (i < n && (_isDigit(source[i]) || source[i] == '.')) {
        if (source[i] == '.') {
          // Un punto solo forma parte del número si le sigue un dígito.
          if (i + 1 >= n || !_isDigit(source[i + 1])) break;
          dots++;
        }
        buffer.write(source[i]);
        i++;
      }
      final raw = buffer.toString();
      if (dots > 1) {
        throw EduParseError('Número no válido: $raw', line: line);
      }
      final num value = dots == 1 ? double.parse(raw) : int.parse(raw);
      tokens.add(Token(TokenType.number, value, line, start: start, end: i));
      continue;
    }
    if (_isLetter(c)) {
      final start = i;
      final buffer = StringBuffer();
      while (i < n && (_isLetter(source[i]) || _isDigit(source[i]))) {
        buffer.write(source[i]);
        i++;
      }
      final word = buffer.toString();
      final lower = word.toLowerCase();
      tokens.add(Token(
        kHardKeywords.contains(lower) ? TokenType.keyword : TokenType.identifier,
        kHardKeywords.contains(lower) ? lower : word,
        line,
        start: start,
        end: i,
      ));
      continue;
    }
    String? matched;
    for (final s in _symbols) {
      if (source.startsWith(s, i)) {
        matched = s;
        break;
      }
    }
    if (matched != null) {
      tokens.add(Token(TokenType.symbol, matched, line,
          start: i, end: i + matched.length));
      i += matched.length;
      continue;
    }
    throw EduParseError('Carácter no reconocido: "$c"',
        line: line, hint: 'Revisa símbolos extraños o teclado en otro idioma.');
  }
  tokens.add(Token(TokenType.eof, null, line, start: n, end: n));
  return tokens;
}
