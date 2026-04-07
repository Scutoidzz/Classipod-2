import 'dart:convert';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:audio_service/audio_service.dart';
import 'package:classipod/core/constants/constants.dart';
import 'package:classipod/features/music/album/models/album_model.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';

String? normalizeMetadataString(String? value) {
  if (value == null || value.isEmpty) {
    return value;
  }

  final codeUnits = value.codeUnits;

  if (codeUnits.isEmpty || codeUnits.first != 0xFFFE) {
    return value;
  }

  final StringBuffer buffer = StringBuffer();

  for (final int unit in codeUnits) {
    final int swappedUnit = ((unit & 0xFF) << 8) | (unit >> 8);

    if (swappedUnit == 0xFEFF) {
      continue;
    }

    buffer.writeCharCode(swappedUnit);
  }

  final String normalizedValue = buffer.toString();

  return normalizedValue.isEmpty ? value : normalizedValue;
}

List<String> _splitArtistNames(String artist) {
  if (artist.contains(',')) {
    return artist.split(',').map((name) => name.trim()).toList();
  } else if (artist.contains('/')) {
    return artist.split('/').map((name) => name.trim()).toList();
  } else if (artist.contains(';')) {
    return artist.split(';').map((name) => name.trim()).toList();
  }

  return [artist];
}

String? _normalizeDynamicString(dynamic value) {
  if (value == null) {
    return null;
  }

  return normalizeMetadataString(value.toString());
}

List<String>? _parseTrackArtistNames(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is List) {
    final List<String> artistNames = value
        .map((artistName) => _normalizeDynamicString(artistName))
        .whereType<String>()
        .where((artistName) => artistName.isNotEmpty)
        .toList(growable: false);

    return artistNames.isEmpty ? null : artistNames;
  }

  final String? artistNames = _normalizeDynamicString(value);
  if (artistNames == null || artistNames.isEmpty) {
    return null;
  }

  return artistNames.split('/').map((name) => name.trim()).toList();
}

List<String> _parseGenres(dynamic value) {
  if (value is List) {
    return value
        .map((genre) => genre?.toString())
        .whereType<String>()
        .where((genre) => genre.isNotEmpty)
        .toList(growable: false);
  }

  return const <String>[];
}

class MusicMetadata extends HiveObject {
  /// Name of the track.
  final String? trackName;

  /// Names of the artists performing in the track.
  final List<String>? trackArtistNames;

  /// Name of the album.
  final String? albumName;

  /// Name of the album artist.
  final String? albumArtistName;

  /// Position of track in the album.
  final int? trackNumber;

  /// Number of tracks in the album.
  final int? albumLength;

  /// Year of the track.
  final int? year;

  /// Genres of the track.
  final List<String> genres;

  /// Number of the disc.
  final int? discNumber;

  /// Mime type.
  final String? mimeType;

  /// Duration of the track in milliseconds.
  final int? trackDuration;

  /// Bitrate of the track.
  final int? bitrate;

  /// File path of the audio file.
  final String? filePath;

  /// File path of the thumbnail album art file.
  final String? thumbnailPath;

  /// Original Song Index
  final int originalSongIndex;

  /// Bool to Indicate that the File is Located On-Device
  final bool isOnDevice;

  /// Rating of the track.
  final int rating;

  final String? lyrics;

  MusicMetadata({
    this.trackName,
    this.trackArtistNames,
    this.albumName,
    this.albumArtistName,
    this.trackNumber,
    this.albumLength,
    this.year,
    this.genres = const [],
    this.discNumber,
    this.mimeType,
    this.trackDuration,
    this.bitrate,
    this.filePath,
    this.thumbnailPath,
    this.originalSongIndex = 0,
    this.isOnDevice = true,
    this.rating = 0,
    this.lyrics,
  });

  factory MusicMetadata.fromAudioMetadata(
    AudioMetadata audioMetadata,
    String? thumbnailPath,
    int originalSongIndex,
  ) {
    final artist =
        normalizeMetadataString(audioMetadata.artist) ?? "Unknown Artist";
    final List<String> trackArtistNames = _splitArtistNames(artist);

    return MusicMetadata(
      trackName:
          normalizeMetadataString(audioMetadata.title) ?? "Unknown Song",
      trackArtistNames: trackArtistNames,
      albumName:
          normalizeMetadataString(audioMetadata.album) ?? "Unknown Album",
      albumArtistName: trackArtistNames[0],
      trackNumber: audioMetadata.trackNumber,
      albumLength: audioMetadata.trackTotal,
      year: audioMetadata.year?.year,
      genres: audioMetadata.genres,
      discNumber: audioMetadata.discNumber,
      mimeType: audioMetadata.pictures.isEmpty
          ? null
          : audioMetadata.pictures[0].mimetype,
      trackDuration: audioMetadata.duration?.inMilliseconds,
      bitrate: audioMetadata.bitrate,
      filePath: audioMetadata.file.path,
      thumbnailPath: thumbnailPath,
      originalSongIndex: originalSongIndex,
      lyrics: audioMetadata.lyrics,
    );
  }

