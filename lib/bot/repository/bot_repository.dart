import 'dart:async';

import 'package:ollama_dart/ollama_dart.dart';

/// Progress event emitted while pulling a model from Ollama. Mirrors
/// the fields of ollama_dart's [PullResponse] in a form the UI layer
/// can consume without coupling to the HTTP client.
class OllamaProgress {
  final String status;
  final int? completed;
  final int? total;

  OllamaProgress({required this.status, this.completed, this.total});

  double? get fraction =>
      (total != null && total! > 0 && completed != null)
          ? completed! / total!
          : null;
}

/// Model-management + inference wrapper on top of [OllamaClient].
///
/// Assumes the daemon is already up; that concern lives in
/// `OllamaSetupRepository`.
class BotRepository {
  static const String defaultModel = 'gemma3';

  final OllamaClient _client;
  String model;

  BotRepository({
    OllamaClient? client,
    this.model = defaultModel,
  }) : _client = client ?? OllamaClient();

  Future<bool> hasModel(String name) async {
    final response = await _client.models.list();
    final models = response.models ?? const <ModelSummary>[];
    return models.any(
      (m) => m.name == name || (m.name?.startsWith('$name:') ?? false),
    );
  }

  /// Stream pull progress for a model.
  Stream<OllamaProgress> pullModel(String name) async* {
    final stream = _client.models.pullStream(
      request: PullRequest(model: name),
    );
    await for (final event in stream) {
      yield OllamaProgress(
        status: event.status ?? '',
        completed: event.completed,
        total: event.total,
      );
    }
  }

  Stream<String> generate(String prompt) async* {
    final stream = _client.completions.generateStream(
      request: GenerateRequest(model: model, prompt: prompt),
    );
    await for (final chunk in stream) {
      final text = chunk.response;
      if (text != null && text.isNotEmpty) yield text;
      if (chunk.done ?? false) break;
    }
  }

  void close() => _client.close();
}
