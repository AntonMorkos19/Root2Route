import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  static const String _prefKey = 'is_dark_mode';

  ThemeCubit() : super(const ThemeState(themeMode: ThemeMode.light));

  /// Called once at app start to restore the persisted preference.
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_prefKey) ?? false;
    emit(ThemeState(themeMode: isDark ? ThemeMode.dark : ThemeMode.light));
  }

  /// Toggles between light and dark, then persists the new value.
  Future<void> toggleTheme() async {
    final isDark = state.themeMode == ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, !isDark);
    emit(ThemeState(themeMode: isDark ? ThemeMode.light : ThemeMode.dark));
  }

  /// Explicitly set a theme.
  Future<void> setTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, mode == ThemeMode.dark);
    emit(ThemeState(themeMode: mode));
  }

  bool get isDark => state.themeMode == ThemeMode.dark;
}
