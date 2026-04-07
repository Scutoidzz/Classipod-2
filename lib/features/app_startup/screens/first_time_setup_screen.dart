import 'dart:io';

import 'package:classipod/core/constants/app_palette.dart';
import 'package:classipod/core/constants/assets.dart';
import 'package:classipod/core/constants/assets.dart';
import 'package:classipod/core/services/audio_files_service.dart';
import 'package:classipod/features/app_startup/controllers/app_startup_controller.dart';
import 'package:classipod/features/app_startup/screens/app_startup_loading_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirstTimeSetupScreen extends ConsumerStatefulWidget {
  const FirstTimeSetupScreen({super.key});

  @override
  ConsumerState<FirstTimeSetupScreen> createState() =>
      _FirstTimeSetupScreenState();
}

class _FirstTimeSetupScreenState extends ConsumerState<FirstTimeSetupScreen> {
  bool _isLoading = false;

  Future<void> _selectMusicFolder() async {
    try {
      setState(() => _isLoading = true);

      String? folderPath;
      String? folderName;

      if (Platform.isIOS) {
        // On iOS, use file picker since directory access is sandboxed
        final pickedFiles = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.audio,
          dialogTitle: 'Select Music Files',
        );

        if (pickedFiles == null || pickedFiles.files.isEmpty) {
          setState(() => _isLoading = false);
          return;
        }

        // Use first file's directory as the "folder"
        final firstFilePath = pickedFiles.files.first.path;
        if (firstFilePath == null) {
          setState(() => _isLoading = false);
          return;
        }

        folderPath = File(firstFilePath).parent.path;
        folderName = folderPath.split(Platform.pathSeparator).last;

        // Scan picked files
        await ref
            .read(audioFilesServiceProvider.notifier)
            .addMusicFilesAndScan(
              pickedFiles.files.map((f) => f.path!).toList(),
              folderName,
            );
      } else {
        // On desktop platforms, use directory picker
        folderPath = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Select Music Folder',
          lockParentWindow: true,
        );

        if (folderPath == null) {
          setState(() => _isLoading = false);
          return;
        }

        folderName = folderPath.split(Platform.pathSeparator).last;

        // Scan and add music folder
        await ref
            .read(audioFilesServiceProvider.notifier)
            .addMusicFolderAndScan(folderPath, folderName);
      }

      // Now initialize the app after scanning is complete
      if (mounted) {
        await ref.read(appStartupControllerProvider.future);
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to load music:\n$e'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      home: CupertinoPageScaffold(
        backgroundColor: AppPalette.darkScreenBackgroundGradient2,
        child: Container(
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
          child: Center(
            child: _isLoading
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CupertinoActivityIndicator(radius: 32),
                      SizedBox(height: 16),
                      Text(
                        'Scanning Music Folder...',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        Assets.appIcon,
                        height: 100,
                        width: 100,
                        color: CupertinoColors.white,
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'ClassiPod',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Revived by scutoid',
                        style: TextStyle(
                          color: CupertinoColors.inactiveGray,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 60),
                      GestureDetector(
                        onTap: _isLoading ? null : _selectMusicFolder,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: CupertinoColors.activeBlue,
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.activeBlue
                                    .withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'OK',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Select your music folder to get started',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: CupertinoColors.inactiveGray,
                            fontSize: 14,
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
