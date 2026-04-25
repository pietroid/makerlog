import 'package:fly_bloc/fly_bloc.dart';
import 'package:makerlog/app/bloc/app_state.dart';

class AppCubit extends Cubit<AppState> {
  AppCubit()
      : super(
          AppState(
            userJourneyStage: UserJourneyStage.onboarding,
          ),
        );

  void startWorklog() {
    emit(AppState(userJourneyStage: UserJourneyStage.worklog));
  }

  void startMainApp() {
    emit(AppState(userJourneyStage: UserJourneyStage.mainApp));
  }
}
