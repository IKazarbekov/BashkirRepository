import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Decorative shapes for the Bashkir spring theme: kurai, tulips, a mosque
/// silhouette and a horseman silhouette inspired by public monuments.
/// Original ornamental panorama created for this app; no embedded text.
/// The illustration is supplied as an asset and scales on all device widths.
class BashkirLandscape extends StatelessWidget {
  const BashkirLandscape({super.key, this.height = 172});
  final double height;

  @override Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: SizedBox(height: height, width: double.infinity,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF4D7), Color(0xFFF6E5BD), Color(0xFFE4C998)])),
        child: Image.asset('assets/bashkir_spring.png',
          alignment: Alignment.bottomCenter, fit: BoxFit.cover,
          filterQuality: FilterQuality.medium),
      ),
    ),
  );
}

class NorthernGlow extends StatefulWidget {
  const NorthernGlow({super.key});
  @override State<NorthernGlow> createState() => _NorthernGlowState();
}
class _NorthernGlowState extends State<NorthernGlow> with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  @override void initState() { super.initState(); controller = AnimationController(vsync: this,
    duration: const Duration(seconds: 7))..repeat(reverse: true); }
  @override void dispose() { controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => SizedBox(height: 85, child: AnimatedBuilder(animation: controller,
    builder: (context, _) => CustomPaint(painter: _NorthernGlowPainter(controller.value))));
}
class _NorthernGlowPainter extends CustomPainter {
  _NorthernGlowPainter(this.t);
  final double t;
  @override void paint(Canvas canvas, Size s) {
    final p=Paint()..shader=LinearGradient(colors: [const Color(0xFF36978D).withValues(alpha:.05),
      const Color(0xFF5FDBB3).withValues(alpha:.3), const Color(0xFF8165B4).withValues(alpha:.05)])
      .createShader(Offset.zero & s);
    final path=Path()..moveTo(0, s.height*.8);
    for(var x=0.0; x<=s.width; x+=5){
      final y=s.height*(.32+.20*math.sin(x/85+t*math.pi*2));
      path.lineTo(x,y);
    }
    path
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    canvas.drawPath(path,p);
  }
  @override bool shouldRepaint(covariant _NorthernGlowPainter old) => old.t != t;
}

/// Lightweight optional theme art. All canvases are responsive and text-free.
class PinkGarden extends StatefulWidget {
  const PinkGarden({super.key});
  @override State<PinkGarden> createState() => _PinkGardenState();
}

class _PinkGardenState extends State<PinkGarden> with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  @override void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
  }
  @override void dispose() { controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(21),
    child: SizedBox(height: 112, child: AnimatedBuilder(animation: controller,
      builder: (_, child) => CustomPaint(painter: _PinkGardenPainter(controller.value)))),
  );
}

class _PinkGardenPainter extends CustomPainter {
  const _PinkGardenPainter(this.t);
  final double t;
  @override void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..shader = const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFFFFEDF5), Color(0xFFF9CEE6), Color(0xFFFFF0D9)],
    ).createShader(Offset.zero & size));
    final stem = Paint()..color = const Color(0xFF55946E)..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    final bud = Paint()..color = const Color(0xFFD9699B);
    for (var i = 0; i < 11; i++) {
      final x = w * (i + .5) / 11;
      final height = 33 + (i % 4) * 11.0;
      canvas.drawLine(Offset(x, h), Offset(x + math.sin(t * 4 + i) * 2.2, h - height), stem);
      final top = Offset(x + math.sin(t * 4 + i) * 2.2, h - height);
      final path = Path()..moveTo(top.dx, top.dy + 18)
        ..quadraticBezierTo(top.dx - 17, top.dy + 1, top.dx - 12, top.dy - 9)
        ..lineTo(top.dx, top.dy - 3)..lineTo(top.dx + 12, top.dy - 9)
        ..quadraticBezierTo(top.dx + 17, top.dy + 1, top.dx, top.dy + 18);
      canvas.drawPath(path, bud);
    }
    final petals = Paint()..color = const Color(0xFFF6B2D0).withValues(alpha: .7);
    for (var i = 0; i < 14; i++) {
      final x = w * (i + .3) / 14;
      final y = (h * (.14 + ((i * 17) % 9) / 13) + math.sin(t * 4 + i) * 6);
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 8, height: 13), petals);
    }
  }
  @override bool shouldRepaint(covariant _PinkGardenPainter old) => old.t != t;
}

class CatCornerBanner extends StatelessWidget {
  const CatCornerBanner({super.key});
  @override Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(21),
    child: SizedBox(height: 112, width: double.infinity,
      child: CustomPaint(painter: _CatCornerPainter())),
  );
}

class _CatCornerPainter extends CustomPainter {
  @override void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..shader = const LinearGradient(
      colors: [Color(0xFFFFEEDB), Color(0xFFF3D9CA)],
    ).createShader(Offset.zero & size));
    final paw = Paint()..color = const Color(0xFFE0AF9B).withValues(alpha: .34);
    for (var j = 0; j < 10; j++) {
      final cx = w * (j + .4) / 10;
      final cy = (j % 3) * 32.0 + 13;
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 16, height: 12), paw);
      for (var k = 0; k < 3; k++) {
        canvas.drawCircle(Offset(cx - 7 + k * 7, cy - 10), 3.6, paw);
      }
    }
    // A sitting-cat silhouette as an original emblem.
    final dark = Paint()..color = const Color(0xFF8A5D52);
    final cat = Path()..moveTo(w * .74, h)
      ..quadraticBezierTo(w * .71, h * .48, w * .78, h * .45)
      ..lineTo(w * .80, h * .24)..lineTo(w * .84, h * .36)
      ..lineTo(w * .89, h * .22)..lineTo(w * .90, h * .43)
      ..quadraticBezierTo(w * .96, h * .66, w * .90, h)
      ..close();
    canvas.drawPath(cat, dark);
    canvas.drawCircle(Offset(w * .80, h * .47), 2.5, Paint()..color = const Color(0xFFFFDD9E));
    canvas.drawCircle(Offset(w * .88, h * .47), 2.5, Paint()..color = const Color(0xFFFFDD9E));
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class DarkNightBanner extends StatelessWidget {
  const DarkNightBanner({super.key});
  @override Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(21),
    child: SizedBox(height: 112, child: CustomPaint(painter: _DarkNightPainter())));
}

class _DarkNightPainter extends CustomPainter {
  @override void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..shader = const LinearGradient(
      colors: [Color(0xFF111C1C), Color(0xFF2A4540)],
    ).createShader(Offset.zero & size));
    for (var i = 0; i < 37; i++) {
      final x = w * ((i * 37) % 89) / 89;
      final y = h * ((i * 19) % 61) / 85;
      canvas.drawCircle(Offset(x, y), (i % 3 + 1) * .7,
        Paint()..color = const Color(0xFFFFF4C9).withValues(alpha: .7));
    }
    canvas.drawCircle(Offset(w * .83, h * .31), 21,
      Paint()..color = const Color(0xFFF9DEAE));
    canvas.drawCircle(Offset(w * .85, h * .23), 20,
      Paint()..color = const Color(0xFF1D3130));
    canvas.drawPath(Path()..moveTo(0, h)..lineTo(w * .25, h * .62)
      ..lineTo(w * .4, h * .77)..lineTo(w * .64, h * .53)
      ..lineTo(w, h * .86)..lineTo(w, h)..close(),
      Paint()..color = const Color(0xFF152A24));
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}
