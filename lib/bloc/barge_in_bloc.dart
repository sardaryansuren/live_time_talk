import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../helpers/barge_in_platform.dart';
import '../helpers/elevenlabs_helper.dart';
import 'barge_in_event.dart';
import 'barge_in_state.dart';

class BargeInBloc extends Bloc<BargeInEvent, BargeInState> {
  final BargeInPlatform platform;
  final ElevenLabsHelper elevenLabs;

  BargeInBloc(this.platform, this.elevenLabs) : super(Idle()) {
    // Set MethodChannel handler once
    platform.setMethodCallHandler(
      onBargeIn: () => add(BargeInDetected()),
      onPlaybackFinished: () => add(PlaybackFinished()),
    );

    on<SpeakPressed>(_onSpeakPressedText);
    on<BargeInDetected>(_onBargeInDetected);
    on<PlaybackFinished>((event, emit) => emit(Idle()));
  }

  Future<void> _onSpeakPressedText(
      SpeakPressed event,
      Emitter<BargeInState> emit,
      ) async {
    emit(Speaking()); // disable button while speaking

    // Start engine (mic + playback ready)
    await platform.start();

    try {
      final startText =
          "Hello! Welcome to your ElevenLabs voice demo. You can speak while this voice is playing.";

      // Stream TTS
      await elevenLabs.streamTts(startText, (chunk, {finalChunk = false}) {
        print("Flutter chunk size=${chunk.length}, final=$finalChunk");

        platform.playChunk(chunk, finalChunk: finalChunk);
      });

      // Do NOT emit Idle here — wait for Kotlin playback_finished
    } catch (e) {
      emit(Idle());
      print("Error streaming TTS: $e");
    }
  }

  void _onBargeInDetected(BargeInDetected event, Emitter emit) {
    emit(Interrupted());
  }
}

/// Internal event to handle playback finished callback
