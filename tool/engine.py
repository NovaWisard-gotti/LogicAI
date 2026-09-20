"""Espejo en Python del motor educativo de LogicAI.

Se usa SOLO en tiempo de autoría para validar la gramática y todo el contenido
(ejercicios, soluciones de referencia, opciones de los huecos, bloques).
El motor Dart de la app replica exactamente este algoritmo.
"""

# Palabras reservadas duras: nunca pueden ser nombres de variables.
KEYWORDS = {
    'inicio', 'fin', 'si', 'entonces', 'sino', 'fin_si', 'mientras',
    'fin_mientras', 'para', 'fin_para', 'funcion', 'retornar', 'fin_funcion',
    'mostrar', 'leer', 'arreglo', 'verdadero', 'falso', 'objeto',
}

# Palabras contextuales: funcionan como operadores/marcadores solo en la
# posicion adecuada, por lo que "y = 2" o "paso = 3" siguen siendo validas.
SOFT_WORDS = {'y', 'o', 'no', 'mod', 'hasta', 'paso', 'hacer'}

SYMBOLS = ['==', '!=', '<=', '>=', '<', '>', '=', '+', '-', '*', '/', '%',
           '(', ')', '[', ']', ',', ':', '.']


class EduError(Exception):
    def __init__(self, message, line=0, hint=None):
        super().__init__(message)
        self.message = message
        self.line = line
        self.hint = hint


class ParseError(EduError):
    pass


class RuntimeEduError(EduError):
    pass


class Token:
    def __init__(self, type_, value, line):
        self.type = type_      # kw, id, num, str, sym, nl, eof
        self.value = value
        self.line = line

    def __repr__(self):
        return f'<{self.type}:{self.value}@{self.line}>'


LETTERS = set('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_áéíóúñÁÉÍÓÚÑü')
DIGITS = set('0123456789')


def tokenize(src):
    tokens = []
    i = 0
    line = 1
    n = len(src)
    while i < n:
        c = src[i]
        if c == '\n':
            tokens.append(Token('nl', '\n', line))
            line += 1
            i += 1
            continue
        if c in ' \t\r':
            i += 1
            continue
        if c == '/' and i + 1 < n and src[i + 1] == '/':
            while i < n and src[i] != '\n':
                i += 1
            continue
        if c == '"':
            i += 1
            buf = ''
            while i < n and src[i] != '"':
                if src[i] == '\n':
                    raise ParseError('Cadena de texto sin cerrar', line)
                buf += src[i]
                i += 1
            if i >= n:
                raise ParseError('Cadena de texto sin cerrar', line)
            i += 1
            tokens.append(Token('str', buf, line))
            continue
        if c in DIGITS:
            buf = ''
            while i < n and (src[i] in DIGITS or src[i] == '.'):
                buf += src[i]
                i += 1
            if buf.count('.') > 1:
                raise ParseError(f'Número inválido: {buf}', line)
            value = float(buf) if '.' in buf else int(buf)
            tokens.append(Token('num', value, line))
            continue
        if c in LETTERS:
            buf = ''
            while i < n and (src[i] in LETTERS or src[i] in DIGITS):
                buf += src[i]
                i += 1
            low = buf.lower()
            if low in KEYWORDS:
                tokens.append(Token('kw', low, line))
            else:
                tokens.append(Token('id', buf, line))
            continue
        matched = None
        for s in SYMBOLS:
            if src.startswith(s, i):
                matched = s
                break
        if matched:
            tokens.append(Token('sym', matched, line))
            i += len(matched)
            continue
        raise ParseError(f'Carácter no reconocido: "{c}"', line)
    tokens.append(Token('eof', None, line))
    return tokens


# ---------------------------------------------------------------- AST
class Node:
    def __init__(self, line):
        self.line = line


class NumLit(Node):
    def __init__(self, line, value):
        super().__init__(line); self.value = value


class StrLit(Node):
    def __init__(self, line, value):
        super().__init__(line); self.value = value


class BoolLit(Node):
    def __init__(self, line, value):
        super().__init__(line); self.value = value


class VarExpr(Node):
    def __init__(self, line, name):
        super().__init__(line); self.name = name


class IndexExpr(Node):
    def __init__(self, line, target, index):
        super().__init__(line); self.target = target; self.index = index


