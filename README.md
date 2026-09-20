# LogicAI

**Laboratorio móvil de lógica de programación para estudiantes universitarios.**

LogicAI no enseña sintaxis de memoria: enseña a entender *por qué* un programa
hace lo que hace. El estudiante construye una solución, la ejecuta paso a paso,
observa cómo cambia la memoria en cada instrucción, se equivoca, ve exactamente
dónde y corrige con evidencia.

```
PROBLEMA → RAZONAMIENTO → CONSTRUCCIÓN → EJECUCIÓN → OBSERVACIÓN
        → ERROR/RESULTADO → CORRECCIÓN → COMPRENSIÓN
```

No es un cuestionario, no es un Duolingo de programación, no es un IDE y no es
un compilador. Es un entorno de observación controlada.

---

## Qué contiene el MVP

| Zona | Qué hace |
|---|---|
| **Inicio** | Estado real del estudiante y el siguiente paso concreto |
| **Módulos** | 7 módulos de fundamentos: variables, operadores, condicionales, ciclos, funciones, arreglos, objetos |
| **Laboratorio** | Pseudocódigo libre con trazador e inspector de memoria; el código se conserva entre sesiones |
| **Retos** | 8 problemas que combinan varios conceptos, con filtros por dificultad y habilidad |
| **Taller de depuración** | 8 programas con fallos reales que hay que localizar y reparar |
| **Progreso** | Avance por módulo y habilidades practicadas, sin puntuaciones artificiales |
| **Historial** | Cada intento, con fecha y resultado, para volver sobre él |
| **Consulta rápida** | Sintaxis del pseudocódigo con buscador, sin salir del trabajo |

**36 ejercicios** repartidos en cinco mecánicas:

- **Trazar** — recorrer un programa y observar el estado en cada paso.
- **Predecir** — anticipar la salida antes de ejecutar, y después comprobarlo.
- **Completar** — elegir la pieza que falta en la lógica.
- **Reparar** — encontrar y corregir el fallo de un programa que se comporta mal.
- **Construir** — armar el algoritmo desde bloques, con distractores.

---

## El motor educativo

LogicAI incluye un intérprete propio de **pseudocódigo estructurado en español**.
No ejecuta código del sistema ni llama a servicios externos: todo ocurre dentro
de un entorno controlado, en el dispositivo.

```
inicio
    notas = [12, 15, 8, 18]
    total = 0
    para i = 0 hasta longitud(notas) - 1
        total = total + notas[i]
    fin_para
    mostrar "Promedio:", total / longitud(notas)
fin
```

Palabras del lenguaje: `inicio`, `fin`, `si`/`entonces`/`sino`/`fin_si`,
`mientras`/`hacer`/`fin_mientras`, `para`/`hasta`/`paso`/`fin_para`,
`funcion`/`retornar`/`fin_funcion`, `mostrar`, `leer`, arreglos `[ ]`,
`objeto(campo: valor)`, `verdadero`/`falso`, operadores `y`, `o`, `no`, `mod`.

Decisiones de diseño que importan:

- **Traza materializada.** El programa se ejecuta una vez y cada paso se guarda
  con su línea, su explicación, la instantánea de la memoria y la salida
  acumulada. Por eso se puede avanzar, **retroceder**, saltar a un paso o
  reproducir automáticamente sin volver a ejecutar nada.
- **Palabras contextuales.** `y`, `o`, `no`, `hasta`, `paso`, `hacer` y `mod`
  son operadores donde toca serlo, pero siguen siendo nombres de variable
  válidos. `paso = 3` no es un error de sintaxis.
- **Protección frente a ciclos infinitos.** Límite de 600 pasos y 24 llamadas
  anidadas. Al alcanzarlo, la ejecución se detiene con un mensaje educativo
  que apunta a la condición del ciclo, no con un bloqueo.
- **Errores que enseñan.** Cada error dice qué pasó, en qué línea, con qué
  variable y qué concepto revisar — nunca solo "incorrecto".
- **Varios casos de prueba.** Los ejercicios con entrada se comprueban con
  entradas distintas, para que una respuesta no pueda acertar por casualidad.

El mismo motor está implementado en Python (`tool/engine.py`, fuera del
paquete de la app) y se usó para validar el catálogo antes de portarlo a Dart.

---

## Arquitectura

MVVM sobre Riverpod, con el motor aislado de la interfaz.

