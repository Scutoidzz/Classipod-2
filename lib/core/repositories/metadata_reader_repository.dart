import 'dart:collection';
import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:classipod/core/models/music_metadata.dart';
import 'package:classipod/core/providers/device_directory_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String _thumbnailsDirectoryPathKey = 'thumbnailsDirectoryPath';
const String _musicFolderPathKey = 'musicFolderPath';
const String _filePathsKey = 'filePaths';

Future<List<Map<String, dynamic>>> extractMetadataMapsFromDirectoryInBackground(
  Map<String, dynamic> request,
) async {
  final metadataReaderRepository = MetadataReaderRepository(
    request[_thumbnailsDirectoryPathKey] as String,
  );

  final UnmodifiableListView<MusicMetadata> metadataList =
      await metadataReaderRepository.extractMetadataFromDirectoryAsync(
        request[_musicFolderPathKey] as String,
      );

  return metadataList
      .map((metadata) => metadata.toMap())
      .toList(growable: false);
}

Future<List<Map<String, dynamic>>> extractMetadataMapsFromFilesInBackground(
  Map<String, dynamic> request,
) async {
  final metadataReaderRepository = MetadataReaderRepository(
    request[_thumbnailsDirectoryPathKey] as String,
  );
  final List<String> filePaths = List<String>.from(
    request[_filePathsKey] as List<dynamic>,
  );
  final UnmodifiableListView<MusicMetadata> metadataList =
      metadataReaderRepository.extractMetadataFromFiles(filePaths);

  return metadataList
      .map((metadata) => metadata.toMap())
      .toList(growable: false);
}

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

  Map<String, dynamic> buildDirectoryScanRequest({
    required String musicFolderPath,
  }) {
    return <String, dynamic>{
      _thumbnailsDirectoryPathKey: thumbnailsDirectoryPath,
      _musicFolderPathKey: musicFolderPath,
    };
  }

  Map<String, dynamic> buildFilesScanRequest({
    required List<String> filePaths,
  }) {
    return <String, dynamic>{
      _thumbnailsDirectoryPathKey: thumbnailsDirectoryPath,
      _filePathsKey: filePaths,
    };
  }

  UnmodifiableListView<MusicMetadata> metadataFromMaps(
    Iterable<Map<String, dynamic>> metadataMaps,
  ) {
    return UnmodifiableListView(
      metadataMaps
          .map(MusicMetadata.fromMap)
          .toList(growable: false),
    );
  }

  bool isSupportedAudioFormat(String path) {
    final String normalizedPath = path.toLowerCase();
    if (normalizedPath.endsWith('.mp3') ||
        normalizedPath.endsWith('.ogg') ||
        normalizedPath.endsWith('.opus') ||
        normalizedPath.endsWith('.wav') ||
        normalizedPath.endsWith('.flac') ||
        normalizedPath.endsWith('.m4a') ||
        normalizedPath.endsWith('.aac')) {
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
    final List<String> filePaths = <String>[];

    try {
      for (final FileSystemEntity entity in storageDir.listSync(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File && isSupportedAudioFormat(entity.path)) {
          filePaths.add(entity.path);
        }
      }
    } on FileSystemException catch (error) {
      debugPrint("Directory Scan Error: $error");
    }

    return extractMetadataFromFiles(filePaths);
  }

  Future<UnmodifiableListView<MusicMetadata>> extractMetadataFromDirectoryAsync(
    String musicFolderPath,
  ) async {
    final Directory storageDir = Directory(musicFolderPath);
    final List<String> filePaths = <String>[];

    if (!storageDir.existsSync()) {
      return UnmodifiableListView(const <MusicMetadata>[]);
    }

    try {
      await for (final FileSystemEntity entity in storageDir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File && isSupportedAudioFormat(entity.path)) {
          filePaths.add(entity.path);
        }
      }
    } on FileSystemException catch (error) {
      debugPrint("Directory Scan Error: $error");
    }

    return extractMetadataFromFiles(filePaths);
  }

  UnmodifiableListView<MusicMetadata> extractMetadataFromFiles(
    List<String> filePaths,
  ) {
    final List<MusicMetadata> metadataList = <MusicMetadata>[];

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
