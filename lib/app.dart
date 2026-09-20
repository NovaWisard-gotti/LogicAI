import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/home/home_shell.dart';
import 'state/app_providers.dart';

class LogicAiApp extends ConsumerWidget {
  const LogicAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'LogicAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const _ContentGate(),
    );
  }
}

/// El contenido educativo vive en un asset local: mientras se carga se muestra
/// un indicador y, si algo falla, un mensaje con reintento (nunca una pantalla
/// vacia ni un placeholder).
class _ContentGate extends ConsumerWidget {
  const _ContentGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentProvider);

    return content.when(
      data: (_) => const HomeShell(),
      loading: () => const _SplashScaffold(),
      error: (error, _) => _ErrorScaffold(
        message: '$error',
        onRetry: () => ref.invalidate(contentProvider),
      ),
    );
  }
}

class _SplashScaffold extends StatelessWidget {
  const _SplashScaffold();

  @override
  Widget build(BuildContext context) {
    final colors = context.logic;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_tree_outlined,
                size: 56, color: colors.accentOnSurface),
            const SizedBox(height: 16),
            Text('LogicAI', style: context.texts.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Preparando el laboratorio de logica',
              style: context.texts.bodySmall,
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 140,
              child: LinearProgressIndicator(minHeight: 4),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.report_gmailerrorred_outlined,
                  size: 48, color: context.logic.danger),
              const SizedBox(height: 12),
              Text('No se pudo cargar el contenido',
                  style: context.texts.titleMedium),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: context.texts.bodySmall,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
