/// Machine prompt is the system message that asks something for the user.
class MachinePrompt {
  /// A unique key to identify the prompt. This is used to track which prompts have been shown to the user and which ones are still pending.
  final String key;

  /// The prompt to show to the user.
  final String prompt;

  /// The options to show to the user.
  final List<String> options;

  /// An optional hint to show to the user when the prompt accepts freeform input.
  final String? freeFormHint;

  MachinePrompt({
    required this.key,
    required this.prompt,
    required this.options,
    this.freeFormHint,
  });
}
