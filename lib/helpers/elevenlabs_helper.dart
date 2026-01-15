import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

typedef StreamCallback = void Function(Uint8List chunk, {bool finalChunk});

class ElevenLabsHelper {
  final String apiKey;
  final String voiceId;

  ElevenLabsHelper({
    required this.apiKey,
    required this.voiceId,
  });

  Future<void> streamTts(String text, StreamCallback onChunk) async {
    final url =
        'https://api.elevenlabs.io/v1/text-to-speech/$voiceId/stream';

    final body = jsonEncode({
      "text": text,
      "model_id": "eleven_multilingual_v2",
      "voice_settings": {
        "stability": 0.5,
        "similarity_boost": 0.75,
      },
    });

    final request = http.Request('POST', Uri.parse(url))
      ..headers.addAll({
        'xi-api-key': apiKey,
        'Content-Type': 'application/json',
        'Accept': 'audio/mpeg', // ✅ MP3
      })
      ..body = body;

    try {
      final response = await request.send();

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        throw Exception(
          'ElevenLabs Error (${response.statusCode}): $errorBody',
        );
      }

      print('TTS stream started');

      final buffer = <int>[];
      const int chunkThreshold = 2048; // MP3-safe buffer size

      await for (final chunk in response.stream) {
        if (chunk.isEmpty) continue;

        buffer.addAll(chunk);

        // Send buffered MP3 bytes
        if (buffer.length >= chunkThreshold) {
          onChunk(Uint8List.fromList(buffer), finalChunk: false);
          buffer.clear();
        }
      }

      // Send remaining MP3 bytes
      if (buffer.isNotEmpty) {
        onChunk(Uint8List.fromList(buffer), finalChunk: false);
      }

      // Signal completion
      onChunk(Uint8List(0), finalChunk: true);
      print('TTS stream finished');

    } catch (e) {
      print('Error during TTS stream: $e');
      onChunk(Uint8List(0), finalChunk: true);
    }
  }
}
