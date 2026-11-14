import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../services/api_client.dart';

class MascotFigure extends StatefulWidget {
  const MascotFigure({super.key, required this.api, this.action = 'idle', this.size = 105});
  final ApiClient api;
  final String action;
  final double size;
  @override
  State<MascotFigure> createState() => _MascotFigureState();
}

class _MascotFigureState extends State<MascotFigure> with SingleTickerProviderStateMixin {
  late final AnimationController _bob;
  late final Future<Map<String, dynamic>> config;
  Offset offset = Offset.zero;
  int taps = 0;
  String activeAnimation = 'idle';

  @override
  void initState() {
    super.initState();
    config = widget.api.request('GET', '/extras/mascot');
    activeAnimation = widget.action;
    _bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 1650))..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant MascotFigure oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.action != widget.action) setState(() => activeAnimation = widget.action);
  }

  @override
  void dispose() { _bob.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _bob, builder: (context, child) => AnimatedContainer(
      duration: const Duration(milliseconds: 380), curve: Curves.easeOutBack,
      transform: Matrix4.translationValues(offset.dx, offset.dy - 5 * _bob.value, 0),
      child: child,
    ), child: GestureDetector(
      onTap: () {
        setState(() { taps++; activeAnimation = 'tap'; });
        Future<void>.delayed(const Duration(milliseconds: 950), () {
          if (mounted && activeAnimation == 'tap') setState(() => activeAnimation = 'idle');
        });
      },
      onPanUpdate: (details) => setState(() { offset += details.delta; activeAnimation = 'float'; }),
      onPanEnd: (_) => setState(() { offset = Offset.zero; activeAnimation = 'idle'; }),
      onPanCancel: () => setState(() { offset = Offset.zero; activeAnimation = 'idle'; }),
      child: FutureBuilder<Map<String, dynamic>>(future: config, builder: (context, snapshot) {
        final data = snapshot.data ?? <String, dynamic>{};
        final actionAssets = data['action_assets'] as Map<String, dynamic>? ?? {};
        final actionData = actionAssets[activeAnimation] as Map<String, dynamic>?;
        final path = actionData?['url'] as String? ?? data['url'] as String?;
        final kind = actionData?['kind'] as String? ?? data['kind'] as String? ?? 'robot';
        final names = data['animations'] as Map<String, dynamic>? ?? {};
        final source = path == null ? '' : '${widget.api.baseUrl}$path';
        final animation = names[activeAnimation] as String? ?? '';
        final size = widget.size;
        if (kind == '3d' && path != null) {
          return SizedBox(width: size, height: size, child: ModelViewer(
            key: ValueKey('$source:$animation'), src: source,
            alt: 'Маскот школы', autoPlay: true, autoRotate: false, cameraControls: false,
            backgroundColor: Colors.transparent,
            animationName: animation.isEmpty ? null : animation));
        }
        if (kind == 'image' && path != null) {
          return AnimatedRotation(turns: taps.isOdd ? .06 : -.03,
            duration: const Duration(milliseconds: 300),
            child: Image.network(source, width: size, height: size, fit: BoxFit.contain));
        }
        return Container(width: size, height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: const Color(0xFFE4F3E9), borderRadius: BorderRadius.circular(24)),
          child: Text(taps.isOdd ? '🤖✨' : '🤖', style: TextStyle(fontSize: size * .47)));
      }),
    ));
  }
}
