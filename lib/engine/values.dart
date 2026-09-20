/// Valores del motor educativo de LogicAI.
///
/// Se usan tipos Dart nativos para números (`num`), textos (`String`),
/// lógicos (`bool`) y arreglos (`List<Object?>`). Los objetos educativos se
/// representan con [ObjValue], una abstracción sencilla con atributos con
/// nombre: no pretende imitar la memoria real del computador.
library;

class ObjValue {
  ObjValue(this.fields);

  final Map<String, Object?> fields;

  ObjValue copy() => ObjValue(Map<String, Object?>.from(fields));
}

/// Formato educativo de un valor (lo que se ve en memoria y en la salida).
String fmt(Object? value) {
  if (value == null) return 'sin valor';
  if (value is bool) return value ? 'verdadero' : 'falso';
  if (value is int) return value.toString();
  if (value is double) {
    if ((value - value.roundToDouble()).abs() < 1e-9) {
      return value.round().toString();
    }
    var text = value.toStringAsFixed(4);
    while (text.contains('.') && (text.endsWith('0'))) {
      text = text.substring(0, text.length - 1);
    }
    if (text.endsWith('.')) text = text.substring(0, text.length - 1);
    return text;
  }
  if (value is String) return value;
  if (value is List) return '[${value.map(fmt).join(', ')}]';
  if (value is ObjValue) {
    return '{${value.fields.entries.map((e) => '${e.key}: ${fmt(e.value)}').join(', ')}}';
  }
  return value.toString();
}

/// Etiqueta de tipo con vocabulario educativo (no técnico de un lenguaje real).
String typeLabel(Object? value) {
  if (value is bool) return 'lógico';
  if (value is num) return 'número';
  if (value is String) return 'texto';
  if (value is List) return 'arreglo';
  if (value is ObjValue) return 'objeto';
  return 'sin valor';
}

bool valuesEqual(Object? a, Object? b) {
  if (a is bool || b is bool) {
    if (a is! bool || b is! bool) return false;
    return a == b;
  }
  if (a is num && b is num) return (a - b).abs() < 1e-9;
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!valuesEqual(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is ObjValue && b is ObjValue) {
    if (a.fields.length != b.fields.length) return false;
    for (final entry in a.fields.entries) {
      if (!b.fields.containsKey(entry.key)) return false;
      if (!valuesEqual(entry.value, b.fields[entry.key])) return false;
    }
    return true;
  }
  return a == b;
}
