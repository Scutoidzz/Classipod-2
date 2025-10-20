import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:flutter/cupertino.dart';

enum ThemeMode {
  light,
  dark;

  String title(BuildContext context) {
    switch (this) {
      case ThemeMode.light:
        return context.localization.lightThemeMode;
      case ThemeMode.dark:
        return context.localization.darkThemeMode;
    }
  }

  Brightness get brightness {
    switch (this) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
    }
  }
}
