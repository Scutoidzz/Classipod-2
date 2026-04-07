import 'package:hive_ce_flutter/hive_flutter.dart';

class UserMusicFolderModel extends HiveObject {
  final String folderPath;
  final String folderName;

  UserMusicFolderModel({
    required this.folderPath,
    required this.folderName,
  });

  UserMusicFolderModel copyWith({String? folderPath, String? folderName}) {
    return UserMusicFolderModel(
      folderPath: folderPath ?? this.folderPath,
      folderName: folderName ?? this.folderName,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UserMusicFolderModel &&
        other.folderPath == folderPath &&
        other.folderName == folderName;
  }

  @override
  int get hashCode => Object.hash(folderPath, folderName);

  @override
  String toString() {
    return 'UserMusicFolderModel(folderPath: $folderPath, folderName: $folderName)';
  }
}
