import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:flutter/cupertino.dart';

enum ThemeMode {
  system,
  light,
  dark;

  String title(BuildContext context) {
    switch (this) {
      case ThemeMode.system:
        return context.localization.lightThemeMode;
      case ThemeMode.light:
        return context.localization.lightThemeMode;
      case ThemeMode.dark:
        return context.localization.darkThemeMode;
    }
  }

  Brightness get brightness {
    switch (this) {
      case ThemeMode.system:
        return Brightness.light;
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
    }
  }
}
