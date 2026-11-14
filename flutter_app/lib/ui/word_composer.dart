import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A controlled word bank. The parent owns the selected indices, while this
/// widget handles drag gestures and stable animations without global overlays.
class WordComposer extends StatelessWidget {
  const WordComposer({super.key, required this.words, required this.selected,
    required this.onAdd, required this.onRemove, this.enabled = true});

  final List<String> words;
  final List<int> selected;
  final ValueChanged<int> onAdd;
  final ValueChanged<int> onRemove;
  final bool enabled;

  static const _green = Color(0xFF238768);

  Widget _chip(BuildContext context, int index, bool inAnswer) {
    final text = words[index];
    final bg = inAnswer ? const Color(0xFFDCF1E5) : Theme.of(context).colorScheme.surface;
    return Material(
      color: bg, elevation: inAnswer ? 1.5 : .3,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: enabled ? () { inAnswer ? onRemove(index) : onAdd(index); } : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(13),
            border: Border.all(color: inAnswer ? _green : Theme.of(context).dividerColor,
              width: inAnswer ? 1.4 : 1)),
          child: Text(text, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface)),
        ),
      ),
    );
  }

  Widget _draggable(BuildContext context, int index, bool chosen) {
    final feedback = Material(color: Colors.transparent, child: Transform.scale(
      scale: 1.07, child: _chip(context, index, chosen)));
    final child = _chip(context, index, chosen);
    final moving = Opacity(opacity: .3, child: child);
    final isDesktopPointer = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
    final drag = !enabled ? child : isDesktopPointer
      ? Draggable<int>(data: index, maxSimultaneousDrags: 1,
          feedback: feedback, childWhenDragging: moving, child: child)
      : LongPressDraggable<int>(data: index,
          delay: const Duration(milliseconds: 180), maxSimultaneousDrags: 1,
          feedback: feedback, childWhenDragging: moving, child: child);
    return Semantics(
      label: '$index: ${words[index]}. ${chosen ? 'Убрать из ответа' : 'Добавить в ответ'}',
      button: true,
      child: TweenAnimationBuilder<double>(
        key: ValueKey('${chosen ? 'answer' : 'bank'}-$index'),
        tween: Tween(begin: 0, end: 1), duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        builder: (_, progress, child) => Opacity(opacity: progress,
          child: Transform.translate(offset: Offset(0, (chosen ? 20 : -14) * (1 - progress)),
            child: Transform.scale(scale: .88 + .12 * progress, child: child))),
        child: drag,
      ),
    );
  }

  Widget _zone(BuildContext context, bool answer) => DragTarget<int>(
    onWillAcceptWithDetails: (data) => enabled && data.data >= 0 &&
      data.data < words.length && (answer != selected.contains(data.data)),
    onAcceptWithDetails: (data) {
      if (!enabled || data.data < 0 || data.data >= words.length) return;
      if (answer && !selected.contains(data.data)) onAdd(data.data);
      if (!answer && selected.contains(data.data)) onRemove(data.data);
    },
    builder: (context, candidates, _) => AnimatedContainer(
      duration: const Duration(milliseconds: 210),
      width: double.infinity,
      constraints: BoxConstraints(minHeight: answer ? 96 : 72),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
        border: Border.all(color: candidates.isNotEmpty ? _green : Theme.of(context).dividerColor,
          width: candidates.isNotEmpty ? 2 : 1),
        color: candidates.isNotEmpty ? const Color(0xFFDCF4E6) : Theme.of(context).colorScheme.surface),
      child: AnimatedSize(duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic,
        alignment: Alignment.topLeft,
        child: Wrap(spacing: 8, runSpacing: 10, children: [
          if (answer && selected.isEmpty)
            const Padding(padding: EdgeInsets.all(10),
              child: Text('Собери предложение здесь…')),
          for (final index in answer ? selected : List<int>.generate(words.length, (i) => i))
            if (index >= 0 && index < words.length && (answer || !selected.contains(index)))
              _draggable(context, index, answer),
        ]),
      ),
    ),
  );

  @override Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _zone(context, true),
      const SizedBox(height: 14),
      _zone(context, false),
      const SizedBox(height: 7),
      Text('Нажми на слово или перетащи его в строку ответа. Для удаления нажми снова.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ],
  );
}
