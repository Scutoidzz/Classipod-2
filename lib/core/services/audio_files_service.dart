import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:classipod/core/constants/constants.dart';
import 'package:classipod/core/constants/online_audio_files_metadata.dart';
import 'package:classipod/core/models/music_metadata.dart';
import 'package:classipod/core/providers/device_directory_provider.dart';
import 'package:classipod/core/repositories/metadata_reader_repository.dart';
import 'package:classipod/features/settings/controller/settings_preferences_controller.dart';
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
              final metadataReaderRepository = ref.read(
                metadataReaderRepositoryProvider,
              );
              final metadataMaps = await compute(
                extractMetadataMapsFromDirectoryInBackground,
                metadataReaderRepository.buildDirectoryScanRequest(
                  musicFolderPath: newDirectory,
                ),
              );
              final result = metadataReaderRepository.metadataFromMaps(
                metadataMaps,
              );
              await metadataBox.addAll(result);
              return UnmodifiableListView(result);
            } else {
              return UnmodifiableListView([]);
            }
          } else if (Platform.isIOS) {
            final newDirectory = await FilePicker.platform.getDirectoryPath(
              dialogTitle: "Select Music Folder",
            );

            if (newDirectory == null) {
              return UnmodifiableListView([]);
            }

            final metadataReaderRepository = ref.read(
              metadataReaderRepositoryProvider,
            );
            final metadataMaps = await compute(
              extractMetadataMapsFromDirectoryInBackground,
              metadataReaderRepository.buildDirectoryScanRequest(
                musicFolderPath: newDirectory,
              ),
            );
            final result = metadataReaderRepository.metadataFromMaps(
              metadataMaps,
            );

            await metadataBox.addAll(result);
            return UnmodifiableListView(result);
          }
          // On Android Automatically Fetch Music Files
          else {
            final OnAudioQuery audioQuery = OnAudioQuery();
            final queriedSongs = await audioQuery.querySongs();

            final metadataReaderRepository = ref.read(
              metadataReaderRepositoryProvider,
            );
            final metadataMaps = await compute(
              extractMetadataMapsFromFilesInBackground,
              metadataReaderRepository.buildFilesScanRequest(
                filePaths: queriedSongs
                    .map((song) => song.data)
                    .toList(growable: false),
              ),
            );
            final result = metadataReaderRepository.metadataFromMaps(
              metadataMaps,
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
}
