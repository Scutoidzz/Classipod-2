import 'dart:async';

import 'package:classipod/features/settings/controller/settings_preferences_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SystemUiSyncScope extends ConsumerStatefulWidget {
  final Widget child;

  const SystemUiSyncScope({super.key, required this.child});

  @override
  ConsumerState createState() => _SystemUiSyncScopeState();
}

class _SystemUiSyncScopeState extends ConsumerState<SystemUiSyncScope>
    with WidgetsBindingObserver {
  ProviderSubscription<bool>? _immersiveModeSubscription;

  bool get _supportsSystemUiSync {
    if (kIsWeb) {
      return false;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => true,
      _ => false,
    };
  }

  Future<void> _syncSystemUiMode() async {
    await ref
        .read(settingsPreferencesControllerProvider.notifier)
        .setSystemUiMode();
  }

  Future<void> _handleSystemUiChange(bool systemOverlaysAreVisible) async {
    if (!systemOverlaysAreVisible) {
      return;
    }

    if (!ref.read(settingsPreferencesControllerProvider).immersiveMode) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) {
      return;
    }
    await _syncSystemUiMode();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _immersiveModeSubscription = ref.listenManual(
      settingsPreferencesControllerProvider.select(
        (value) => value.immersiveMode,
      ),
      (_, __) => unawaited(_syncSystemUiMode()),
    );
    if (_supportsSystemUiSync) {
      unawaited(SystemChrome.setSystemUIChangeCallback(_handleSystemUiChange));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_syncSystemUiMode());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncSystemUiMode());
    }
  }

  @override
  void dispose() {
    _immersiveModeSubscription?.close();
    WidgetsBinding.instance.removeObserver(this);
    if (_supportsSystemUiSync) {
      unawaited(SystemChrome.setSystemUIChangeCallback(null));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
