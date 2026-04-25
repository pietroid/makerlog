import 'dart:async';

import 'package:fly_bloc/fly_bloc.dart';
import 'package:makerlog/bot/cubit/bot_state.dart';
import 'package:makerlog/bot/repository/bot_repository.dart';

/// Owns model-level bot lifecycle: is the configured model pulled,
/// and if not, pull it. Assumes the Ollama daemon is already up —
/// that precondition is owned by `OllamaSetupCubit`.
///
/// Inference is exposed as high-level methods (e.g.
/// [askForThreeAnswers]) that bake the prompt template into the bot
/// layer, so the chat UI only has to forward the raw user text. The
/// generated text is accumulated into `state.message` as it streams
/// in, then the cubit flips to [BotStatus.answered] when done — which
/// the chat watches to know the reply is complete.
class BotCubit extends Cubit<BotState> {
  final BotRepository repository;

  static const String _threeAnswersSystem =
      'You are a playful oracle. Answer the user\'s question with '
      'exactly three short possible answers, each on its own line, '
      'numbered "1.", "2.", "3.". Keep each answer under 15 words. '
      'Do not add any preamble or closing remarks.';

  BotCubit({required this.repository}) : super(const BotState());

  String get model => repository.model;

  Future<void> ensureReady() async {
    emit(state.copyWith(
      status: BotStatus.checkingModel,
      message: 'Checking whether the model '
          '"${repository.model}" is already installed...',
      clearProgress: true,
      clearError: true,
    ));

    final bool hasModel;
    try {
      hasModel = await repository.hasModel(repository.model);
    } catch (e) {
      emit(state.copyWith(
        status: BotStatus.error,
        message: 'Failed to list local models: $e',
        error: e.toString(),
      ));
      return;
    }

    if (!hasModel) {
      emit(state.copyWith(
        status: BotStatus.modelMissing,
        message:
            'Model "${repository.model}" is not installed. Starting download — '
            'this may take a while on the first run.',
      ));

      try {
        await for (final p in repository.pullModel(repository.model)) {
          final fraction = p.fraction;
          final pct = fraction != null
              ? ' (${(fraction * 100).toStringAsFixed(1)}%)'
              : '';
          emit(state.copyWith(
            status: BotStatus.installing,
            message: 'Downloading "${repository.model}": ${p.status}$pct',
            progress: fraction,
          ));
        }
      } catch (e) {
        emit(state.copyWith(
          status: BotStatus.error,
          message: 'Failed to install model: $e',
          error: e.toString(),
        ));
        return;
      }
    }

    emit(state.copyWith(
      status: BotStatus.ready,
      message: 'Local model "${repository.model}" is ready.',
      clearProgress: true,
    ));
  }

  /// Ask the model for three short, numbered answers to [question].
  ///
  /// While tokens stream in, `state.message` holds the text accumulated
  /// so far and `state.status` is [BotStatus.answering]; the chat uses
  /// this to live-update the reply bubble. When the stream ends the
  /// cubit emits [BotStatus.answered] with the final text, then
  /// settles back to [BotStatus.ready] so the next prompt can run.
  Future<void> askForThreeAnswers(String question) async {
    if (state.status != BotStatus.ready &&
        state.status != BotStatus.answered) {
      emit(state.copyWith(
        status: BotStatus.error,
        message: 'Bot is not ready yet (status=${state.status.name}).',
      ));
      return;
    }

    final prompt = '$_threeAnswersSystem\n\nQuestion: $question';
    final buffer = StringBuffer();
    emit(state.copyWith(
      status: BotStatus.answering,
      message: '',
      clearProgress: true,
      clearError: true,
    ));

    try {
      await for (final chunk in repository.generate(prompt)) {
        buffer.write(chunk);
        emit(state.copyWith(
          status: BotStatus.answering,
          message: buffer.toString(),
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: BotStatus.error,
        message: 'Generation failed: $e',
        error: e.toString(),
      ));
      return;
    }

    emit(state.copyWith(
      status: BotStatus.answered,
      message: buffer.toString().trim(),
    ));
  }
}