class FieldExpr(Node):
    def __init__(self, line, target, field):
        super().__init__(line); self.target = target; self.field = field


class Unary(Node):
    def __init__(self, line, op, expr):
        super().__init__(line); self.op = op; self.expr = expr


class Binary(Node):
    def __init__(self, line, op, left, right):
        super().__init__(line); self.op = op; self.left = left; self.right = right


class Call(Node):
    def __init__(self, line, name, args):
        super().__init__(line); self.name = name; self.args = args


class ArrayLit(Node):
    def __init__(self, line, items):
        super().__init__(line); self.items = items


class ObjectLit(Node):
    def __init__(self, line, pairs):
        super().__init__(line); self.pairs = pairs


class Assign(Node):
    def __init__(self, line, target, value):
        super().__init__(line); self.target = target; self.value = value


class ArrayDecl(Node):
    def __init__(self, line, name, size):
        super().__init__(line); self.name = name; self.size = size


class Print(Node):
    def __init__(self, line, args):
        super().__init__(line); self.args = args


class Read(Node):
    def __init__(self, line, name):
        super().__init__(line); self.name = name


class If(Node):
    def __init__(self, line, cond, then, other):
        super().__init__(line); self.cond = cond; self.then = then; self.other = other


class While(Node):
    def __init__(self, line, cond, body):
        super().__init__(line); self.cond = cond; self.body = body


class For(Node):
    def __init__(self, line, var, start, end, step, body):
        super().__init__(line); self.var = var; self.start = start
        self.end = end; self.step = step; self.body = body


class FuncDecl(Node):
    def __init__(self, line, name, params, body):
        super().__init__(line); self.name = name; self.params = params; self.body = body


class Return(Node):
    def __init__(self, line, value):
        super().__init__(line); self.value = value


class ExprStmt(Node):
    def __init__(self, line, expr):
        super().__init__(line); self.expr = expr


