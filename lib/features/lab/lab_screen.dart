import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/line_editor.dart';
import '../../state/app_providers.dart';
import '../../state/execution_controller.dart';
import '../../state/exercise_session.dart';
import '../exercise/widgets/memory_inspector.dart';
import '../exercise/widgets/output_panel.dart';
import '../exercise/widgets/tracer_panel.dart';
import '../reference/reference_screen.dart';

/// Laboratorio de logica: espacio libre para experimentar.
///
/// El codigo se guarda en el dispositivo, de modo que el experimento sigue
/// ahi al volver a abrir la aplicacion.
class LabScreen extends ConsumerStatefulWidget {
  const LabScreen({super.key});

  @override
  ConsumerState<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends ConsumerState<LabScreen> {
  static const String _sessionId = 'laboratorio';

  String? _code;
  bool _editing = true;

  String get _defaultCode =>
      'inicio\n    contador = 0\n    mientras contador < 3 hacer\n'
      '        mostrar contador\n        contador = contador + 1\n'
      '    fin_mientras\nfin';

  String get code => _code ??= ref.read(progressRepositoryProvider).loadLabCode() ??
      _defaultCode;

  void _setCode(String value) {
    setState(() => _code = value);
    ref.read(progressRepositoryProvider).saveLabCode(value);
  }

  void _run() {
    ref
        .read(executionControllerProvider(_sessionId).notifier)
        .run(code);
    setState(() => _editing = false);
  }

  Future<void> _openSamples() async {
    final content = ref.read(loadedContentProvider);
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text('Programas de ejemplo',
                style: Theme.of(sheetContext).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Cargar un ejemplo reemplaza el codigo actual del laboratorio.',
              style: Theme.of(sheetContext).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final sample in content.labSamples)
              ListTile(
                leading: const Icon(Icons.science_outlined),
                title: Text(sample.title),
                onTap: () => Navigator.of(sheetContext).pop(sample.code),
              ),
          ],
        ),
      ),
    );
    if (chosen != null) {
      _setCode(chosen);
      ref.read(executionControllerProvider(_sessionId).notifier).clear();
      setState(() => _editing = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final execution = ref.watch(executionControllerProvider(_sessionId));
    final executionController =
        ref.read(executionControllerProvider(_sessionId).notifier);
    final colors = context.logic;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laboratorio de logica'),
        actions: [
          IconButton(
            tooltip: 'Ejemplos',
            onPressed: _openSamples,
            icon: const Icon(Icons.library_books_outlined),
          ),
          IconButton(
            tooltip: 'Consulta rapida',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ReferenceScreen()),
            ),
            icon: const Icon(Icons.menu_book_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        children: [
          InfoBanner(
            icon: Icons.science_outlined,
            color: colors.info,
            title: 'Experimenta sin nota',
            text: 'Escribe una idea, ejecutala paso a paso y observa la '
                'memoria. Aqui equivocarse es parte del metodo.',
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(
                  'Mi programa',
                  icon: Icons.edit_note,
                  trailing: TextButton.icon(
                    onPressed: () => setState(() => _editing = !_editing),
                    icon: Icon(
                      _editing ? Icons.visibility_outlined : Icons.edit_outlined,
                      size: 16,
                    ),
                    label: Text(_editing ? 'Solo ver' : 'Editar'),
                  ),
                ),
                const SizedBox(height: 10),
                LineCodeEditor(
                  code: code,
                  onChanged: _setCode,
                  enabled: _editing,
                  errorLine: execution.errorLine,
                  activeLine: execution.activeLine,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TracerPanel(
            code: code,
            state: execution,
            controller: executionController,
          ),
          const SizedBox(height: 12),
          MemoryInspector(state: execution),
          const SizedBox(height: 12),
          OutputPanel(state: execution),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _setCode(_defaultCode);
                  executionController.clear();
                  setState(() => _editing = true);
                },
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reiniciar'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _run,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Ejecutar paso a paso'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
