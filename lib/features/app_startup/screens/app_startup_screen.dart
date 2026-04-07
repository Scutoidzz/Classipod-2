import 'package:classipod/core/providers/first_time_provider.dart';
import 'package:classipod/features/app_startup/controllers/app_startup_controller.dart';
import 'package:classipod/features/app_startup/screens/app_startup_error_screen.dart';
import 'package:classipod/features/app_startup/screens/app_startup_loading_screen.dart';
import 'package:classipod/features/app_startup/screens/first_time_setup_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppStartupScreen extends ConsumerWidget {
  final Widget app;

  const AppStartupScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFirstTime = ref.watch(isFirstTimeProvider);
    final appStartupState = ref.watch(appStartupControllerProvider);

    return isFirstTime.when(
      skipLoadingOnReload: false,
      loading: () => const AppStartupLoading(),
      error: (e, _) => AppStartupError(
        error: e,
        onRetry: () => ref.invalidate(isFirstTimeProvider),
      ),
      data: (firstTime) {
        if (firstTime) {
          return const FirstTimeSetupScreen();
        }
        return appStartupState.when(
          skipLoadingOnReload: false,
          loading: () => const AppStartupLoading(),
          error: (e, _) => AppStartupError(
            error: e,
            onRetry: () => ref.invalidate(appStartupControllerProvider),
          ),
          data: (_) => app,
        );
      },
    );
  }
}