```
lib/
├── engine/        Léxico, análisis sintáctico, intérprete y trazador.
│                  Dart puro: no importa Flutter.
├── data/
│   ├── models/    Contenido educativo y progreso (serializables)
│   └── repositories/  Assets locales y SharedPreferences
├── state/         Vista-modelo: providers, sesión de ejercicio, trazador
├── core/
│   ├── theme/     Identidad visual y colores verificados por contraste
│   └── widgets/   Visor de código, editor por líneas, piezas comunes
└── features/      Una carpeta por zona de la aplicación
```

Detalle en [`docs/ARQUITECTURA.md`](docs/ARQUITECTURA.md).

---

## Instalación y ejecución

Requiere Flutter 3.27 o superior (Dart 3.6+).

```bash
flutter pub get
flutter run
```

Compilar el APK:

```bash
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk
```

> El repositorio incluye el wrapper de Gradle (`gradlew`, `gradlew.bat` y
> `gradle-wrapper.jar`) fijado en la version 8.13, la minima compatible con
> el Android Gradle Plugin del proyecto. Si alguna vez hace falta
> regenerarlo, usa una distribucion de Gradle 8.x (no la que traiga
> preinstalada tu maquina si es 9.6 o superior, porque AGP 8.x no es
> compatible con Gradle 9.6+).

Ejecutar las pruebas:

```bash
flutter analyze
flutter test
```

### Herramientas de autoría (`tool/`, opcionales)

Requieren Python 3.10+. No forman parte de la aplicación.

```bash
python3 tool/build_content.py   # valida y regenera assets/content/content.json
python3 tool/make_icons.py      # regenera los PNG del icono (necesita Pillow)
```

`tool/engine.py` es el mismo motor educativo implementado en Python. Sirve para
validar el catálogo de ejercicios antes de empaquetarlo: `build_content.py`
ejecuta cada solución, comprueba que cada programa "roto" falla de verdad y que
cada opción incorrecta falla en algún caso, y **se niega a escribir el JSON** si
algo no cuadra.

---

## Qué se verifica automáticamente

Las pruebas no son decorativas: el contenido educativo se valida como si fuera
código.

- **`test/engine_test.dart`** — trazado, marcado de la variable que cambia,
  salida acumulada, ciclos infinitos, límite de pasos configurable, errores
  educativos, estructuras del lenguaje, palabras contextuales y verificación
  por casos.
- **`test/content_test.dart`** — cada solución de referencia resuelve todos sus
  casos; cada programa del taller de depuración **falla de verdad**; cada opción
  incorrecta de "completa" falla en algún caso; los distractores no forman parte
  de ninguna solución; cada predicción coincide con la salida real; ningún
  programa del catálogo agota el límite de pasos.
- **`test/theme_test.dart`** — contraste WCAG en los dos temas: los colores de
  sintaxis superan 4.5:1 sobre el fondo del editor, el resalte de memoria no
  tapa el texto y los colores de estado se leen sobre las tarjetas.
- **`test/app_test.dart`** — la aplicación arranca, carga el contenido
  empaquetado y navega entre zonas.

---

## Identidad visual

Negro azulado (`#0A0F15`), gris acero (`#5B6E80`), blanco frío (`#EFF4F8`) y
**verde lima eléctrico (`#B4F02A`) solo como acento**, nunca como fondo
dominante. En tema claro el lima se sustituye por su versión legible
(`#3F6212`), porque el lima puro sobre blanco no alcanza el contraste mínimo.

El icono representa una **ruta lógica**: un nodo de inicio, un rombo de decisión
y dos caminos posibles, con el camino activo en lima. No es un cerebro con
circuitos ni un símbolo genérico de inteligencia artificial.

Los dos temas están diseñados por separado, no derivados uno del otro.

---

## Privacidad y funcionamiento sin conexión

- Sin backend, sin cuentas, sin registro.
- Sin permiso de red en la aplicación instalada (INTERNET solo en depuración,
  para la recarga en caliente de Flutter).
- El progreso, el historial y el código del laboratorio se guardan únicamente
  en el dispositivo, con `SharedPreferences`.
- El contenido educativo viaja empaquetado como asset: la app funciona completa
  en modo avión.

## Inteligencia artificial

**El MVP no depende de IA.** Toda la retroalimentación —qué falló, en qué paso,
con qué variable, qué concepto revisar— se deriva de la ejecución real del
programa, que es información más fiable y más barata que un modelo. La IA se
contempla como evolución posterior (explicaciones en lenguaje natural sobre la
traza ya calculada, generación de variantes de ejercicios), no como requisito.

---

## Licencia

MIT. Ver [`LICENSE`](LICENSE).
