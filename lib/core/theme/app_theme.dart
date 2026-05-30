import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // ─── Brand palette ────────────────────────────────────────────────────────
  static const Color _primary = AppColors.primary;          // 0xFF1B7A35
  static const Color _primaryDark = Color(0xFF145C27);
  static const Color _primaryLight = Color(0xFF2EAF4D);

  // ─── Light surface colours ────────────────────────────────────────────────
  static const Color _bgLight = Color(0xFFF5F6FA);
  static const Color _surfaceLight = Colors.white;
  static const Color _cardLight = Colors.white;

  // ─── Dark surface colours ─────────────────────────────────────────────────
  static const Color _bgDark = Color(0xFF0F1A13);
  static const Color _surfaceDark = Color(0xFF1A2B1E);
  static const Color _cardDark = Color(0xFF1E3324);

  // ─── Shared ───────────────────────────────────────────────────────────────
  static const Color _error = Color(0xFFE53935);
  static const String _fontFamily = 'Roboto';

  // ═══════════════════════════════════════════════════════════════════════════
  //  LIGHT THEME
  // ═══════════════════════════════════════════════════════════════════════════
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: _primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFBBF0CC),
      onPrimaryContainer: Color(0xFF002110),
      secondary: Color(0xFF4CAF50),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFC8E6C9),
      onSecondaryContainer: Color(0xFF1B5E20),
      tertiary: Color(0xFF1E3A8A),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFDBE4FF),
      onTertiaryContainer: Color(0xFF001356),
      error: _error,
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: _surfaceLight,
      onSurface: Color(0xFF1A1C18),
      surfaceContainerHighest: Color(0xFFE2E8E0),
      onSurfaceVariant: Color(0xFF42493E),
      outline: Color(0xFF72796E),
      outlineVariant: Color(0xFFC2C9BD),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFF2F312D),
      onInverseSurface: Color(0xFFF0F1EB),
      inversePrimary: _primaryLight,
    );

    return ThemeData(
      useMaterial3: false,
      fontFamily: _fontFamily,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      primaryColor: _primary,
      scaffoldBackgroundColor: _bgLight,
      canvasColor: _bgLight,
      cardColor: _cardLight,

      // ── AppBar ─────────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF1A1C18)),
        titleTextStyle: TextStyle(
          color: Color(0xFF1A1C18),
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: _fontFamily,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),

      // ── Card ───────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: _cardLight,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // ── Divider ────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: Color(0xFFF0F0F0),
        thickness: 1,
        space: 1,
      ),

      // ── Input ──────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        labelStyle: WidgetStateTextStyle.resolveWith((states) {
          if (states.contains(WidgetState.error)) return const TextStyle(color: Colors.red, fontSize: 14);
          if (states.contains(WidgetState.focused)) return const TextStyle(color: _primary, fontSize: 14);
          return const TextStyle(color: Color(0xFF42493E), fontSize: 14);
        }),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
          if (states.contains(WidgetState.error)) return const TextStyle(color: Colors.red, fontSize: 14);
          if (states.contains(WidgetState.focused)) return const TextStyle(color: _primary, fontSize: 14);
          return const TextStyle(color: Color(0xFF42493E), fontSize: 14);
        }),
        suffixIconColor: Colors.grey.shade500,
      ),

      // ── Elevated Button ────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: _primary.withValues(alpha: 0.35),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontFamily: _fontFamily,
          ),
        ),
      ),

      // ── Text Button ────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primary,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: _fontFamily,
          ),
        ),
      ),

      // ── Outlined Button ────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primary,
          side: const BorderSide(color: _primary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: _fontFamily,
          ),
        ),
      ),

      // ── Icon ───────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(color: Color(0xFF42493E), size: 24),
      primaryIconTheme: const IconThemeData(color: _primary, size: 24),

      // ── ListTile ───────────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        iconColor: _primary,
        textColor: Color(0xFF1A1C18),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // ── Switch ─────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? _primary : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? _primary.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),

      // ── BottomNav ──────────────────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: _primary,
        unselectedItemColor: Color(0xFF9E9E9E),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      // ── Chip ───────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: _primary.withValues(alpha: 0.08),
        labelStyle: const TextStyle(color: _primary, fontSize: 13),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // ── Text ───────────────────────────────────────────────────────────────
      textTheme: _buildTextTheme(const Color(0xFF1A1C18)),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  DARK THEME
  // ═══════════════════════════════════════════════════════════════════════════
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _primaryLight,
      onPrimary: Color(0xFF003919),
      primaryContainer: _primaryDark,
      onPrimaryContainer: Color(0xFFBBF0CC),
      secondary: Color(0xFF81C784),
      onSecondary: Color(0xFF003919),
      secondaryContainer: Color(0xFF1B5E20),
      onSecondaryContainer: Color(0xFFC8E6C9),
      tertiary: Color(0xFF93B4FF),
      onTertiary: Color(0xFF001971),
      tertiaryContainer: Color(0xFF1E3A8A),
      onTertiaryContainer: Color(0xFFDBE4FF),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: _surfaceDark,
      onSurface: Color(0xFFE2E3DD),
      surfaceContainerHighest: Color(0xFF3E4A41),
      onSurfaceVariant: Color(0xFFC2C9BD),
      outline: Color(0xFF8C9389),
      outlineVariant: Color(0xFF42493E),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFE2E3DD),
      onInverseSurface: Color(0xFF2F312D),
      inversePrimary: _primary,
    );

    return ThemeData(
      useMaterial3: false,
      fontFamily: _fontFamily,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      primaryColor: _primaryLight,
      scaffoldBackgroundColor: _bgDark,
      canvasColor: _bgDark,
      cardColor: _cardDark,

      // ── AppBar ─────────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFFE2E3DD)),
        titleTextStyle: TextStyle(
          color: Color(0xFFE2E3DD),
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: _fontFamily,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      // ── Card ───────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: _cardDark,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // ── Divider ────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2A3D2F),
        thickness: 1,
        space: 1,
      ),

      // ── Input ──────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _cardDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3E4A41)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3E4A41)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFB4AB)),
        ),
        hintStyle: const TextStyle(color: Color(0xFF6B7568), fontSize: 14),
        labelStyle: const TextStyle(color: Color(0xFFC2C9BD), fontSize: 14),
      ),

      // ── Elevated Button ────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryLight,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: _primaryLight.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontFamily: _fontFamily,
          ),
        ),
      ),

      // ── Text Button ────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryLight,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: _fontFamily,
          ),
        ),
      ),

      // ── Outlined Button ────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryLight,
          side: const BorderSide(color: _primaryLight, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: _fontFamily,
          ),
        ),
      ),

      // ── Icon ───────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(color: Color(0xFFC2C9BD), size: 24),
      primaryIconTheme: const IconThemeData(color: _primaryLight, size: 24),

      // ── ListTile ───────────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        iconColor: _primaryLight,
        textColor: Color(0xFFE2E3DD),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // ── Switch ─────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? _primaryLight : Colors.grey,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? _primaryLight.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),

      // ── BottomNav ──────────────────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _surfaceDark,
        selectedItemColor: _primaryLight,
        unselectedItemColor: Color(0xFF6B7568),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      // ── Chip ───────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: _primaryLight.withValues(alpha: 0.12),
        labelStyle: const TextStyle(color: _primaryLight, fontSize: 13),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // ── Text ───────────────────────────────────────────────────────────────
      textTheme: _buildTextTheme(const Color(0xFFE2E3DD)),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SHARED TEXT THEME
  // ═══════════════════════════════════════════════════════════════════════════
  static TextTheme _buildTextTheme(Color baseColor) {
    return TextTheme(
      displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: baseColor),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: baseColor),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: baseColor),
      headlineLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: baseColor),
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: baseColor),
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: baseColor),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: baseColor),
      titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: baseColor),
      titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: baseColor),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: baseColor),
      bodyMedium: TextStyle(fontSize: 15, height: 1.5, color: baseColor),
      bodySmall: TextStyle(fontSize: 13, height: 1.4, color: baseColor.withValues(alpha: 0.7)),
      labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: baseColor),
      labelMedium: TextStyle(fontSize: 13, color: baseColor.withValues(alpha: 0.8)),
      labelSmall: TextStyle(fontSize: 12, color: baseColor.withValues(alpha: 0.6)),
    );
  }
}
