import 'package:fly/fly.dart';
import 'package:fly_bloc/fly_bloc.dart';
import 'package:makerlog/app/bloc/app_state.dart';
import 'package:makerlog/chat/view/chat_page.dart';
import 'package:makerlog/onboarding/view/onboarding_page.dart';

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
