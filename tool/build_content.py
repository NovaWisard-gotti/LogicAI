# -*- coding: utf-8 -*-
"""Valida todo el contenido contra el motor y exporta los assets JSON."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from engine import run_code  # noqa: E402
from content import MODULES, EXERCISES, LAB_SAMPLES, REFERENCE, SKILLS  # noqa: E402

errors = []
report = []


def fill(code, mapping):
    out = code
    for k, v in mapping.items():
        out = out.replace('{{%s}}' % k, v)
    return out


def assemble(blocks, order):
    by_id = {b['id']: b for b in blocks}
    lines = []
    for bid in order:
        b = by_id[bid]
        lines.append('    ' * b.get('indent', 0) + b['text'])
    return '\n'.join(lines)


def run_ok(code, inputs=None, label=''):
    r = run_code(code, inputs)
    if r.status != 'ok':
        errors.append(f'{label}: estado {r.status} -> {r.message} (linea {r.error_line})')
    return r


def tests_of(ex):
    """Casos de prueba de un ejercicio (siempre al menos uno)."""
    ts = ex.get('tests')
    if ts:
        return [{'label': t.get('label', f'Caso {i + 1}'), 'inputs': list(t.get('inputs', []))}
                for i, t in enumerate(ts)]
    return [{'label': 'Caso único', 'inputs': list(ex.get('inputs') or [])}]


def run_suite(code, tests):
    """Devuelve (ok, [salidas por caso])."""
    outs = []
    ok = True
    for t in tests:
        r = run_code(code, list(t['inputs']))
        if r.status != 'ok':
            ok = False
        outs.append(r.output)
    return ok, outs


out_exercises = []
for ex in EXERCISES:
    ex = dict(ex)
    kind = ex['kind']
    label = ex['id']
    tests = tests_of(ex)
    ex['tests'] = tests
    inputs = tests[0]['inputs']

    if kind == 'trace':
        r = run_ok(ex['code'], inputs, label)
        ex['expected'] = r.output
        ex['expectedByTest'] = [r.output]
        ex['steps'] = len(r.steps)
    elif kind == 'predict':
        r = run_ok(ex['code'], inputs, label)
        ex['expected'] = r.output
        ex['expectedByTest'] = [r.output]
        q = ex['question']
        declared = q['options'][q['answer']]
        real = ' '.join(r.output) if r.output else ''
        report.append(f'  PREDICT {label}: opcion declarada="{declared}" | salida real="{real}"')
    elif kind == 'complete':
        answers = {b['id']: b['answer'] for b in ex['blanks']}
        solution = fill(ex['code'], answers)
        ok, expected = run_suite(solution, tests)
        if not ok:
            errors.append(f'{label}: la solucion falla en algun caso de prueba')
        ex['solution'] = solution
        ex['expected'] = expected[0]
        ex['expectedByTest'] = expected
        # cada opcion incorrecta debe fallar en al menos un caso de prueba
        for b in ex['blanks']:
            for opt in b['options']:
                if opt == b['answer']:
                    continue
                probe = dict(answers)
                probe[b['id']] = opt
                okk, outs = run_suite(fill(ex['code'], probe), tests)
                if okk and outs == expected:
                    errors.append(
                        f'{label}: la opcion incorrecta "{opt}" en {b["id"]} pasa todos los casos')
    elif kind == 'build':
        solution = assemble(ex['blocks'], ex['order'])
        ok, expected = run_suite(solution, tests)
        if not ok:
            errors.append(f'{label}: la solucion falla en algun caso de prueba')
        ex['solution'] = solution
        ex['expected'] = expected[0]
        ex['expectedByTest'] = expected
        ids = {b['id'] for b in ex['blocks']}
        for bid in ex['order']:
            if bid not in ids:
                errors.append(f'{label}: el bloque {bid} del orden no existe')
        needed = {b['id'] for b in ex['blocks'] if not b.get('distractor')}
        if needed != set(ex['order']):
            errors.append(f'{label}: los bloques no distractores no coinciden con el orden')
        if not [b for b in ex['blocks'] if b.get('distractor')]:
            errors.append(f'{label}: no tiene bloques distractores')
    elif kind == 'repair':
        ok, expected = run_suite(ex['solution'], tests)
        if not ok:
            errors.append(f'{label}: la solucion falla en algun caso de prueba')
        ex['expected'] = expected[0]
        ex['expectedByTest'] = expected
        okb, outs = run_suite(ex['code'], tests)
        if okb and outs == expected:
            errors.append(f'{label}: el programa "con error" ya produce la salida correcta')
        report.append(f'  REPAIR {label}: buggy_ok={okb} salida={outs[0][:6]} | esperado={expected[0]}')
    else:
        errors.append(f'{label}: tipo desconocido {kind}')

    out_exercises.append(ex)

# teoría y ejemplos del laboratorio / referencia también deben ejecutar
for m in MODULES:
    for t in m['theory']:
        if t.get('code'):
            run_ok(t['code'], None, f'teoria {m["id"]}::{t["title"]}')

for s in LAB_SAMPLES:
    code = s['code'].strip()
    if code not in ('inicio\n    \nfin', 'inicio\nfin'):
        run_ok(s['code'], None, f'lab::{s["title"]}')

for sec in REFERENCE:
    for it in sec['items']:
        c = it['code']
        if 'longitud(a)' in c or 'notas[2] = 20' in c or c.startswith('mostrar p.nombre'):
            continue  # fragmentos parciales, no programas completos
        r = run_code(c)
        if r.status == 'sintaxis':
            errors.append(f'referencia {sec["id"]}: no parsea -> {r.message}')

print('\n'.join(report))
if errors:
    print('\n*** PROBLEMAS ***')
    for e in errors:
        print(' -', e)
    sys.exit(1)

modules = list(MODULES)
for m in modules:
    m['exercises'] = [e['id'] for e in out_exercises if e['module'] == m['id']]

data = {
    'version': 1,
    'modules': modules,
    'exercises': out_exercises,
    'challenges': [e['id'] for e in out_exercises if e['module'] == 'retos'],
    'debugWorkshop': [e['id'] for e in out_exercises if e['kind'] == 'repair'],
    'labSamples': LAB_SAMPLES,
    'reference': REFERENCE,
    'skills': SKILLS,
}

_default = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    'assets', 'content', 'content.json')
dest = sys.argv[1] if len(sys.argv) > 1 else _default
os.makedirs(os.path.dirname(dest), exist_ok=True)
with open(dest, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=1)

print(f'\nOK: {len(out_exercises)} ejercicios validados -> {dest}')
print('   retos:', len(data['challenges']), '| taller de depuracion:', len(data['debugWorkshop']))
