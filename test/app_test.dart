import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logicai/app.dart';
import 'package:logicai/data/models/content_models.dart';
import 'package:logicai/state/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Prueba de humo: la aplicacion arranca, carga el contenido empaquetado y
/// muestra las zonas de trabajo sin necesidad de red ni de cuenta.
///
/// El contenido se carga aqui directamente del archivo (en vez de esperar a
/// que `rootBundle` lo resuelva dentro del test) para que la primera pantalla
/// no dependa del canal de assets: eso es lo que hacia que pumpAndSettle no
/// terminara nunca de asentarse.
AppContent _loadTestContent() {
  final file = File('assets/content/content.json');
  return AppContent.fromJson(
      json.decode(file.readAsStringSync()) as Map<String, dynamic>);
}

void main() {
  final content = _loadTestContent();

  testWidgets('LogicAI arranca y muestra el panel inicial', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          contentProvider.overrideWith((ref) async => content),
        ],
        child: const LogicAiApp(),
      ),
    );

    // Primer fotograma: indicador de carga del contenido.
    expect(find.text('LogicAI'), findsWidgets);

    await tester.pumpAndSettle();

    expect(find.text('Laboratorio de logica'), findsWidgets);

    // La tarjeta "Modulos de fundamentos" queda mas abajo del panel inicial:
    // el ListView solo construye lo que esta cerca de la vista, asi que hay
    // que desplazarlo antes de poder encontrar el texto.
    await tester.scrollUntilVisible(find.text('Modulos de fundamentos'), 300);
    expect(find.text('Modulos de fundamentos'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('la navegacion inferior cambia de zona', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          contentProvider.overrideWith((ref) async => content),
        ],
        child: const LogicAiApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.school_outlined).last);
    await tester.pumpAndSettle();
    expect(find.text('Variables y datos'), findsWidgets);

    await tester.tap(find.byIcon(Icons.insights_outlined).last);
    await tester.pumpAndSettle();
    expect(find.text('Mi progreso'), findsWidgets);
  });
}
