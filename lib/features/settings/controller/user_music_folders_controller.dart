import 'package:classipod/core/constants/constants.dart';
import 'package:classipod/features/settings/models/user_music_folder_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

final userMusicFoldersProvider = NotifierProvider<
    UserMusicFoldersNotifier,
    List<UserMusicFolderModel>
>(
  UserMusicFoldersNotifier.new,
);

class UserMusicFoldersNotifier extends Notifier<List<UserMusicFolderModel>> {
  late final Box<UserMusicFolderModel> _userMusicFoldersBox;

  @override
  List<UserMusicFolderModel> build() {
    _userMusicFoldersBox = Hive.box<UserMusicFolderModel>(
      Constants.userMusicFoldersBoxName,
    );
    return _userMusicFoldersBox.values.toList();
  }

  List<String> get folderPaths {
    return _userMusicFoldersBox.values
        .map((folder) => folder.folderPath)
        .toList();
  }

  Future<void> addMusicFolder({
    required String folderPath,
    required String folderName,
  }) async {
    // Check if folder already exists
    if (_userMusicFoldersBox.values
        .any((folder) => folder.folderPath == folderPath)) {
      return;
    }

    final newFolder = UserMusicFolderModel(
      folderPath: folderPath,
      folderName: folderName,
    );
    await _userMusicFoldersBox.add(newFolder);
    state = _userMusicFoldersBox.values.toList();
  }

  Future<void> removeMusicFolder({required dynamic folderKey}) async {
    if (folderKey == null) return;

    await _userMusicFoldersBox.delete(folderKey);
    state = _userMusicFoldersBox.values.toList();
  }

  Future<void> renameMusicFolder({
    required dynamic folderKey,
    required String newName,
  }) async {
    if (folderKey == null) return;

    final folder = _userMusicFoldersBox.get(folderKey);
    if (folder != null) {
      await _userMusicFoldersBox.put(
        folderKey,
        folder.copyWith(folderName: newName),
      );
      state = _userMusicFoldersBox.values.toList();
    }
  }
}
