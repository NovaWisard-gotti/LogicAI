import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../state/app_providers.dart';

/// Ajustes: apariencia, datos locales e informacion del proyecto.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final colors = context.logic;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Apariencia',
                    icon: Icons.contrast_outlined),
                const SizedBox(height: 4),
                Text(
                  'Los dos temas estan disenados por separado: el codigo y el '
                  'inspector de memoria mantienen contraste suficiente en '
                  'ambos.',
                  style: context.texts.bodySmall,
                ),
                const SizedBox(height: 12),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Claro'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.phone_android),
                      label: Text('Sistema'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Oscuro'),
                    ),
                  ],
                  selected: {mode},
                  onSelectionChanged: (selection) => ref
                      .read(themeModeProvider.notifier)
                      .setMode(selection.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Mis datos', icon: Icons.storage_outlined),
                const SizedBox(height: 4),
                Text(
                  'El progreso, el historial y el codigo del laboratorio se '
                  'guardan unicamente en este dispositivo.',
                  style: context.texts.bodySmall,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _confirmReset(context, ref),
                  icon: Icon(Icons.delete_outline, color: colors.danger),
                  label: Text('Reiniciar progreso',
                      style: TextStyle(color: colors.danger)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Sobre LogicAI',
                    icon: Icons.info_outline),
                const SizedBox(height: 8),
                Text(
                  'LogicAI es un laboratorio movil de logica de programacion. '
                  'Su objetivo no es memorizar sintaxis, sino entender por que '
                  'un programa hace lo que hace: construir, ejecutar, observar '
                  'la memoria, equivocarse y corregir con evidencia.',
                  style: context.texts.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    Pill('Version 1.0.0', icon: Icons.tag, dense: true),
                    Pill('Funciona sin conexion',
                        icon: Icons.wifi_off, dense: true),
                    Pill('Sin cuenta', icon: Icons.no_accounts, dense: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reiniciar progreso'),
        content: const Text(
          'Se borraran los ejercicios resueltos, el historial y las '
          'habilidades practicadas. Esta accion no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(progressProvider.notifier).reset();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Progreso reiniciado.'),
        ),
      );
  }
}
