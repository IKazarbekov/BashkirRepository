import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../data/progress_store.dart';
import 'api_client.dart';

class SpeechPlayer extends ChangeNotifier {
  SpeechPlayer(this.api, this.progress);
  final ApiClient api;
  final ProgressStore progress;
  final AudioPlayer _player = AudioPlayer();
  bool loading = false;

  Future<void> speak(String text, {String? language, String? speaker}) async {
    if (loading) return;
    loading = true;
    notifyListeners();
    try {
      final bytes = await api.speech(
        text,
        language ?? progress.voiceLanguage,
        speaker ?? progress.voiceId,
      );
      await _player.stop();
      await _player.play(BytesSource(bytes, mimeType: 'audio/wav'));
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
