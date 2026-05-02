import 'package:makerlog/common/repository/common_repository.dart';
import 'package:makerlog/worklog/repository/worklog_entry.dart';

/// Handles durable storage of the worklog as a Markdown file.
///
/// The backing file is `.makerlog/worklog.md`. Every non-empty line is
/// treated as one entry. The file is the single source of truth.
class WorklogRepository {
  final CommonRepository _common;

  static const String _filePath = 'worklog.md';

  WorklogRepository({CommonRepository? common})
      : _common = common ?? CommonRepository();

  /// Loads existing entries from disk. Returns an empty list when the
  /// file has not been created yet.
  Future<List<WorklogEntry>> load() async {
    final raw = await _common.readFile(_filePath);
    if (raw == null || raw.isEmpty) return [];
    return raw
        .split('\n')
        .map(WorklogEntry.fromMarkdown)
        .whereType<WorklogEntry>()
        .toList();
  }

  /// Persists [text] to disk as a new line and reloads the file.
  Future<List<WorklogEntry>> append(String text) async {
    final line = '${text.trim()}\n';
    await _common.appendFile(_filePath, line);
    return load();
  }
}
