import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

class ElevenLabsStreamer {
  final String apiKey;
  final String voiceId;
  final AudioPlayer _player = AudioPlayer();

  ElevenLabsStreamer({required this.apiKey, required this.voiceId});

  Future<void> speak(String text) async {
    final url = 'https://api.elevenlabs.io/v1/text-to-speech/$voiceId/stream';

    try {
      // 1. Initialize our custom byte-stream source
      final source = MyStreamSource();

      // 2. Start the player loading the source
      final playFuture = _player.setAudioSource(source);

      // 3. Manually perform the POST request
      final request = http.Request('POST', Uri.parse(url))
        ..headers.addAll({
          'xi-api-key': apiKey,
          'Content-Type': 'application/json',
          'accept': 'audio/mpeg',
        })
        ..body = jsonEncode({
          "text": text,
          "model_id": "eleven_multilingual_v2",
          "voice_settings": {"stability": 0.5, "similarity_boost": 0.8},
        });

      final response = await http.Client().send(request);

      if (response.statusCode == 200) {
        _player.play();

        // 4. Feed chunks into the player as they arrive
        await for (final chunk in response.stream) {
          source.addBytes(chunk);
        }
        source.finish(); // Tell the source no more data is coming
      } else {
        final errorBody = await response.stream.bytesToString();
        print("ElevenLabs Error ${response.statusCode}: $errorBody");
      }

      await playFuture;
    } catch (e) {
      print("Streamer Error: $e");
    }
  }

  void stop() => _player.stop();
}

class MyStreamSource extends StreamAudioSource {
  final StreamController<List<int>> _controller = StreamController<List<int>>();
  final List<int> _buffer = [];

  void addBytes(List<int> bytes) {
    _buffer.addAll(bytes);
    _controller.add(bytes);
  }

  void finish() => _controller.close();

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    return StreamAudioResponse(
      sourceLength: null,
      contentLength: null,
      offset: start ?? 0,
      stream: _controller.stream,
      contentType: 'audio/mpeg',
    );
  }
}