# ---------------------------------------------------------------- Parser
class Parser:
    def __init__(self, tokens):
        self.t = tokens
        self.p = 0

    def peek(self):
        return self.t[self.p]

    def at_kw(self, *kws):
        tk = self.peek()
        return tk.type == 'kw' and tk.value in kws

    def at_word(self, *words):
        tk = self.peek()
        return tk.type == 'id' and tk.value.lower() in words

    def expect_word(self, word):
        tk = self.next()
        if tk.type != 'id' or tk.value.lower() != word:
            raise ParseError(f'Se esperaba "{word}"', tk.line)
        return tk

    def at_sym(self, *syms):
        tk = self.peek()
        return tk.type == 'sym' and tk.value in syms

    def next(self):
        tk = self.t[self.p]
        self.p += 1
        return tk

    def expect_sym(self, s):
        tk = self.next()
        if tk.type != 'sym' or tk.value != s:
            raise ParseError(f'Se esperaba "{s}"', tk.line)
        return tk

    def expect_kw(self, k):
        tk = self.next()
        if tk.type != 'kw' or tk.value != k:
            raise ParseError(f'Se esperaba "{k}"', tk.line)
        return tk

    def expect_id(self):
        tk = self.next()
        if tk.type != 'id':
            raise ParseError('Se esperaba el nombre de una variable', tk.line)
        return tk

    def skip_nl(self):
        while self.peek().type == 'nl':
            self.next()

    def end_of_stmt(self):
        tk = self.peek()
        if tk.type in ('nl', 'eof'):
            return
        raise ParseError(f'Instrucción no reconocida cerca de "{tk.value}"', tk.line)

    def parse_program(self):
        stmts = []
        self.skip_nl()
        if self.at_kw('inicio'):
            self.next()
            self.skip_nl()
        while True:
            self.skip_nl()
            tk = self.peek()
            if tk.type == 'eof':
                break
            if tk.type == 'kw' and tk.value == 'fin':
                self.next()
                self.skip_nl()
                break
            stmts.append(self.parse_statement())
        return stmts

    def parse_block(self, *terminators):
        stmts = []
        while True:
            self.skip_nl()
            tk = self.peek()
            if tk.type == 'eof':
                raise ParseError(
                    'El bloque no fue cerrado (falta %s)' % ' o '.join(terminators),
                    tk.line)
            if tk.type == 'kw' and tk.value in terminators:
                break
            stmts.append(self.parse_statement())
        return stmts

    def parse_statement(self):
        tk = self.peek()
        line = tk.line
        if tk.type == 'kw':
            v = tk.value
            if v == 'mostrar':
                self.next()
                args = [self.parse_expr()]
                while self.at_sym(','):
                    self.next()
                    args.append(self.parse_expr())
                self.end_of_stmt()
                return Print(line, args)
            if v == 'leer':
                self.next()
                name = self.expect_id().value
                self.end_of_stmt()
                return Read(line, name)
            if v == 'arreglo':
                self.next()
                name = self.expect_id().value
                self.expect_sym('[')
                size = self.parse_expr()
                self.expect_sym(']')
                self.end_of_stmt()
                return ArrayDecl(line, name, size)
            if v == 'si':
                return self.parse_if()
            if v == 'mientras':
                self.next()
                cond = self.parse_expr()
                if self.at_word('hacer'):
                    self.next()
                self.end_of_stmt()
                body = self.parse_block('fin_mientras')
                self.expect_kw('fin_mientras')
                self.end_of_stmt()
                return While(line, cond, body)
            if v == 'para':
                self.next()
                var = self.expect_id().value
                self.expect_sym('=')
                start = self.parse_expr()
                self.expect_word('hasta')
                end = self.parse_expr()
                step = None
                if self.at_word('paso'):
                    self.next()
                    step = self.parse_expr()
                if self.at_word('hacer'):
                    self.next()
                self.end_of_stmt()
                body = self.parse_block('fin_para')
                self.expect_kw('fin_para')
                self.end_of_stmt()
                return For(line, var, start, end, step, body)
            if v == 'funcion':
                self.next()
                name = self.expect_id().value
                params = []
                self.expect_sym('(')
                if not self.at_sym(')'):
                    params.append(self.expect_id().value)
                    while self.at_sym(','):
                        self.next()
                        params.append(self.expect_id().value)
                self.expect_sym(')')
                self.end_of_stmt()
                body = self.parse_block('fin_funcion')
                self.expect_kw('fin_funcion')
                self.end_of_stmt()
                return FuncDecl(line, name, params, body)
            if v == 'retornar':
                self.next()
                value = None
                if self.peek().type not in ('nl', 'eof'):
                    value = self.parse_expr()
                self.end_of_stmt()
                return Return(line, value)
            raise ParseError(f'No se esperaba "{v}" aquí', line)
        if tk.type == 'id':
            target = self.parse_postfix_target()
            if self.at_sym('='):
                self.next()
                value = self.parse_expr()
                self.end_of_stmt()
                return Assign(line, target, value)
            if isinstance(target, Call):
                self.end_of_stmt()
                return ExprStmt(line, target)
            raise ParseError('Se esperaba una asignación con "="', line)
        raise ParseError(f'Instrucción no reconocida cerca de "{tk.value}"', line)

    def parse_if(self):
        line = self.peek().line
        self.expect_kw('si')
        cond = self.parse_expr()
        self.expect_kw('entonces')
        self.end_of_stmt()
        then = self.parse_block('sino', 'fin_si')
        other = []
        if self.at_kw('sino'):
            self.next()
            if self.at_kw('si'):
                other = [self.parse_if()]
                return If(line, cond, then, other)
            self.end_of_stmt()
            other = self.parse_block('fin_si')
        self.expect_kw('fin_si')
        self.end_of_stmt()
        return If(line, cond, then, other)

    def parse_postfix_target(self):
        tk = self.expect_id()
        node = VarExpr(tk.line, tk.value)
        return self.parse_postfix(node)

    def parse_postfix(self, node):
        while True:
            if self.at_sym('['):
                self.next()
                idx = self.parse_expr()
                self.expect_sym(']')
                node = IndexExpr(node.line, node, idx)
            elif self.at_sym('.'):
                self.next()
                fld = self.expect_id().value
                node = FieldExpr(node.line, node, fld)
            elif self.at_sym('(') and isinstance(node, VarExpr):
                self.next()
                args = []
                if not self.at_sym(')'):
                    args.append(self.parse_expr())
                    while self.at_sym(','):
                        self.next()
                        args.append(self.parse_expr())
                self.expect_sym(')')
                node = Call(node.line, node.name, args)
            else:
                return node

    # expressions
    def parse_expr(self):
        return self.parse_or()

    def parse_or(self):
        left = self.parse_and()
        while self.at_word('o'):
            line = self.next().line
            right = self.parse_and()
            left = Binary(line, 'o', left, right)
        return left

    def parse_and(self):
        left = self.parse_not()
        while self.at_word('y'):
            line = self.next().line
            right = self.parse_not()
            left = Binary(line, 'y', left, right)
        return left

    def parse_not(self):
        if self.at_word('no'):
            line = self.next().line
            return Unary(line, 'no', self.parse_not())
        return self.parse_comparison()

    def parse_comparison(self):
        left = self.parse_additive()
        while self.at_sym('==', '!=', '<', '<=', '>', '>='):
            tk = self.next()
            right = self.parse_additive()
            left = Binary(tk.line, tk.value, left, right)
        return left

    def parse_additive(self):
        left = self.parse_multiplicative()
        while self.at_sym('+', '-'):
            tk = self.next()
            right = self.parse_multiplicative()
            left = Binary(tk.line, tk.value, left, right)
        return left

    def parse_multiplicative(self):
        left = self.parse_unary()
        while self.at_sym('*', '/', '%') or self.at_word('mod'):
            tk = self.next()
            op = '%' if str(tk.value).lower() == 'mod' else tk.value
            right = self.parse_unary()
            left = Binary(tk.line, op, left, right)
        return left

    def parse_unary(self):
        if self.at_sym('-'):
            tk = self.next()
            return Unary(tk.line, '-', self.parse_unary())
        return self.parse_primary()

    def parse_primary(self):
        tk = self.peek()
        if tk.type == 'num':
            self.next()
            return NumLit(tk.line, tk.value)
        if tk.type == 'str':
            self.next()
            return StrLit(tk.line, tk.value)
        if tk.type == 'kw' and tk.value in ('verdadero', 'falso'):
            self.next()
            return BoolLit(tk.line, tk.value == 'verdadero')
        if tk.type == 'kw' and tk.value == 'objeto':
            self.next()
            self.expect_sym('(')
            pairs = []
            if not self.at_sym(')'):
                while True:
                    key = self.expect_id().value
                    self.expect_sym(':')
                    pairs.append((key, self.parse_expr()))
                    if self.at_sym(','):
                        self.next()
                        continue
                    break
            self.expect_sym(')')
            return ObjectLit(tk.line, pairs)
        if tk.type == 'sym' and tk.value == '(':
            self.next()
            e = self.parse_expr()
            self.expect_sym(')')
            return e
        if tk.type == 'sym' and tk.value == '[':
            self.next()
            items = []
            if not self.at_sym(']'):
                items.append(self.parse_expr())
                while self.at_sym(','):
                    self.next()
                    items.append(self.parse_expr())
            self.expect_sym(']')
            return ArrayLit(tk.line, items)
        if tk.type == 'id':
            return self.parse_postfix_target()
        raise ParseError(f'Expresión no válida cerca de "{tk.value}"', tk.line)


