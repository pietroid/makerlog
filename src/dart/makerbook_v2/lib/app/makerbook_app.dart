import 'package:clitter/clitter.dart';
import 'package:clitter_bloc/clitter_bloc.dart';
import 'package:makerbook_v2/app/bloc/app_state.dart';
import 'package:makerbook_v2/chat/view/chat_page.dart';
import 'package:makerbook_v2/onboarding/view/onboarding_page.dart';

import 'bloc/app_cubit.dart';

/// The root of the app. Sets up global providers and holds the main layout.
class MakerbookApp extends StatelessWidget {
  MakerbookApp();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        BlocProvider(create: (_) => AppCubit()),
      ],
      child: _MakerbookAppView(),
    );
  }
}

class _MakerbookAppView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(builder: (context, state) {
      switch (state.userJourneyStage) {
        case UserJourneyStage.onboarding:
          return OnboardingPage();
        case UserJourneyStage.mainApp:
          return ChatPage();
      }
    });
  }
}
