import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> get hasPermission => _recorder.hasPermission();

  Future<void> start() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_query.wav';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
  }

  /// Stop recording and return base64-encoded WAV bytes, or null on failure.
  Future<String?> stop() async {
    final path = await _recorder.stop();
    if (path == null) return null;
    final bytes = await File(path).readAsBytes();
    return base64Encode(bytes);
  }

  Future<bool> get isRecording => _recorder.isRecording();

  Future<void> dispose() => _recorder.dispose();
}
