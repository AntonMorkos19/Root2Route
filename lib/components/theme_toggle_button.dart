import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/features/theme/cubit/theme_cubit.dart';

/// A compact animated icon button that toggles between light and dark mode.
/// Drop it anywhere — AppBar actions, settings rows, etc.
class ThemeToggleButton extends StatelessWidget {
  /// Show as an [IconButton] in AppBars / toolbars.
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => RotationTransition(
            turns: anim,
            child: ScaleTransition(scale: anim, child: child),
          ),
          child: IconButton(
            key: ValueKey<bool>(state.isDark),
            icon: Icon(
              state.isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              color: state.isDark ? const Color(0xFFFDD835) : const Color(0xFF5C6BC0),
            ),
            tooltip: state.isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () => context.read<ThemeCubit>().toggleTheme(),
          ),
        );
      },
    );
  }
}

/// A full-width settings-row tile for use inside a settings list.
class ThemeToggleTile extends StatelessWidget {
  const ThemeToggleTile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        final isDark = state.isDark;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDark
                      ? const Color(0xFFFDD835)
                      : const Color(0xFF5C6BC0))
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              color: isDark ? const Color(0xFFFDD835) : const Color(0xFF5C6BC0),
            ),
          ),
          title: Text(
            'Dark Mode',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          trailing: Switch(
            value: isDark,
            onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
            activeThumbColor: const Color(0xFF2EAF4D),
          ),
          onTap: () => context.read<ThemeCubit>().toggleTheme(),
        );
      },
    );
  }
}
