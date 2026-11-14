import 'dart:async';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'api_client.dart';

/// Records mono PCM to WAV, then submits to the optional Bashkir ASR endpoint.
class PronunciationRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _stream;
  final BytesBuilder _builder = BytesBuilder(copy: false);
  bool recording = false;

  Future<void> start() async {
    if (!await _recorder.hasPermission()) {
      throw const ApiError('Разреши доступ к микрофону в настройках браузера');
    }
    _builder.clear();
    final stream = await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      numChannels: 1,
      sampleRate: 16000,
    ));
    recording = true;
    _stream = stream.listen((bytes) => _builder.add(bytes));
  }

  Future<Uint8List> stop() async {
    if (!recording) throw const ApiError('Микрофон не включён');
    await _recorder.stop();
    await _stream?.cancel();
    recording = false;
    final pcm = _builder.takeBytes();
    if (pcm.isEmpty) throw const ApiError('Пустая запись. Попробуй ещё раз');
    final out = ByteData(44 + pcm.length);
    void word(int offset, int value) => out.setUint16(offset, value, Endian.little);
    void dword(int offset, int value) => out.setUint32(offset, value, Endian.little);
    void ascii(int offset, String word) {
      for (var i = 0; i < word.length; i++) { out.setUint8(offset + i, word.codeUnitAt(i)); }
    }
    ascii(0, 'RIFF'); dword(4, 36 + pcm.length); ascii(8, 'WAVE');
    ascii(12, 'fmt '); dword(16, 16); word(20, 1); word(22, 1);
    dword(24, 16000); dword(28, 32000); word(32, 2); word(34, 16);
    ascii(36, 'data'); dword(40, pcm.length);
    final bytes = out.buffer.asUint8List();
    bytes.setRange(44, bytes.length, pcm);
    return bytes;
  }

  Future<void> dispose() async {
    if (recording) await _recorder.stop();
    await _stream?.cancel();
    await _recorder.dispose();
  }
}
