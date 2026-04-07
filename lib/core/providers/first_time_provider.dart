import 'package:classipod/core/constants/constants.dart';
import 'package:classipod/core/providers/shared_preferences_with_cache_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final isFirstTimeProvider = FutureProvider<bool>((ref) async {
  final prefs = await ref.watch(sharedPreferencesWithCacheProvider.future);
  return prefs.getBool('isFirstTime') ?? true;
});

final markFirstTimeCompleteProvider = FutureProvider<void>((ref) async {
  final prefs = await ref.watch(sharedPreferencesWithCacheProvider.future);
  await prefs.setBool('isFirstTime', false);
});