def parse(src):
    return Parser(tokenize(src)).parse_program()


# ---------------------------------------------------------------- values
class ObjVal:
    def __init__(self, fields):
        self.fields = fields


def fmt(value):
    if value is None:
        return 'sin valor'
    if isinstance(value, bool):
        return 'verdadero' if value else 'falso'
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        if abs(value - round(value)) < 1e-9:
            return str(int(round(value)))
        return f'{value:.4f}'.rstrip('0').rstrip('.')
    if isinstance(value, str):
        return value
    if isinstance(value, list):
        return '[' + ', '.join(fmt(v) for v in value) + ']'
    if isinstance(value, ObjVal):
        return '{' + ', '.join(f'{k}: {fmt(v)}' for k, v in value.fields.items()) + '}'
    return str(value)


def type_label(value):
    if isinstance(value, bool):
        return 'lógico'
    if isinstance(value, (int, float)):
        return 'número'
    if isinstance(value, str):
        return 'texto'
    if isinstance(value, list):
        return 'arreglo'
    if isinstance(value, ObjVal):
        return 'objeto'
    return 'sin valor'


class ReturnSignal(Exception):
    def __init__(self, value):
        self.value = value


class StepLimit(Exception):
    pass


class Step:
    def __init__(self, index, line, action, note, variables, output, scope):
        self.index = index
        self.line = line
        self.action = action
        self.note = note
        self.variables = variables
        self.output = output
        self.scope = scope


