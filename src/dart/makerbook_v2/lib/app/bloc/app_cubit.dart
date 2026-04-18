import 'package:clitter_bloc/clitter_bloc.dart';
import 'package:makerbook_v2/app/bloc/app_state.dart';

class AppCubit extends Cubit<AppState> {
  AppCubit()
      : super(
          AppState(
            userJourneyStage: UserJourneyStage.onboarding,
          ),
        );
}
