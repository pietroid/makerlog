/// A single entry in the worklog.
class WorklogEntry {
  final DateTime timestamp;
  final String text;

  WorklogEntry({
    required this.timestamp,
    required this.text,
  });

  /// Serialises to a Markdown bullet with an ISO timestamp.
  String toMarkdown() {
    final iso = timestamp.toIso8601String();
    return '- **[$iso]** $text';
  }

  /// Parses a line that matches [toMarkdown] format.
  static WorklogEntry? fromMarkdown(String line) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('- **[')) return null;
    final closeBracket = trimmed.indexOf(']**');
    if (closeBracket == -1) return null;
    final iso = trimmed.substring(5, closeBracket);
    final text = trimmed.substring(closeBracket + 3).trim();
    if (text.isEmpty) return null;
    try {
      return WorklogEntry(
        timestamp: DateTime.parse(iso),
        text: text,
      );
    } catch (_) {
      return null;
    }
  }
}
