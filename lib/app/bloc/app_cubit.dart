import 'package:fly_bloc/fly_bloc.dart';
import 'package:makerlog/app/bloc/app_state.dart';

class AppCubit extends Cubit<AppState> {
  AppCubit()
      : super(
          AppState(
            userJourneyStage: UserJourneyStage.onboarding,
          ),
        );

  void startMainApp() {
    emit(AppState(userJourneyStage: UserJourneyStage.mainApp));
  }
}
