/// Lifecycle of model-level bot setup + inference. Walks
/// [checkingModel] → (optionally [installing]) → [ready], flipping to
/// [answering] / [answered] during inference calls. [error] is
/// terminal.
enum BotStatus {
  idle,
  checkingModel,
  modelMissing,
  installing,
  ready,
  error,
  answering,
  answered,
}

class BotState {
  final BotStatus status;
  final String message;
  final double? progress;
  final String? error;

  const BotState({
    this.status = BotStatus.idle,
    this.message = '',
    this.progress,
    this.error,
  });

  bool get isReady => status == BotStatus.ready;
  bool get isTerminalFailure => status == BotStatus.error;

  BotState copyWith({
    BotStatus? status,
    String? message,
    double? progress,
    bool clearProgress = false,
    String? error,
    bool clearError = false,
  }) {
    return BotState(
      status: status ?? this.status,
      message: message ?? this.message,
      progress: clearProgress ? null : (progress ?? this.progress),
      error: clearError ? null : (error ?? this.error),
    );
  }
}
