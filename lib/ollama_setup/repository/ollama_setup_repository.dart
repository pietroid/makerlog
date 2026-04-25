import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ollama_dart/ollama_dart.dart';

/// Thin wrapper over host-level concerns: is the `ollama` binary
/// installed, is the daemon reachable, and if not, install/start it.
///
/// Kept deliberately small so the domain boundary is obvious — model
/// management and inference live in `BotRepository`; this class only
/// deals with making sure the Ollama server exists and is up.
class OllamaSetupRepository {
  static const List<String> _candidatePaths = [
    '/usr/local/bin/ollama',
    '/opt/homebrew/bin/ollama',
    '/usr/bin/ollama',
  ];

  final OllamaClient _client;

  OllamaSetupRepository({OllamaClient? client})
      : _client = client ?? OllamaClient();

  /// Locate the `ollama` executable on PATH, falling back to the
  /// common install locations. Returns the absolute path or `null`.
  Future<String?> findOllamaBinary() async {
    final which = Platform.isWindows ? 'where' : 'which';
    try {
      final result = await Process.run(which, ['ollama']);
      if (result.exitCode == 0) {
        final line = (result.stdout as String).split('\n').first.trim();
        if (line.isNotEmpty) return line;
      }
    } on ProcessException {
      // `which`/`where` missing — fall through to the path probe.
    }
    for (final path in _candidatePaths) {
      if (await File(path).exists()) return path;
    }
    return null;
  }

  Future<bool> isInstalled() async => (await findOllamaBinary()) != null;

  /// Quick server liveness probe via `/api/version`.
  Future<bool> isServerRunning() async {
    try {
      final version = await _client.version.get();
      return version.version?.isNotEmpty ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Run the official install script in a subshell and forward its
  /// stdout/stderr line-by-line so the UI can narrate progress. The
  /// script prompts for sudo on macOS/Linux — callers should surface
  /// this up-front.
  ///
  /// Throws if the installer exits non-zero or the platform isn't
  /// supported.
  Stream<String> installOllama() async* {
    if (!(Platform.isMacOS || Platform.isLinux)) {
      throw UnsupportedError(
        'Automatic install is only supported on macOS/Linux. '
        'Please install Ollama manually from https://ollama.com',
      );
    }
    final process = await Process.start(
      'sh',
      ['-c', 'curl -fsSL https://ollama.com/install.sh | sh'],
    );
    final controller = StreamController<String>();
    var openStreams = 2;
    void onDone() {
      openStreams -= 1;
      if (openStreams == 0) controller.close();
    }

    process.stdout
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .listen(controller.add, onError: controller.addError, onDone: onDone);
    process.stderr
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .listen(controller.add, onError: controller.addError, onDone: onDone);

    await for (final line in controller.stream) {
      if (line.trim().isNotEmpty) yield line;
    }
    final code = await process.exitCode;
    if (code != 0) {
      throw Exception('Ollama installer exited with code $code');
    }
  }

  /// Start `ollama serve` detached, then poll `/api/version` until it
  /// responds (or [timeout] elapses).
  Future<void> startServer({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final binary = await findOllamaBinary();
    if (binary == null) {
      throw StateError('Ollama is not installed.');
    }
    await Process.start(
      binary,
      ['serve'],
      mode: ProcessStartMode.detached,
    );
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await isServerRunning()) return;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    throw Exception('Ollama server did not come up within $timeout.');
  }

  void close() => _client.close();
}
