import 'dart:async';

import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/navigation/routes.dart';
import 'package:classipod/core/providers/filtered_audio_files_provider.dart';
import 'package:classipod/core/services/audio_files_service.dart';
import 'package:classipod/core/widgets/empty_state_widget.dart';
import 'package:classipod/features/custom_screen_elements/custom_screen.dart';
import 'package:classipod/features/music/album/models/album_model.dart';
import 'package:classipod/features/music/album/providers/album_details_provider.dart';
import 'package:classipod/features/music/album/widgets/album_list_tile.dart';
import 'package:classipod/features/status_bar/widgets/status_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AlbumsSelectionScreen extends ConsumerStatefulWidget {
  const AlbumsSelectionScreen({super.key});

  @override
  ConsumerState createState() => _AlbumsSelectionScreenState();
}

class _AlbumsSelectionScreenState extends ConsumerState<AlbumsSelectionScreen>
    with CustomScreen {
  @override
  double get displayTileHeight => 54;

  @override
  int get extraDisplayItems => 2;

  @override
  String get routeName => Routes.albums.name;

  @override
  List<AlbumModel> get displayItems => ref.watch(albumDetailsProvider);

  @override
  Future<void> onSelectPressed() async {
    if (selectedDisplayItem == displayItems.length + 1) {
      await _addAlbum();
      return;
    }

    await _navigateToAlbumSelectionScreen(selectedDisplayItem);
  }

  @override
  Future<void> onSelectLongPress() async {
    if (selectedDisplayItem == displayItems.length + 1) {
      return;
    }
    return _navigateToAlbumMoreOptionsScreen(selectedDisplayItem);
  }

  Future<void> _navigateToAlbumMoreOptionsScreen(int index) async {
    setState(() => selectedDisplayItem = index);
    // If the index is 0, it means the user has selected the "All Albums" option.
    // If the index is the last extra item, it means "Add Album".
    if (index == 0 || index == displayItems.length + 1) {
      return;
    } else {
      await context.pushNamed(
        Routes.albumMoreOptions.name,
        extra: displayItems[index - 1],
      );
    }
  }

  Future<void> _addAlbum() async {
    try {
      final pickedFiles = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.audio,
        dialogTitle: 'Select Songs for Album',
      );

      if (pickedFiles == null || pickedFiles.files.isEmpty) {
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
    }
  }

  Future<void> _navigateToAlbumSelectionScreen(int index) async {
    setState(() => selectedDisplayItem = index);
    if (index == 0) {
      await context.goNamed(
        Routes.albumSongs.name,
        extra: AlbumModel(
          albumName: context.localization.allAlbums,
          albumArtistName: "",
          albumSongs: ref.read(filteredAudioFilesProvider).requireValue,
        ),
      );
    } else {
      await context.goNamed(Routes.albumSongs.name, extra: displayItems[index - 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (displayItems.isEmpty) {
      return CupertinoPageScaffold(
        child: Column(
          children: [
            StatusBar(title: Routes.albums.title(context)),
            Expanded(
              child: EmptyStateWidget(
                emptyDescription: context.localization.noAlbumsFound,
              ),
            ),
          ],
        ),
      );
    }

    return CupertinoPageScaffold(
      child: Column(
        children: [
          StatusBar(title: Routes.albums.title(context)),
          Flexible(
            child: CupertinoScrollbar(
              controller: scrollController,
              child: ListView.builder(
                controller: scrollController,
                itemCount: displayItems.length + 2,
                prototypeItem: AlbumListTile(
                  albumDetails: AlbumModel(
                    albumName: '',
                    albumArtistName: '',
                    albumSongs: [],
                  ),
                  isSelected: false,
                  onTap: () {},
                  onLongPress: () {},
                ),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final allSongs = ref
                        .read(filteredAudioFilesProvider)
                        .requireValue;
                    return AlbumListTile(
                      albumDetails: AlbumModel(
                        albumName: context.localization.allSongs,
                        albumArtistName: context.localization.nSongs(
                          allSongs.length,
                        ),
                        albumSongs: allSongs,
                      ),
                      isSelected: selectedDisplayItem == 0,
                      isAllSongsAlbum: true,
                      onTap: () async => _navigateToAlbumSelectionScreen(0),
                      onLongPress: () {},
                    );
                  }

                  if (index == displayItems.length + 1) {
                    return GestureDetector(
                      onTap: _addAlbum,
                      child: Container(
                        color: CupertinoColors.systemBackground,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Add Album',
                              style: TextStyle(
                                color: CupertinoColors.activeBlue,
                                fontSize: 16,
                              ),
                            ),
                            const Icon(
                              CupertinoIcons.chevron_right,
                              color: CupertinoColors.inactiveGray,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return AlbumListTile(
                    albumDetails: displayItems[index - 1],
                    isSelected: selectedDisplayItem == index,
                    onTap: () async => _navigateToAlbumSelectionScreen(index),
                    onLongPress: () async =>
                        _navigateToAlbumMoreOptionsScreen(index),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
