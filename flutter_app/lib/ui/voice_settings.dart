import 'package:flutter/material.dart';

import '../data/progress_store.dart';
import '../data/extras_controller.dart';
import 'community_pages.dart';
import '../services/api_client.dart';
import '../services/speech_player.dart';
import 'main.dart';

class VoiceSettings extends StatefulWidget {
  const VoiceSettings({super.key, required this.progress, required this.api, required this.speech, required this.extras});
  final ProgressStore progress;
  final ApiClient api;
  final SpeechPlayer speech;
  final ExtrasController extras;

  @override
  State<VoiceSettings> createState() => _VoiceSettingsState();
}

class _VoiceSettingsState extends State<VoiceSettings> {
  late final Future<Map<String, dynamic>> catalog;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    catalog = widget.api.request('GET', '/tts/voices', authorized: false);
  }

  Future<void> save(String language, String speaker) async {
    if (!widget.extras.hasVoice(language, speaker)) {
      final buy = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Голос пока закрыт'),
        content: const Text('Этот голос или язык можно открыть за монеты в магазине.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Позже')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('В магазин'))]));
      if (buy == true && mounted) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => ShopPage(extras: widget.extras, progress: widget.progress)));
      }
      return;
    }
    setState(() => saving = true);
    try {
      await widget.progress.changeVoice(language, speaker);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> preview(String language, String speaker, String sample) async {
    try {
      await widget.speech.speak(sample, language: language, speaker: speaker);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: catalog,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          if (snapshot.hasError) return Text('Голоса недоступны: ${snapshot.error}', style:  TextStyle(color: AppColors.muted));
          return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
        }
        final data = snapshot.data!;
        final languages = data['languages'] as Map<String, dynamic>;
        final selectedLanguage = languages.containsKey(widget.progress.voiceLanguage) ? widget.progress.voiceLanguage : 'bak';
        final selected = languages[selectedLanguage] as Map<String, dynamic>;
        final voices = selected['voices'] as List<dynamic>;
        final currentVoice = voices.any((v) => v['id'] == widget.progress.voiceId)
            ? widget.progress.voiceId : voices.first['id'] as String;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DropdownButtonFormField<String>(
            key: ValueKey('language_$selectedLanguage'),
            value: selectedLanguage,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Язык озвучки', border: OutlineInputBorder()),
            items: [for (final code in languages.keys)
              DropdownMenuItem(value: code, child: Text('${widget.extras.hasVoice(code) ? '' : '🔒 '}${(languages[code] as Map<String, dynamic>)['label']}'))],
            onChanged: saving ? null : (code) {
              if (code == null) return;
              final voice = ((languages[code] as Map<String, dynamic>)['voices'] as List<dynamic>).first['id'] as String;
              save(code, voice);
            },
          ),
          const SizedBox(height: 11),
          DropdownButtonFormField<String>(
            key: ValueKey('voice_$selectedLanguage'),
            value: currentVoice,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Голос', border: OutlineInputBorder()),
            items: [for (final voice in voices)
              DropdownMenuItem(value: voice['id'] as String, child: Text('${widget.extras.hasVoice(selectedLanguage, voice['id'] as String) ? '' : '🔒 '}${voice['label']}'))],
            onChanged: saving ? null : (value) { if (value != null) save(selectedLanguage, value); },
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: saving || widget.speech.loading ? null : () => widget.extras.hasVoice(selectedLanguage, currentVoice)
              ? preview(selectedLanguage, currentVoice, selected['sample'] as String)
              : save(selectedLanguage, currentVoice),
            icon: widget.speech.loading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.volume_up_rounded),
            label: const Text('Послушать голос'),
          ),
          const SizedBox(height: 7),
          Text(data['installed'] == true
            ? 'В упражнениях и словаре используется выбранный голос.'
            : 'На сервере ещё не установлен Silero TTS. Язык и голос можно выбрать, но для воспроизведения установи requirements-tts.txt.',
            style:  TextStyle(fontSize: 12, color: AppColors.muted)),
          if (selectedLanguage != 'bak') ...[
            const SizedBox(height: 7),
             Text('Уроки остаются башкирскими: для их произношения лучше выбрать башкирский голос.',
              style: TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ]);
      },
    );
  }
}
