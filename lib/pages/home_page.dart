import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart'; // For animation
import '../bloc/barge_in_bloc.dart';
import '../bloc/barge_in_event.dart';
import '../bloc/barge_in_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF091133), // Page background
      body: BlocBuilder<BargeInBloc, BargeInState>(
        builder: (context, state) {
          final isEnabled = state is Idle || state is Interrupted;

          String topText;
          if (state is Speaking) {
            topText = "Speaking...";
          } else if (state is Interrupted) {
            topText = "New voice detected! Tap anywhere to continue";
          } else {
            topText = "Press anywhere to Speak";
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isEnabled
                ? () {
              context.read<BargeInBloc>().add(SpeakPressed());
            }
                : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(50.0),
                    child: Text(
                      topText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                if (state is Speaking)
                // Full-width Lottie animation from local file
                  Container(
                    color: const Color(0xFF091133), // animation background color
                    width: double.infinity,
                    height: 200,
                    child: Lottie.asset(
                      'assets/animations/audio_wave.json',
                      fit: BoxFit.cover,
                      repeat: true,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
