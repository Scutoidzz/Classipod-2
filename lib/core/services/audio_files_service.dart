import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:classipod/core/constants/constants.dart';
import 'package:classipod/core/constants/online_audio_files_metadata.dart';
import 'package:classipod/core/models/music_metadata.dart';
import 'package:classipod/core/providers/device_directory_provider.dart';
import 'package:classipod/core/repositories/metadata_reader_repository.dart';
import 'package:classipod/features/settings/controller/settings_preferences_controller.dart';
import 'package:classipod/features/settings/controller/user_music_folders_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:on_audio_query/on_audio_query.dart';

final audioFilesServiceProvider =
    AsyncNotifierProvider<
      AudioFilesServiceNotifier,
      UnmodifiableListView<MusicMetadata>
    >(AudioFilesServiceNotifier.new);

class AudioFilesServiceNotifier
    extends AsyncNotifier<UnmodifiableListView<MusicMetadata>> {
  @override
  Future<UnmodifiableListView<MusicMetadata>> build() async {
    return getAudioFilesMetadata();
  }

  Future<UnmodifiableListView<MusicMetadata>> getAudioFilesMetadata() async {
    state = const AsyncLoading();
    try {
      if (ref.read(settingsPreferencesControllerProvider).fetchOnlineMusic) {
        return UnmodifiableListView(onlineDemoAudioFilesMetaData);
      }
      // Fetch metadata from local files
      else {
        final Box<MusicMetadata> metadataBox = Hive.box<MusicMetadata>(
          Constants.metadataBoxName,
        );
        // Check if the metadata box is empty
        if (metadataBox.isEmpty) {
          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
            final newDirectory = await FilePicker.platform.getDirectoryPath(
              dialogTitle: "Select Music Directory",
              lockParentWindow: true,
              initialDirectory: ref
                  .read(deviceDirectoryProvider)
                  .requireValue
                  .musicFolderPath,
            );
            if (newDirectory != null) {
              final result = await compute(
                ref
                    .read(metadataReaderRepositoryProvider)
                    .extractMetadataFromDirectory,
                newDirectory,
              );
              await metadataBox.addAll(result);
              return UnmodifiableListView(result);
            } else {
              return UnmodifiableListView([]);
            }
          } else if (Platform.isIOS) {
            final pickedFiles = await FilePicker.platform.pickFiles(
              allowMultiple: true,
              dialogTitle: "Pick Song Files",
            );

            if (pickedFiles == null || pickedFiles.files.isEmpty) {
              return UnmodifiableListView([]);
            }

            final result = await compute(
              ref
                  .read(metadataReaderRepositoryProvider)
                  .extractMetadataFromFiles,
              pickedFiles.files.map((f) => f.path!).toList(),
            );

            await metadataBox.addAll(result);
            return UnmodifiableListView(result);
          }
          // On Android Automatically Fetch Music Files
          else {
            final OnAudioQuery audioQuery = OnAudioQuery();
            final queriedSongs = await audioQuery.querySongs();

            final result = await compute(
              ref
                  .read(metadataReaderRepositoryProvider)
                  .extractMetadataFromFiles,
              queriedSongs.map((e) => e.data).toList(growable: false),
            );
            await metadataBox.addAll(result);
            return UnmodifiableListView(result);
          }
        }
        // Return cached metadata
        else {
          return UnmodifiableListView(metadataBox.values);
        }
      }
    } catch (e) {
      return UnmodifiableListView([]);
    }
  }

  Future<void> addMusicFolderAndScan(
    String folderPath,
    String folderName,
  ) async {
    try {
      // Add folder to user music folders
      await ref
          .read(userMusicFoldersProvider.notifier)
          .addMusicFolder(
            folderPath: folderPath,
            folderName: folderName,
          );

      // Extract metadata from the folder
      final result = await compute(
        ref
            .read(metadataReaderRepositoryProvider)
            .extractMetadataFromDirectory,
        folderPath,
      );

      if (result.isEmpty) {
        throw Exception(
          'No audio files found in $folderPath. Supported formats: MP3, OGG, OPUS, WAV, FLAC, M4A, AAC',
        );
      }

      // Add to metadata box
      final metadataBox = Hive.box<MusicMetadata>(Constants.metadataBoxName);
      final uniqueResults = result.where((metadata) {
        return !metadataBox.values.any(
          (existing) => existing.filePath == metadata.filePath,
        );
      }).toList();

      if (uniqueResults.isNotEmpty) {
        await metadataBox.addAll(uniqueResults);
      }

      // Refresh the provider with all music
      state = AsyncValue.data(
        UnmodifiableListView(metadataBox.values),
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> removeMusicFolderAndRefresh(dynamic folderKey) async {
    try {
      // Remove folder
      await ref
          .read(userMusicFoldersProvider.notifier)
          .removeMusicFolder(folderKey: folderKey);

      // Refresh metadata - you might want to clear and rescan,
      // or keep existing files. For now, we'll keep them.
      final metadataBox = Hive.box<MusicMetadata>(Constants.metadataBoxName);
      state = AsyncValue.data(
        UnmodifiableListView(metadataBox.values),
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