class Result:
    def __init__(self):
        self.steps = []
        self.output = []
        self.status = 'ok'      # ok | limite | error | sintaxis
        self.message = None
        self.error_line = 0
        self.hint = None


class Interpreter:
    MAX_STEPS = 600
    MAX_DEPTH = 24

    def __init__(self, inputs=None, max_steps=None):
        self.inputs = list(inputs or [])
        self.max_steps = max_steps or Interpreter.MAX_STEPS
        self.result = Result()
        self.functions = {}
        self.scopes = [('principal', {})]
        self.changed = None
        self.depth = 0

    # -- scope helpers
    @property
    def current(self):
        return self.scopes[-1][1]

    def get_var(self, name, line):
        sc = self.current
        if name in sc:
            return sc[name]
        raise RuntimeEduError(
            f'La variable "{name}" se usa antes de recibir un valor.', line,
            'Asigna un valor inicial antes de utilizarla.')

    def set_var(self, name, value):
        self.current[name] = value

    def snapshot_vars(self):
        out = []
        for scope_name, vars_ in self.scopes:
            for k, v in vars_.items():
                out.append({
                    'scope': scope_name,
                    'name': k,
                    'value': fmt(v),
                    'type': type_label(v),
                    'changed': self.changed == (scope_name, k),
                })
        return out

    def emit(self, line, action, note=None):
        if len(self.result.steps) >= self.max_steps:
            raise StepLimit()
        self.result.steps.append(Step(
            len(self.result.steps), line, action, note,
            self.snapshot_vars(), list(self.result.output),
            self.scopes[-1][0]))

    # -- run
    def run(self, program):
        try:
            for st in program:
                if isinstance(st, FuncDecl):
                    self.functions[st.name] = st
            self.exec_block([s for s in program if not isinstance(s, FuncDecl)])
        except StepLimit:
            self.result.status = 'limite'
            self.result.message = (
                'La ejecución se detuvo porque el programa superó el límite de '
                f'{self.max_steps} pasos. Revisa la condición del ciclo.')
        except ReturnSignal:
            pass
        except RuntimeEduError as e:
            self.result.status = 'error'
            self.result.message = e.message
            self.result.error_line = e.line
            self.result.hint = e.hint
        return self.result

    def exec_block(self, stmts):
        for st in stmts:
            self.exec_stmt(st)

    def exec_stmt(self, st):
        self.changed = None
        if isinstance(st, Assign):
            self.exec_assign(st)
        elif isinstance(st, ArrayDecl):
            size = self.eval(st.size)
            if not isinstance(size, (int, float)) or isinstance(size, bool) or size < 0:
                raise RuntimeEduError('El tamaño del arreglo debe ser un número positivo.', st.line)
            self.set_var(st.name, [0] * int(size))
            self.changed = (self.scopes[-1][0], st.name)
            self.emit(st.line, f'arreglo {st.name}[{int(size)}]',
                      f'Se crea un arreglo de {int(size)} posiciones en 0.')
        elif isinstance(st, Print):
            parts = [fmt(self.eval(a)) for a in st.args]
            text = ' '.join(parts)
            self.result.output.append(text)
            self.emit(st.line, 'mostrar', f'Salida: {text}')
        elif isinstance(st, Read):
            if not self.inputs:
                raise RuntimeEduError(
                    f'No hay más datos de entrada para "leer {st.name}".', st.line,
                    'Este ejercicio define una lista fija de entradas.')
            value = self.inputs.pop(0)
            self.set_var(st.name, value)
            self.changed = (self.scopes[-1][0], st.name)
            self.emit(st.line, f'leer {st.name}', f'Se lee el valor {fmt(value)}.')
        elif isinstance(st, If):
            cond = self.eval_condition(st.cond, st.line)
            self.emit(st.line, 'si',
                      'La condición es ' + ('verdadera' if cond else 'falsa') +
                      (' → se ejecuta el bloque.' if cond else ' → se omite el bloque.'))
            self.exec_block(st.then if cond else st.other)
        elif isinstance(st, While):
            it = 0
            while True:
                cond = self.eval_condition(st.cond, st.line)
                if cond:
                    it += 1
                self.emit(st.line, 'mientras',
                          (f'Condición verdadera → iteración {it}.' if cond
                           else f'Condición falsa → el ciclo termina tras {it} iteraciones.'))
                if not cond:
                    break
                self.exec_block(st.body)
        elif isinstance(st, For):
            start = self.eval(st.start)
            end = self.eval(st.end)
            step = self.eval(st.step) if st.step is not None else 1
            for v in (start, end, step):
                if isinstance(v, bool) or not isinstance(v, (int, float)):
                    raise RuntimeEduError('El ciclo "para" necesita valores numéricos.', st.line)
            if step == 0:
                raise RuntimeEduError('El paso del ciclo "para" no puede ser 0.', st.line)
            self.set_var(st.var, start)
            self.changed = (self.scopes[-1][0], st.var)
            self.emit(st.line, 'para',
                      f'{st.var} inicia en {fmt(start)} y avanza hasta {fmt(end)} de {fmt(step)} en {fmt(step)}.')
            it = 0
            while True:
                cur = self.current.get(st.var)
                cont = cur <= end if step > 0 else cur >= end
                if cont:
                    it += 1
                    self.changed = None
                    self.emit(st.line, 'para',
                              f'{st.var} = {fmt(cur)} → iteración {it}.')
                    self.exec_block(st.body)
                    nxt = self.current.get(st.var) + step
                    self.set_var(st.var, nxt)
                    self.changed = (self.scopes[-1][0], st.var)
                    self.emit(st.line, 'para', f'{st.var} avanza a {fmt(nxt)}.')
                else:
                    self.changed = None
                    self.emit(st.line, 'para',
                              f'{st.var} = {fmt(cur)} ya no cumple el límite → el ciclo termina.')
                    break
        elif isinstance(st, Return):
            value = self.eval(st.value) if st.value is not None else None
            self.emit(st.line, 'retornar', f'Devuelve {fmt(value)}.')
            raise ReturnSignal(value)
        elif isinstance(st, ExprStmt):
            value = self.eval(st.expr)
            if isinstance(st.expr, Call) and st.expr.name in self.functions:
                pass
            else:
                self.emit(st.line, 'llamada', f'Resultado: {fmt(value)}')
        elif isinstance(st, FuncDecl):
            self.functions[st.name] = st
        else:
            raise RuntimeEduError('Instrucción no soportada.', st.line)

    def exec_assign(self, st):
        value = self.eval(st.value)
        t = st.target
        if isinstance(t, VarExpr):
            prev = self.current.get(t.name)
            self.set_var(t.name, value)
            self.changed = (self.scopes[-1][0], t.name)
            if prev is None:
                note = f'Se crea {t.name} con el valor {fmt(value)}.'
            else:
                note = f'{t.name}: {fmt(prev)} → {fmt(value)}'
            self.emit(st.line, f'{t.name} = ...', note)
        elif isinstance(t, IndexExpr):
            container = self.eval(t.target)
            idx = self.eval(t.index)
            if not isinstance(container, list):
                raise RuntimeEduError('Solo se puede indexar un arreglo.', st.line)
            if isinstance(idx, bool) or not isinstance(idx, (int, float)) or int(idx) != idx:
                raise RuntimeEduError('El índice debe ser un número entero.', st.line)
            idx = int(idx)
            if idx < 0 or idx >= len(container):
                raise RuntimeEduError(
                    f'El índice {idx} está fuera del arreglo (0 a {len(container) - 1}).',
                    st.line, 'Los arreglos empiezan en la posición 0.')
            prev = container[idx]
            container[idx] = value
            name = self.base_name(t)
            self.changed = (self.scopes[-1][0], name)
            self.emit(st.line, f'{name}[{idx}] = ...',
                      f'{name}[{idx}]: {fmt(prev)} → {fmt(value)}')
        elif isinstance(t, FieldExpr):
            obj = self.eval(t.target)
            if not isinstance(obj, ObjVal):
                raise RuntimeEduError('Solo un objeto tiene atributos.', st.line)
            prev = obj.fields.get(t.field)
            obj.fields[t.field] = value
            name = self.base_name(t)
            self.changed = (self.scopes[-1][0], name)
            self.emit(st.line, f'{name}.{t.field} = ...',
                      f'{name}.{t.field}: {fmt(prev)} → {fmt(value)}')
        else:
            raise RuntimeEduError('Destino de asignación no válido.', st.line)

    def base_name(self, node):
        while not isinstance(node, VarExpr):
            node = node.target
        return node.name

    def eval_condition(self, expr, line):
        v = self.eval(expr)
        if not isinstance(v, bool):
            raise RuntimeEduError(
                'La condición debe dar verdadero o falso.', line,
                'Usa comparaciones como >=, ==, < o valores lógicos.')
        return v

    def eval(self, e):
        if isinstance(e, NumLit) or isinstance(e, StrLit) or isinstance(e, BoolLit):
            return e.value
        if isinstance(e, VarExpr):
            return self.get_var(e.name, e.line)
        if isinstance(e, ArrayLit):
            return [self.eval(i) for i in e.items]
        if isinstance(e, ObjectLit):
            return ObjVal({k: self.eval(v) for k, v in e.pairs})
        if isinstance(e, IndexExpr):
            c = self.eval(e.target)
            i = self.eval(e.index)
            if not isinstance(c, list):
                raise RuntimeEduError('Solo se puede indexar un arreglo.', e.line)
            if isinstance(i, bool) or not isinstance(i, (int, float)) or int(i) != i:
                raise RuntimeEduError('El índice debe ser un número entero.', e.line)
            i = int(i)
            if i < 0 or i >= len(c):
                raise RuntimeEduError(
                    f'El índice {i} está fuera del arreglo (0 a {len(c) - 1}).', e.line,
                    'Recuerda que la primera posición es 0.')
            return c[i]
        if isinstance(e, FieldExpr):
            o = self.eval(e.target)
            if not isinstance(o, ObjVal):
                raise RuntimeEduError('Solo un objeto tiene atributos.', e.line)
            if e.field not in o.fields:
                raise RuntimeEduError(f'El objeto no tiene el atributo "{e.field}".', e.line)
            return o.fields[e.field]
        if isinstance(e, Unary):
            v = self.eval(e.expr)
            if e.op == '-':
                self.require_num(v, e.line)
                return -v
            if not isinstance(v, bool):
                raise RuntimeEduError('"no" solo se aplica a valores lógicos.', e.line)
            return not v
        if isinstance(e, Binary):
            return self.eval_binary(e)
        if isinstance(e, Call):
            return self.call(e)
        raise RuntimeEduError('Expresión no soportada.', e.line)

    def require_num(self, v, line):
        if isinstance(v, bool) or not isinstance(v, (int, float)):
            raise RuntimeEduError('Se esperaba un valor numérico.', line)

    def eval_binary(self, e):
        op = e.op
        if op in ('y', 'o'):
            left = self.eval(e.left)
            if not isinstance(left, bool):
                raise RuntimeEduError(f'"{op}" necesita valores lógicos.', e.line)
            if op == 'y' and not left:
                return False
            if op == 'o' and left:
                return True
            right = self.eval(e.right)
            if not isinstance(right, bool):
                raise RuntimeEduError(f'"{op}" necesita valores lógicos.', e.line)
            return right
        a = self.eval(e.left)
        b = self.eval(e.right)
        if op == '==':
            return self.equals(a, b)
        if op == '!=':
            return not self.equals(a, b)
        if op in ('<', '<=', '>', '>='):
            if isinstance(a, str) and isinstance(b, str):
                pass
            else:
                self.require_num(a, e.line)
                self.require_num(b, e.line)
            if op == '<':
                return a < b
            if op == '<=':
                return a <= b
            if op == '>':
                return a > b
            return a >= b
        if op == '+':
            if isinstance(a, str) or isinstance(b, str):
                return fmt(a) + fmt(b)
            self.require_num(a, e.line)
            self.require_num(b, e.line)
            return a + b
        self.require_num(a, e.line)
        self.require_num(b, e.line)
        if op == '-':
            return a - b
        if op == '*':
            return a * b
        if op == '/':
            if b == 0:
                raise RuntimeEduError('No se puede dividir entre cero.', e.line)
            r = a / b
            if isinstance(a, int) and isinstance(b, int) and a % b == 0:
                return a // b
            return r
        if op == '%':
            if b == 0:
                raise RuntimeEduError('No se puede calcular el residuo entre cero.', e.line)
            return a % b
        raise RuntimeEduError(f'Operador no soportado: {op}', e.line)

    def equals(self, a, b):
        if isinstance(a, bool) != isinstance(b, bool):
            return False
        if isinstance(a, (int, float)) and isinstance(b, (int, float)):
            return abs(a - b) < 1e-9
        if isinstance(a, list) and isinstance(b, list):
            return len(a) == len(b) and all(self.equals(x, y) for x, y in zip(a, b))
        return a == b

    BUILTINS = {'longitud', 'entero', 'redondear', 'absoluto', 'maximo', 'minimo',
                'texto', 'numero', 'residuo', 'potencia'}

    def call(self, e):
        name = e.name
        if name in self.functions:
            return self.call_user(e)
        if name not in Interpreter.BUILTINS:
            raise RuntimeEduError(
                f'La función "{name}" no existe.', e.line,
                'Revisa el nombre o define la función con "funcion".')
        args = [self.eval(a) for a in e.args]

        def need(n):
            if len(args) != n:
                raise RuntimeEduError(
                    f'"{name}" necesita {n} argumento(s).', e.line)
        if name == 'longitud':
            need(1)
            v = args[0]
            if isinstance(v, list):
                return len(v)
            if isinstance(v, str):
                return len(v)
            raise RuntimeEduError('"longitud" se usa con arreglos o textos.', e.line)
        if name == 'entero':
            need(1); self.require_num(args[0], e.line); return int(args[0])
        if name == 'redondear':
            need(1); self.require_num(args[0], e.line)
            v = args[0]
            f = v - int(v)
            r = int(v) + (1 if f >= 0.5 else 0) if v >= 0 else int(v) - (1 if -f >= 0.5 else 0)
            return r
        if name == 'absoluto':
            need(1); self.require_num(args[0], e.line); return abs(args[0])
        if name == 'maximo':
            need(2); self.require_num(args[0], e.line); self.require_num(args[1], e.line)
            return max(args[0], args[1])
        if name == 'minimo':
            need(2); self.require_num(args[0], e.line); self.require_num(args[1], e.line)
            return min(args[0], args[1])
        if name == 'texto':
            need(1); return fmt(args[0])
        if name == 'numero':
            need(1)
            try:
                s = args[0]
                return float(s) if '.' in str(s) else int(s)
            except Exception:
                raise RuntimeEduError('No se pudo convertir a número.', e.line)
        if name == 'residuo':
            need(2); self.require_num(args[0], e.line); self.require_num(args[1], e.line)
            if args[1] == 0:
                raise RuntimeEduError('No se puede calcular el residuo entre cero.', e.line)
            return args[0] % args[1]
        if name == 'potencia':
            need(2); self.require_num(args[0], e.line); self.require_num(args[1], e.line)
            return args[0] ** args[1]
        raise RuntimeEduError(f'La función "{name}" no existe.', e.line)

    def call_user(self, e):
        decl = self.functions[e.name]
        if len(e.args) != len(decl.params):
            raise RuntimeEduError(
                f'La función "{e.name}" espera {len(decl.params)} parámetro(s) '
                f'y recibió {len(e.args)}.', e.line)
        args = [self.eval(a) for a in e.args]
        if self.depth >= Interpreter.MAX_DEPTH:
            raise RuntimeEduError(
                'Demasiadas llamadas anidadas de funciones.', e.line,
                'Revisa si la función se llama a sí misma sin condición de salida.')
        local = dict(zip(decl.params, args))
        self.scopes.append((e.name, local))
        self.depth += 1
        self.changed = None
        self.emit(e.line, f'llamar {e.name}',
                  'Parámetros: ' + ', '.join(f'{p} = {fmt(v)}' for p, v in local.items())
                  if local else 'Sin parámetros.')
        value = None
        try:
            self.exec_block(decl.body)
        except ReturnSignal as r:
            value = r.value
        finally:
            self.scopes.pop()
            self.depth -= 1
        self.changed = None
        self.emit(e.line, f'fin de {e.name}',
                  f'La función devuelve {fmt(value)}.' if value is not None
                  else f'La función {e.name} termina sin devolver valor.')
        return value


def run_code(src, inputs=None, max_steps=None):
    res = Result()
    try:
        program = parse(src)
    except ParseError as pe:
        res.status = 'sintaxis'
        res.message = pe.message
        res.error_line = pe.line
        return res
    return Interpreter(inputs, max_steps).run(program)