  factory MusicMetadata.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic> metadataMap = switch (map['metadata']) {
      final Map metadata => Map<String, dynamic>.from(metadata),
      _ => map,
    };

    return MusicMetadata(
      trackName: _normalizeDynamicString(metadataMap['trackName']),
      trackArtistNames: _parseTrackArtistNames(
        metadataMap['trackArtistNames'],
      ),
      albumName: _normalizeDynamicString(metadataMap['albumName']),
      albumArtistName: _normalizeDynamicString(
        metadataMap['albumArtistName'],
      ),
      trackNumber: parseInteger(metadataMap['trackNumber']),
      albumLength: parseInteger(metadataMap['albumLength']),
      year: parseInteger(metadataMap['year']),
      genres: _parseGenres(metadataMap['genres'] ?? map['genres']),
      discNumber: parseInteger(metadataMap['discNumber']),
      mimeType: _normalizeDynamicString(metadataMap['mimeType']),
      trackDuration: parseInteger(metadataMap['trackDuration']),
      bitrate: parseInteger(metadataMap['bitrate']),
      filePath: _normalizeDynamicString(
        metadataMap['filePath'] ?? map['filePath'],
      ),
      thumbnailPath: _normalizeDynamicString(
        metadataMap['thumbnailPath'] ?? map['thumbnailPath'],
      ),
      originalSongIndex: parseInteger(
            metadataMap['originalSongIndex'] ?? map['originalSongIndex'],
          ) ??
          0,
      isOnDevice:
          (metadataMap['isOnDevice'] ?? map['isOnDevice']) as bool? ?? true,
      rating: parseInteger(metadataMap['rating'] ?? map['rating']) ?? 0,
      lyrics: _normalizeDynamicString(
        metadataMap['lyrics'] ?? map['lyrics'],
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'trackName': trackName,
    'trackArtistNames': trackArtistNames,
    'albumName': albumName,
    'albumArtistName': albumArtistName,
    'trackNumber': trackNumber,
    'albumLength': albumLength,
    'year': year,
    'genres': genres,
    'discNumber': discNumber,
    'mimeType': mimeType,
    'trackDuration': trackDuration,
    'bitrate': bitrate,
    'filePath': filePath,
    'thumbnailPath': thumbnailPath,
    'originalSongIndex': originalSongIndex,
    'isOnDevice': isOnDevice,
    'rating': rating,
    'lyrics': lyrics,
  };

  factory MusicMetadata.fromJson(String source) =>
      MusicMetadata.fromMap(jsonDecode(source));

  String toJson() => jsonEncode(toMap());

  MusicMetadata copyWith({
    String? trackName,
    List<String>? trackArtistNames,
    String? albumName,
    String? albumArtistName,
    int? trackNumber,
    int? albumLength,
    int? year,
    List<String>? genres,
    int? discNumber,
    String? mimeType,
    int? trackDuration,
    int? bitrate,
    String? filePath,
    String? thumbnailPath,
    int? originalSongIndex,
    bool? isOnDevice,
    int? rating,
    String? lyrics,
  }) {
    return MusicMetadata(
      trackName: trackName ?? this.trackName,
      trackArtistNames: trackArtistNames ?? this.trackArtistNames,
      albumName: albumName ?? this.albumName,
      albumArtistName: albumArtistName ?? this.albumArtistName,
      trackNumber: trackNumber ?? this.trackNumber,
      albumLength: albumLength ?? this.albumLength,
      year: year ?? this.year,
      genres: genres ?? this.genres,
      discNumber: discNumber ?? this.discNumber,
      mimeType: mimeType ?? this.mimeType,
      trackDuration: trackDuration ?? this.trackDuration,
      bitrate: bitrate ?? this.bitrate,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      originalSongIndex: originalSongIndex ?? this.originalSongIndex,
      isOnDevice: isOnDevice ?? this.isOnDevice,
      rating: rating ?? this.rating,
      lyrics: lyrics ?? this.lyrics,
    );
  }

  AudioSource toAudioSource() {
    if (isOnDevice) {
      return AudioSource.file(
        filePath ?? '',
        tag: MediaItem(
          id: filePath ?? '',
          title: trackName ?? "Unknown Song",
          album: albumName ?? "Unknown Album",
          artist: getTrackArtistNames,
          genre: genres.isEmpty ? null : genres[0],
          duration: trackDuration != null
              ? Duration(milliseconds: trackDuration!)
              : null,
          artUri: thumbnailPath == null
              ? Uri.file(filePath!)
              : Uri.file(thumbnailPath!),
          rating: Rating.newStarRating(RatingStyle.range5stars, rating),
          extras: {"loadThumbnailUri": true},
        ),
      );
    } else {
      return AudioSource.uri(
        Uri.parse(filePath ?? ''),
        tag: MediaItem(
          id: filePath ?? '',
          title: trackName ?? "Unknown Song",
          album: albumName ?? "Unknown Album",
          artist: getTrackArtistNames,
          genre: genres.isEmpty ? null : genres[0],
          duration: trackDuration != null
              ? Duration(milliseconds: trackDuration!)
              : null,
          artUri: thumbnailPath == null
              ? Uri.parse(Constants.defaultNotificationAlbumArtImageUrl)
              : Uri.file(thumbnailPath!),
          rating: Rating.newStarRating(RatingStyle.range5stars, rating),
        ),
      );
    }
  }

  @override
  String toString() => toJson().toString();

  String get getTrackName {
    return trackName ?? 'Unknown Song';
  }

  String get getAlbumName {
    return albumName ?? "Unknown Album";
  }

  String get getAlbumArtistName {
    return albumArtistName ?? "Unknown Album Artist";
  }

  int get getTrackNumber {
    return trackNumber ?? 0;
  }

  int get getTrackDuration {
    return trackDuration ?? 0;
  }

  String get getMainArtistName {
    return trackArtistNames?[0] ?? "Unknown Artist";
  }

  String? get getTrackArtistNames {
    return trackArtistNames?.toString().substring(
      1,
      trackArtistNames.toString().length - 1,
    );
  }

  String get getMainGenre {
    return genres.isNotEmpty ? genres[0] : "Unknown Genre";
  }

  AlbumModel get getAlbumDetail {
    return AlbumModel(
      albumName: getAlbumName,
      albumArtPath: thumbnailPath,
      albumArtistName: getAlbumArtistName,
      albumSongs: [this],
    );
  }

  String? get parentDirectoryPath {
    if (filePath == null) return null;

    // Normalize separators to forward slash for processing
    String normalizedPath = filePath!.replaceAll('\\', '/');

    // Remove trailing slash if present
    if (normalizedPath.endsWith('/')) {
      normalizedPath = normalizedPath.substring(0, normalizedPath.length - 1);
    }

    // Find the last separator index
    final int lastSeparatorIndex = normalizedPath.lastIndexOf('/');

    // If no separator found, return root (or empty string)
    if (lastSeparatorIndex == -1) return null;

    String parent = normalizedPath.substring(0, lastSeparatorIndex);

    // For Windows: if the path is like C:/folder, preserve the drive letter and slash
    if (parent.length == 2 && parent[1] == ':') {
      parent += '/';
    }

    // Restore original backslashes on Windows if needed
    if (filePath!.contains('\\')) {
      parent = parent.replaceAll('/', '\\');
    }

    return parent;
  }

  @override
  bool operator ==(Object other) {
    return other is MusicMetadata &&
        trackName == other.trackName &&
        listEquals(trackArtistNames, other.trackArtistNames) &&
        albumName == other.albumName &&
        albumArtistName == other.albumArtistName &&
        trackNumber == other.trackNumber &&
        albumLength == other.albumLength &&
        year == other.year &&
        listEquals(genres, other.genres) &&
        discNumber == other.discNumber &&
        mimeType == other.mimeType &&
        trackDuration == other.trackDuration &&
        bitrate == other.bitrate &&
        filePath == other.filePath &&
        rating == other.rating &&
        lyrics == other.lyrics;
  }

  @override
  int get hashCode => Object.hash(
    trackName,
    trackArtistNames,
    albumName,
    albumArtistName,
    trackNumber,
    albumLength,
    year,
    genres,
    discNumber,
    mimeType,
    trackDuration,
    bitrate,
    filePath,
    rating,
    lyrics,
  );
}

int? parseInteger(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  } else if (value is String) {
    try {
      try {
        return int.parse(value);
      } catch (_) {
        return int.parse(value.split('/').first);
      }
    } catch (_) {}
  }
  return null;
}
