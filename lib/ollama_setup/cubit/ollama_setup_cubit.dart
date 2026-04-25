import 'dart:async';

import 'package:fly_bloc/fly_bloc.dart';
import 'package:makerlog/ollama_setup/cubit/ollama_setup_state.dart';
import 'package:makerlog/ollama_setup/repository/ollama_setup_repository.dart';

/// Orchestrates the host-level ollama bootstrap: CLI present? daemon
/// up? If not, install/start and narrate along the way.
class OllamaSetupCubit extends Cubit<OllamaSetupState> {
  final OllamaSetupRepository repository;

  OllamaSetupCubit({required this.repository})
      : super(const OllamaSetupState());

  Future<void> ensureRunning() async {
    emit(state.copyWith(
      status: OllamaSetupStatus.checkingInstallation,
      message: 'Checking whether the Ollama CLI is installed...',
      clearError: true,
    ));

    if (!await repository.isInstalled()) {
      emit(state.copyWith(
        status: OllamaSetupStatus.notInstalled,
        message: 'Ollama is not installed. Running the official installer — '
            'you may be prompted for your sudo password.',
      ));
      try {
        await for (final line in repository.installOllama()) {
          emit(state.copyWith(
            status: OllamaSetupStatus.installing,
            message: line,
          ));
        }
      } on UnsupportedError catch (e) {
        emit(state.copyWith(
          status: OllamaSetupStatus.unsupportedPlatform,
          message: e.message ?? e.toString(),
          error: e.toString(),
        ));
        return;
      } catch (e) {
        emit(state.copyWith(
          status: OllamaSetupStatus.error,
          message: 'Failed to install Ollama: $e',
          error: e.toString(),
        ));
        return;
      }
    }

    emit(state.copyWith(
      status: OllamaSetupStatus.checkingServer,
      message: 'Ollama is installed. Checking if the daemon is running...',
    ));

    if (await repository.isServerRunning()) {
      emit(state.copyWith(
        status: OllamaSetupStatus.ready,
        message: 'Ollama daemon is already running.',
      ));
      return;
    }

    emit(state.copyWith(
      status: OllamaSetupStatus.startingServer,
      message: 'Starting the Ollama daemon in the background...',
    ));

    try {
      await repository.startServer();
    } catch (e) {
      emit(state.copyWith(
        status: OllamaSetupStatus.error,
        message: 'Failed to start Ollama daemon: $e',
        error: e.toString(),
      ));
      return;
    }

    emit(state.copyWith(
      status: OllamaSetupStatus.ready,
      message: 'Ollama daemon is up and ready.',
    ));
  }
}
