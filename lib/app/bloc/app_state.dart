import 'package:equatable/equatable.dart';

class AppState extends Equatable {
  AppState({
    required this.userJourneyStage,
  });

  final UserJourneyStage userJourneyStage;

  @override
  List<Object?> get props => [userJourneyStage];
}

enum UserJourneyStage {
  /// Onboarding comprises the first time user enters the app, sees the welcome message, and sends their first message. It's a good opportunity to introduce the app's value prop and maybe some tips.
  onboarding,

  /// The worklog stage, where the user inputs what they are working on.
  worklog,

  /// The main app experience, where the user is sending messages and getting responses. This is the core of the app and should be designed to be as smooth and engaging as possible.
  mainApp,
}
