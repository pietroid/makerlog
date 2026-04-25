import 'package:makerlog/common/repository/common_repository.dart';
import 'package:makerlog/worklog/repository/worklog_entry.dart';

/// Handles durable storage of the worklog as a Markdown file.
///
/// The backing file is `.makerbook/worklog.md`. Every entry is a
/// single Markdown bullet with an ISO timestamp. The file is kept
/// in sync with the in-memory list: [append] writes immediately.
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

  /// Persists [entry] to disk and returns it.
  Future<WorklogEntry> append(WorklogEntry entry) async {
    final line = '${entry.toMarkdown()}\n';
    await _common.appendFile(_filePath, line);
    return entry;
  }
}
