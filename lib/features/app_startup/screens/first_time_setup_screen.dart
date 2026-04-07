import 'package:classipod/core/constants/app_palette.dart';
import 'package:classipod/core/constants/assets.dart';
import 'package:classipod/core/services/audio_files_service.dart';
import 'package:classipod/features/app_startup/controllers/app_startup_controller.dart';
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
  List<String> _addedAlbums = [];

  Future<void> _pickAndAddAlbum() async {
    try {
      setState(() => _isLoading = true);

      final pickedFiles = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.audio,
        dialogTitle: 'Select Songs for Album',
      );

      if (pickedFiles == null || pickedFiles.files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final filePaths = pickedFiles.files
          .where((f) => f.path != null)
          .map((f) => f.path!)
          .toList();

      if (mounted) {
        final albumName = await ref
            .read(audioFilesServiceProvider.notifier)
            .addAlbumFromPickedFiles(filePaths);

        if (mounted) {
          setState(() {
            _addedAlbums.add(albumName);
            _isLoading = false;
          });

          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Album Added'),
              content: Text('Added: $albumName'),
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
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to add album:\n$e'),
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

  Future<void> _continueToApp() async {
    try {
      setState(() => _isLoading = true);
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
            content: Text('Failed to initialize app:\n$e'),
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
                        'Processing...',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            Assets.appIcon,
                            height: 80,
                            width: 80,
                            color: CupertinoColors.white,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'ClassiPod',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Revived by scutoid',
                            style: TextStyle(
                              color: CupertinoColors.inactiveGray,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 48),
                          const Text(
                            'Add Your Albums',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _addedAlbums.isEmpty
                                ? 'Select songs to add your first album'
                                : 'Added ${_addedAlbums.length} album${_addedAlbums.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: CupertinoColors.inactiveGray,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_addedAlbums.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    CupertinoColors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _addedAlbums
                                    .map(
                                      (album) => Padding(
                                        padding:
                                            const EdgeInsets.symmetric(
                                              vertical: 4,
                                            ),
                                        child: Text(
                                          '• $album',
                                          style: const TextStyle(
                                            color: CupertinoColors.white,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                          const SizedBox(height: 40),
                          CupertinoButton.filled(
                            onPressed: _isLoading ? null : _pickAndAddAlbum,
                            child: const SizedBox(
                              width: double.infinity,
                              child: Text(
                                'Add Album',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          CupertinoButton(
                            onPressed:
                                _isLoading ? null : _continueToApp,
                            child: const Text('Continue'),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
