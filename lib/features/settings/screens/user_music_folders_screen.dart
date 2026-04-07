import 'dart:io';

import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/services/audio_files_service.dart';
import 'package:classipod/features/settings/controller/user_music_folders_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserMusicFoldersScreen extends ConsumerStatefulWidget {
  const UserMusicFoldersScreen({super.key});

  @override
  ConsumerState<UserMusicFoldersScreen> createState() =>
      _UserMusicFoldersScreenState();
}

class _UserMusicFoldersScreenState extends ConsumerState<UserMusicFoldersScreen> {
  bool _isScanning = false;

  Future<void> _selectAndAddFolder() async {
    try {
      setState(() => _isScanning = true);

      final pickedFiles = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.audio,
        dialogTitle: 'Select Songs for Album',
      );

      if (pickedFiles == null || pickedFiles.files.isEmpty) {
        setState(() => _isScanning = false);
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
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final folders = ref.watch(userMusicFoldersProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Music Folders'),
      ),
      child: SafeArea(
        child: _isScanning
            ? const Center(
                child: CupertinoActivityIndicator(radius: 16),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: CupertinoButton(
                      color: CupertinoColors.activeBlue,
                      onPressed: _selectAndAddFolder,
                      child: const Text('Add Music Folder'),
                    ),
                  ),
                  if (folders.isEmpty)
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No music folders added yet. Tap "Add Music Folder" to start.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: folders.length,
                        itemBuilder: (context, index) {
                          final folder = folders[index];

                          return Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: CupertinoColors.separator,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: CupertinoListTile(
                              title: Text(folder.folderName),
                              subtitle: Text(
                                folder.folderPath,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: CupertinoButton(
                                padding: EdgeInsets.zero,
                                minSize: 44,
                                onPressed: () {
                                  showCupertinoDialog(
                                    context: context,
                                    builder: (context) =>
                                        CupertinoAlertDialog(
                                      title: const Text('Remove Folder?'),
                                      content: Text(
                                        'Remove "${folder.folderName}" from music folders?',
                                      ),
                                      actions: [
                                        CupertinoDialogAction(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        CupertinoDialogAction(
                                          isDestructiveAction: true,
                                          onPressed: () {
                                            ref
                                                .read(
                                                  audioFilesServiceProvider
                                                      .notifier,
                                                )
                                                .removeMusicFolderAndRefresh(
                                                  index,
                                                );
                                            ref
                                                .read(
                                                  userMusicFoldersProvider
                                                      .notifier,
                                                )
                                                .removeMusicFolder(
                                                  folderKey: index,
                                                );
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Remove'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: const Icon(
                                  CupertinoIcons.delete,
                                  color: CupertinoColors.systemRed,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
