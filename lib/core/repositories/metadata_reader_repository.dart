import 'dart:collection';
import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:classipod/core/models/music_metadata.dart';
import 'package:classipod/core/providers/device_directory_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final metadataReaderRepositoryProvider =
    Provider.autoDispose<MetadataReaderRepository>((ref) {
      final documentsDirectory = ref
          .read(deviceDirectoryProvider)
          .requireValue
          .documentsDirectory;
      final thumbnailsDirectoryPath =
          '${documentsDirectory.path}/ClassiPod/thumbnails';
      Directory(thumbnailsDirectoryPath).createSync(recursive: true);
      return MetadataReaderRepository(thumbnailsDirectoryPath);
    });

class MetadataReaderRepository {
  final String thumbnailsDirectoryPath;

  MetadataReaderRepository(this.thumbnailsDirectoryPath);

  bool isSupportedAudioFormat(String path) {
    if (path.endsWith('.mp3') ||
        path.endsWith('.ogg') ||
        path.endsWith('.opus') ||
        path.endsWith('.wav') ||
        path.endsWith('.flac') ||
        path.endsWith('.m4a') ||
        path.endsWith('.aac')) {
      return true;
    } else {
      return false;
    }
  }

  String getThumbnailPath({
    required String? albumName,
    required String? artistName,
    required String filePath,
  }) {
    final String? normalizedAlbumName = normalizeMetadataString(albumName);
    final String? normalizedArtistName = normalizeMetadataString(artistName);
    String albumArtFileName;
    if (normalizedAlbumName == null || normalizedArtistName == null) {
      albumArtFileName = filePath;
    } else {
      albumArtFileName = '${normalizedAlbumName}by$normalizedArtistName';
    }
    albumArtFileName = albumArtFileName
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll('/', '-')
        .replaceAll(' ', '');
    return '$thumbnailsDirectoryPath/$albumArtFileName.jpg';
  }

  UnmodifiableListView<MusicMetadata> extractMetadataFromDirectory(
    String musicFolderPath,
  ) {
    final Directory storageDir = Directory(musicFolderPath);
    final List<FileSystemEntity> files = storageDir.listSync(
      recursive: true,
      followLinks: false,
    );
    final List<String> filePaths = files.map((e) => e.path).toList();

    final List<MusicMetadata> metadataList = [];

    AudioMetadata audioMetadata;

    for (final String path in filePaths) {
      try {
        if (isSupportedAudioFormat(path)) {
          audioMetadata = readMetadata(File(path), getImage: true);

          final String thumbnailPath = getThumbnailPath(
            albumName: audioMetadata.album,
            artistName: audioMetadata.artist,
            filePath: path,
          );

          if (audioMetadata.pictures.isNotEmpty) {
            File(
              thumbnailPath,
            ).writeAsBytesSync(audioMetadata.pictures[0].bytes);
          }

          metadataList.add(
            MusicMetadata.fromAudioMetadata(
              audioMetadata,
              thumbnailPath,
              metadataList.length,
            ),
          );
        }
      } catch (e) {
        debugPrint("Metadata Parsing Error: $e");
      }
    }

    return UnmodifiableListView(metadataList);
  }

  UnmodifiableListView<MusicMetadata> extractMetadataFromFiles(
    List<String> filePaths,
  ) {
    final List<MusicMetadata> metadataList = [];

    AudioMetadata audioMetadata;

    for (final String path in filePaths) {
      try {
        if (isSupportedAudioFormat(path)) {
          audioMetadata = readMetadata(File(path), getImage: true);

          final String thumbnailPath = getThumbnailPath(
            albumName: audioMetadata.album,
            artistName: audioMetadata.artist,
            filePath: path,
          );

          if (audioMetadata.pictures.isNotEmpty) {
            File(
              thumbnailPath,
            ).writeAsBytesSync(audioMetadata.pictures[0].bytes);
          }

          metadataList.add(
            MusicMetadata.fromAudioMetadata(
              audioMetadata,
              thumbnailPath,
              metadataList.length,
            ),
          );
        }
      } catch (e) {
        debugPrint("Metadata Parsing Error: $e");
      }
    }

    return UnmodifiableListView(metadataList);
  }
}
