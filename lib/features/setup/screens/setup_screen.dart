import 'package:classipod/core/constants/app_palette.dart';
import 'package:classipod/core/constants/assets.dart';
import 'package:classipod/core/constants/constants.dart';
import 'package:classipod/core/models/music_metadata.dart';
import 'package:classipod/core/navigation/routes.dart';
import 'package:classipod/core/repositories/metadata_reader_repository.dart';
import 'package:classipod/features/settings/repository/settings_preferences_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  bool _isLoading = false;

  Future<void> _pickFolderAndSetup() async {
    setState(() => _isLoading = true);

    try {
      final newDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: "Select Music Folder",
      );

      if (newDirectory == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final metadataBox = Hive.box<MusicMetadata>(Constants.metadataBoxName);
      await metadataBox.clear();

      final result = await compute(
        ref.read(metadataReaderRepositoryProvider).extractMetadataFromDirectory,
        newDirectory,
      );

      await metadataBox.addAll(result);

      await ref
          .read(settingsPreferencesRepositoryProvider)
          .setHasCompletedSetup(hasCompleted: true);

      if (mounted) {
        ref.read(routerProvider).goNamed(Routes.splash.name);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppPalette.darkScreenBackgroundGradient2,
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppPalette.darkScreenBackgroundGradient1,
                AppPalette.darkScreenBackgroundGradient2,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                Image.asset(
                  Assets.appIcon,
                  height: 44,
                  width: 44,
                  color: CupertinoColors.white,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Classipod',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                const Icon(
                  CupertinoIcons.music_note_2,
                  color: CupertinoColors.white,
                  size: 36,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Music',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Import all your music folders',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                const Text(
                  'revived by scutoidzz',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey2,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    onPressed: _isLoading ? null : _pickFolderAndSetup,
                    child: _isLoading
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          )
                        : const Text(
                            'Go',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
