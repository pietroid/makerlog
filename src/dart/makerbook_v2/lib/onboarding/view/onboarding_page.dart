import 'package:clitter/clitter.dart';
import 'package:makerbook_v2/app/bloc/app_cubit.dart';

class OnboardingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      onKeyEvent: (event) {
        context.read<AppCubit>().startMainApp();
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
                style: TextStyle(
                  color: Color.rgb(120, 230, 160),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
