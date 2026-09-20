import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/content_models.dart';
import '../models/progress_models.dart';

/// Carga el contenido educativo empaquetado en la aplicación.
/// No hay backend: LogicAI funciona completamente sin conexión.
class ContentRepository {
  const ContentRepository();

  static const String assetPath = 'assets/content/content.json';

  Future<AppContent> load() async {
    final raw = await rootBundle.loadString(assetPath);
    return AppContent.fromJson(json.decode(raw) as Map<String, dynamic>);
  }
}

/// Persistencia local del progreso, historial y preferencias.
class ProgressRepository {
  const ProgressRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String _progressKey = 'logicai.progress.v1';
  static const String _themeKey = 'logicai.theme.v1';
  static const String _labKey = 'logicai.lab.v1';

  ProgressState loadProgress() {
    final raw = _prefs.getString(_progressKey);
    if (raw == null || raw.isEmpty) return const ProgressState();
    try {
      return ProgressState.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const ProgressState();
    }
  }

  Future<void> saveProgress(ProgressState state) =>
      _prefs.setString(_progressKey, json.encode(state.toJson()));

  Future<void> clearProgress() => _prefs.remove(_progressKey);

  ThemeMode loadThemeMode() {
    final raw = _prefs.getString(_themeKey);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> saveThemeMode(ThemeMode mode) =>
      _prefs.setString(_themeKey, mode.name);

  String? loadLabCode() => _prefs.getString(_labKey);

  Future<void> saveLabCode(String code) => _prefs.setString(_labKey, code);
}
