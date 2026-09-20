import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logicai/app.dart';
import 'package:logicai/state/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Prueba de humo: la aplicacion arranca, carga el contenido empaquetado y
/// muestra las zonas de trabajo sin necesidad de red ni de cuenta.
void main() {
  testWidgets('LogicAI arranca y muestra el panel inicial', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const LogicAiApp(),
      ),
    );

    // Primer fotograma: indicador de carga del contenido.
    expect(find.text('LogicAI'), findsWidgets);

    await tester.pumpAndSettle();

    expect(find.text('Laboratorio de logica'), findsWidgets);
    expect(find.text('Modulos de fundamentos'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('la navegacion inferior cambia de zona', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
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
