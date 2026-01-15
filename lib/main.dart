import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'helpers/barge_in_platform.dart';
import 'helpers/elevenlabs_helper.dart';
import 'bloc/barge_in_bloc.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final platform = BargeInPlatform();
    final elevenLabs = ElevenLabsHelper(
      apiKey: 'sk_b97f8cbe72af10f39cc8bd932395587fa6d3f3c2d1fd19f5',
      voiceId: '21m00Tcm4TlvDq8ikWAM',
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BlocProvider(
        create: (_) => BargeInBloc(platform, elevenLabs),
        child: const HomePage(),
      ),
    );
  }
}
