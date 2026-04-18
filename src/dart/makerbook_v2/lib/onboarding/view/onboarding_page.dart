import 'package:clitter/clitter.dart';

class OnboardingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.rgb(0, 150, 100),
      child: Center(
        child: Text(
          'Welcome to makerbook! This is the onboarding page.',
          style: TextStyle(
            color: Color.white,
          ),
        ),
      ),
    );
  }
}
