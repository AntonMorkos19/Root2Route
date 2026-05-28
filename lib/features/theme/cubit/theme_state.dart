part of 'theme_cubit.dart';

class ThemeState {
  final ThemeMode themeMode;

  const ThemeState({required this.themeMode});

  bool get isDark => themeMode == ThemeMode.dark;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeState && themeMode == other.themeMode;

  @override
  int get hashCode => themeMode.hashCode;
}
