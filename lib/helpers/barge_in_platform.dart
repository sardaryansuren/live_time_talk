import 'dart:typed_data';
import 'package:flutter/services.dart';

typedef BargeInCallback = void Function();
typedef PlaybackFinishedCallback = void Function();

class BargeInPlatform {
  static const MethodChannel _channel = MethodChannel('barge_in');

  MethodChannel get channel => _channel;

  /// Start engine (starts mic listening)
  Future<void> start() async {
    await _channel.invokeMethod('start'); // no empty buffer
  }

  /// Stop engine
  Future<void> stop() async {
    await _channel.invokeMethod('stop');
  }

  /// Play audio chunk
  Future<void> playChunk(Uint8List chunk, {bool finalChunk = false}) async {
    await _channel.invokeMethod('play_chunk', {
      'chunk': chunk,
      'final': finalChunk, // must match Kotlin
    });
  }

  /// Set a single handler for both barge-in and playback finished
  void setMethodCallHandler({
    required BargeInCallback onBargeIn,
    required PlaybackFinishedCallback onPlaybackFinished,
  }) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'barge_in_detected') {
        onBargeIn();
      } else if (call.method == 'playback_finished') {
        onPlaybackFinished();
      }
    });
  }
}
