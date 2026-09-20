import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/code_view.dart';
import '../../core/widgets/common.dart';
import '../../state/exercise_session.dart';

/// Consulta rapida: sintaxis del pseudocodigo sin salir del trabajo.
class ReferenceScreen extends ConsumerStatefulWidget {
  const ReferenceScreen({super.key});

  @override
  ConsumerState<ReferenceScreen> createState() => _ReferenceScreenState();
}

class _ReferenceScreenState extends ConsumerState<ReferenceScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(loadedContentProvider);
    final query = _query.trim().toLowerCase();

    final sections = content.reference.where((section) {
      if (query.isEmpty) return true;
      if (section.title.toLowerCase().contains(query)) return true;
      if (section.summary.toLowerCase().contains(query)) return true;
      return section.items.any((item) =>
          item.text.toLowerCase().contains(query) ||
          item.code.toLowerCase().contains(query));
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Consulta rapida')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar: mientras, arreglo, funcion...',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: sections.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyState(
                      icon: Icons.search_off,
                      title: 'Sin resultados',
                      message: 'Prueba con otra palabra del pseudocodigo.',
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      for (final section in sections)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(section.title,
                                    style: context.texts.titleSmall),
                                const SizedBox(height: 4),
                                Text(section.summary,
                                    style: context.texts.bodySmall),
                                const SizedBox(height: 12),
                                for (final item in section.items) ...[
                                  Text(item.text,
                                      style: context.texts.bodyMedium),
                                  const SizedBox(height: 6),
                                  CodeView(
                                    code: item.code,
                                    showLineNumbers: false,
                                    fontSize: 13.5,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
