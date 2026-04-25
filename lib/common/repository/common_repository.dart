import 'dart:io';

/// Shared file-system helpers for the `.makerbook` working directory.
///
/// All domain repositories that need durable storage should go through
/// this class so path logic lives in one place.
class CommonRepository {
  /// The root directory inside the user's home where all makerbook
  /// data is kept.
  static final Directory _makerbookDir = Directory(
    '${Platform.environment['HOME']}/.makerbook',
  );

  Directory get makerbookDir => _makerbookDir;

  /// Ensures the `.makerbook` directory (and any optional [subPath])
  /// exists on disk.
  Future<Directory> ensureDirectory([String? subPath]) async {
    final path = subPath == null
        ? _makerbookDir.path
        : '${_makerbookDir.path}/$subPath';
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Reads a file inside `.makerbook/[relativePath]`. Returns `null`
  /// when the file does not exist yet.
  Future<String?> readFile(String relativePath) async {
    final file = File('${_makerbookDir.path}/$relativePath');
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  /// Writes [contents] to a file inside `.makerbook/[relativePath]`,
  /// creating missing parent directories automatically.
  Future<void> writeFile(String relativePath, String contents) async {
    final file = File('${_makerbookDir.path}/$relativePath');
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    await file.writeAsString(contents);
  }

  /// Appends [contents] to a file inside `.makerbook/[relativePath]`,
  /// creating the file and parent directories if necessary.
  Future<void> appendFile(String relativePath, String contents) async {
    final file = File('${_makerbookDir.path}/$relativePath');
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    await file.writeAsString(contents, mode: FileMode.append);
  }
}
