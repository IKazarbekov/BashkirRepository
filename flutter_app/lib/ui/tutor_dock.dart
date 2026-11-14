import 'package:flutter/material.dart';
import '../services/api_client.dart';

/// Right-corner language tutor. Requests run only through the local API server.
class TutorDock extends StatefulWidget {
  const TutorDock({super.key, required this.api});
  final ApiClient api;
  @override
  State<TutorDock> createState() => TutorDockState();
}

class TutorDockState extends State<TutorDock> {
  final input = TextEditingController();
  final scroll = ScrollController();
  final history = <Map<String, String>>[];
  bool open = false;
  bool sending = false;
  int? lessonNumber;
  String lessonTitle = '';
  String currentProvider = 'deepseek';
  List<Map<String, dynamic>> providers = [];

  @override void initState() {
    super.initState();
    loadProviders();
  }

  Future<void> loadProviders() async {
    try {
      final data = await widget.api.request('GET', '/extras/tutor/providers');
      if (!mounted) return;
      setState(() {
        currentProvider = (data['active'] as Map<String, dynamic>? ?? {})['provider'] as String? ?? 'deepseek';
        providers = (data['providers'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().toList();
      });
    } catch (_) {}
  }


  Future<void> openForLesson(int number, String title) async {
    setState(() { open = true; lessonNumber = number; lessonTitle = title; });
    await send('Не понял тему');
  }

  Future<void> send(String value) async {
    final message = value.trim();
    if (message.isEmpty || sending) return;
    final previous = history.take(6).map((m) => <String, String>{'role': m['role']!, 'content': m['content']!}).toList();
    setState(() { history.add({'role': 'user', 'content': message}); sending = true; open = true; input.clear(); });
    try {
      final result = await widget.api.request('POST', '/extras/tutor/chat', body: {
        'message': message, 'lesson_number': lessonNumber, 'lesson_title': lessonTitle,
        'history': previous, 'provider': currentProvider,
      });
      if (mounted) setState(() => history.add({'role': 'assistant', 'content': result['answer'] as String? ?? 'Не удалось ответить'}));
    } catch (e) {
      if (mounted) setState(() => history.add({'role': 'assistant', 'content': '$e'}));
    } finally {
      if (mounted) {
        setState(() => sending = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scroll.hasClients) scroll.animateTo(scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        });
      }
    }
  }

  @override
  void dispose() {
    input.dispose(); scroll.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(color: Colors.transparent, child: Column(
      mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        if (open)
          Container(width: 320, height: 420,
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width - 36,
              maxHeight: MediaQuery.sizeOf(context).height * 0.67),
            margin: const EdgeInsets.only(bottom: 9),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Theme.of(context).dividerColor),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 26)]),
            child: Column(children: [
              ListTile(dense: true, leading: const Icon(Icons.school_outlined),
                title: const Text('Учитель башкирского', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Помогу с темами и словами'),
                trailing: IconButton(tooltip: 'Свернуть', onPressed: () => setState(() => open = false),
                  icon: const Icon(Icons.close))),
              if (providers.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<String>(
                  value: providers.any((p) => p['id'] == currentProvider) ? currentProvider : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Преподаватель', isDense: true),
                  items: [for (final provider in providers)
                    DropdownMenuItem(value: provider['id'] as String,
                      child: Text('${provider['title']}${provider['configured'] == true ? '' : ' · не настроен'}',
                        overflow: TextOverflow.ellipsis))],
                  onChanged: sending ? null : (value) { if (value != null) setState(() => currentProvider = value); },
                )),
              Expanded(child: ListView.builder(controller: scroll, padding: const EdgeInsets.all(12),
                itemCount: history.length, itemBuilder: (context, index) {
                  final item = history[index];
                  final mine = item['role'] == 'user';
                  return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(maxWidth: 275),
                      decoration: BoxDecoration(color: mine ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16)),
                      child: SelectableText(item['content'] ?? '')));
                })),
              if (sending) const LinearProgressIndicator(minHeight: 2),
              Padding(padding: const EdgeInsets.all(9), child: Row(children: [
                Expanded(child: TextField(controller: input, maxLength: 800, minLines: 1, maxLines: 3,
                  onSubmitted: (value) => send(value),
                  decoration: const InputDecoration(hintText: 'Вопрос о башкирском…', counterText: '',
                    isDense: true, border: OutlineInputBorder()))),
                IconButton(onPressed: sending ? null : () => send(input.text),
                  icon: const Icon(Icons.send_rounded)),
              ])),
            ])),
        FloatingActionButton.small(heroTag: null,
          tooltip: open ? 'Свернуть учителя' : 'Спросить учителя',
          onPressed: () => setState(() => open = !open),
          child: Icon(open ? Icons.keyboard_arrow_down_rounded : Icons.chat_bubble_outline_rounded)),
      ]));
  }
}
