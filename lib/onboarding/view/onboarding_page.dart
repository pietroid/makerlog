import 'package:fly/fly.dart';
import 'package:makerlog/app/bloc/app_cubit.dart';

class OnboardingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      onKeyEvent: (event) {
        context.read<AppCubit>().startWorklog();
      },
      child: Container(
        color: Color.black,
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AsciiImage(
                'assets/makerlog.txt',
                color: Color.rgb(120, 230, 160),
              ),
              Text(
                'Welcome to Makerlog! Press any key to start our journey...',
                style: TextStyle(color: Color.rgb(120, 230, 160)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
