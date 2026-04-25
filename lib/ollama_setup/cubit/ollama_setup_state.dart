/// Lifecycle for bringing the ollama daemon online.
///
/// `checkingInstallation` → (`installing`) → `checkingServer` →
/// (`startingServer`) → `ready`. `error` / `unsupportedPlatform` are
/// terminal for this flow.
enum OllamaSetupStatus {
  idle,
  checkingInstallation,
  notInstalled,
  installing,
  checkingServer,
  startingServer,
  ready,
  unsupportedPlatform,
  error,
}

class OllamaSetupState {
  final OllamaSetupStatus status;
  final String message;
  final String? error;

  const OllamaSetupState({
    this.status = OllamaSetupStatus.idle,
    this.message = '',
    this.error,
  });

  bool get isReady => status == OllamaSetupStatus.ready;
  bool get isTerminalFailure =>
      status == OllamaSetupStatus.error ||
      status == OllamaSetupStatus.unsupportedPlatform;

  OllamaSetupState copyWith({
    OllamaSetupStatus? status,
    String? message,
    String? error,
    bool clearError = false,
  }) {
    return OllamaSetupState(
      status: status ?? this.status,
      message: message ?? this.message,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
