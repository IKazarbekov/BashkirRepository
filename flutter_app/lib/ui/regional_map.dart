import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_client.dart';

// A tap-only, offline vector map. No map gesture recognizers, tile downloads or
// camera controllers: scrolling the leaderboard can never move the map.
class RegionalMapPanel extends StatefulWidget {
  const RegionalMapPanel({super.key, required this.api, this.metric = 'tasks', this.onRegionSelected});
  final ApiClient api;
  final String metric;
  final ValueChanged<String>? onRegionSelected;
  @override State<RegionalMapPanel> createState() => _RegionalMapPanelState();
}

class _RegionShape {
  const _RegionShape(this.region, this.points);
  final String region;
  final List<LatLng> points;
}

class _ViewRect {
  const _ViewRect(this.minX, this.minY, this.maxX, this.maxY);
  final double minX, minY, maxX, maxY;
  static const all = _ViewRect(18, 40, 191, 83);
  static _ViewRect lerp(_ViewRect a, _ViewRect b, double t) => _ViewRect(
    a.minX + (b.minX - a.minX) * t, a.minY + (b.minY - a.minY) * t,
    a.maxX + (b.maxX - a.maxX) * t, a.maxY + (b.maxY - a.maxY) * t);
}

double _longitude(double x) => x < 0 ? x + 360 : x;

class _VectorMapPainter extends CustomPainter {
  const _VectorMapPainter({required this.shapes, required this.values,
    required this.selected, required this.view, required this.background});
  final List<_RegionShape> shapes;
  final Map<String, double> values;
  final String selected;
  final _ViewRect view;
  final Color background;

  Offset coordinate(LatLng point, Size size) {
    final padding = 14.0;
    final usableW = math.max(1.0, size.width - 2 * padding);
    final usableH = math.max(1.0, size.height - 2 * padding);
    final spanX = math.max(view.maxX - view.minX, .2);
    final spanY = math.max(view.maxY - view.minY, .2);
    // Keep geographic aspect stable and reserve room for wide regions.
    final unit = math.min(usableW / spanX, usableH / (spanY * 1.8));
    final x0 = (size.width - spanX * unit) / 2;
    final y0 = (size.height - spanY * unit * 1.8) / 2;
    return Offset(x0 + (_longitude(point.longitude) - view.minX) * unit,
      y0 + (view.maxY - point.latitude) * unit * 1.8);
  }

  ui.Path _path(List<LatLng> points, Size size) {
    final path = ui.Path();
    if (points.isEmpty) return path;
    final start = coordinate(points.first, size);
    path.moveTo(start.dx, start.dy);
    Offset previous = start;
    for (var i = 1; i < points.length; i++) {
      final next = coordinate(points[i], size);
      if ((next - previous).distanceSquared < 1.2 && i != points.length - 1) continue;
      path.lineTo(next.dx, next.dy);
      previous = next;
    }
    path.close();
    return path;
  }

  String? findRegion(Offset tap, Size size) {
    // The current frame is used for hit detection, including during zoom.
    for (final shape in shapes.reversed) {
      if (_path(shape.points, size).contains(tap)) return shape.region;
    }
    return null;
  }

  @override void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final peak = values.values.fold<double>(1, (max, value) => value > max ? value : max);
    for (final shape in shapes) {
      final path = _path(shape.points, size);
      final chosen = shape.region == selected;
      final ratio = ((values[shape.region] ?? 0) / peak).clamp(0.0, 1.0).toDouble();
      final fill = chosen ? const Color(0xFFEFC25D)
        : Color.lerp(const Color(0xFFBADCD1), const Color(0xFF278D70), ratio)!;
      canvas.drawPath(path, Paint()..color = fill);
      canvas.drawPath(path, Paint()
        ..color = chosen ? const Color(0xFF94641B) : Colors.white.withValues(alpha: .85)
        ..style = PaintingStyle.stroke..strokeWidth = chosen ? 2.5 : .65);
    }
  }

  @override bool shouldRepaint(covariant _VectorMapPainter old) =>
    old.shapes != shapes || old.values != values || old.selected != selected ||
    old.view != view || old.background != background;
}

class _RegionalMapPanelState extends State<RegionalMapPanel> with SingleTickerProviderStateMixin {
  late final AnimationController animation;
  _ViewRect source = _ViewRect.all;
  _ViewRect target = _ViewRect.all;
  final search = TextEditingController();
  List<Map<String, dynamic>> stats = [];
  List<_RegionShape> shapes = [];
  String selected = '';
  String? statsError;
  String? geometryError;
  bool statsLoading = true;
  bool geometryLoading = true;
  int statsRequest = 0;

  @override void initState() {
    super.initState();
    animation = AnimationController(vsync: this, duration: const Duration(milliseconds: 460), value: 1);
    loadStats(); loadGeometry();
  }

  @override void didUpdateWidget(covariant RegionalMapPanel old) {
    super.didUpdateWidget(old);
    if (old.metric != widget.metric) loadStats();
  }

  @override void dispose() {
    statsRequest++;
    animation.dispose(); search.dispose(); super.dispose();
  }

  Future<void> loadStats() async {
    final request = ++statsRequest;
    if (mounted) setState(() { statsLoading = true; statsError = null; });
    try {
      final data = await widget.api.request('GET', '/extras/analytics/regions?metric=${widget.metric}');
      if (!mounted || request != statsRequest) return;
      setState(() { stats = ((data['items'] as List<dynamic>?) ?? []).whereType<Map<String, dynamic>>().toList(); statsLoading = false; });
    } catch (error) {
      if (mounted && request == statsRequest) setState(() { statsError = '$error'; statsLoading = false; });
    }
  }

  Future<void> loadGeometry() async {
    try {
      final response = await widget.api.request('GET', '/extras/geo/regions', timeout: const Duration(seconds: 30));
      final list = <_RegionShape>[];
      for (final entry in (response['features'] as List<dynamic>? ?? [])) {
        if (entry is! Map) continue;
        final name = (entry['region'] ?? '').toString();
        if (name.isEmpty) continue;
        for (final polygon in (entry['polygons'] as List<dynamic>? ?? [])) {
          if (polygon is! List) continue;
          final points = <LatLng>[];
          for (final pair in polygon) {
            if (pair is List && pair.length >= 2 && pair[0] is num && pair[1] is num) {
              points.add(LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble()));
            }
          }
          if (points.length > 2) list.add(_RegionShape(name, points));
        }
      }
      if (!mounted) return;
      setState(() { shapes = list; geometryLoading = false;
        if (list.isEmpty) geometryError = 'Границы не загружены — выбирай регион из списка.'; });
    } catch (error) {
      if (mounted) setState(() { geometryLoading = false; geometryError = 'Границы регионов недоступны. Список работает отдельно.'; });
    }
  }

  _ViewRect _regionBounds(String region) {
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    for (final shape in shapes.where((s) => s.region == region)) {
      for (final p in shape.points) {
        final x = _longitude(p.longitude);
        if (x < minX) minX = x; if (x > maxX) maxX = x;
        if (p.latitude < minY) minY = p.latitude; if (p.latitude > maxY) maxY = p.latitude;
      }
    }
    if (!minX.isFinite) return _ViewRect.all;
    final dx = math.max(3.8, (maxX - minX) * .19);
    final dy = math.max(2.0, (maxY - minY) * .2);
    return _ViewRect(minX - dx, minY - dy, maxX + dx, maxY + dy);
  }

  void choose(String region) {
    if (!mounted || (selected == region && region.isNotEmpty)) return;
    final current = _ViewRect.lerp(source, target, Curves.easeInOutCubic.transform(animation.value));
    source = current;
    target = region.isEmpty ? _ViewRect.all : _regionBounds(region);
    setState(() => selected = region);
    animation.forward(from: 0);
    if (region.isNotEmpty) widget.onRegionSelected?.call(region);
  }

  Map<String, dynamic> get selectedStats {
    for (final item in stats) { if (item['region'] == selected) return item; }
    return {};
  }

  Widget _stat(String label, Object value) => Column(crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min, children: [
      Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
    ]);

  Widget _selectedPanel() {
    if (selected.isEmpty) return const Text('Нажми на область или выбери регион в списке. Карта сама приблизит выбранный регион.');
    final item = selectedStats;
    final leaders = (item['leaders'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().toList();
    return Card(key: ValueKey(selected), child: Padding(padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.place_outlined), const SizedBox(width: 8),
          Expanded(child: Text(selected, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
          TextButton(onPressed: () => choose(''), child: const Text('Вся Россия'))]),
        const SizedBox(height: 12),
        Wrap(spacing: 20, runSpacing: 10, children: [
          _stat('Учеников', item['users'] ?? 0),
          _stat('Активность', '${item['activity_percent'] ?? 0}%'),
          _stat('Результат', item['value'] ?? 0),
        ]),
        const SizedBox(height: 12),
        const Text('Лидеры региона', style: TextStyle(fontWeight: FontWeight.w800)),
        if (leaders.isEmpty) const Text('Пока нет опубликованных результатов.')
        else for (var i = 0; i < leaders.length && i < 5; i++)
          ListTile(dense: true, contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(radius: 13, child: Text('${i + 1}')),
            title: Text('@${leaders[i]['username']}'), trailing: Text('${leaders[i]['value']}')),
      ])));
  }

  @override Widget build(BuildContext context) {
    final matches = stats.where((v) => '${v['region'] ?? ''}'.toLowerCase()
      .contains(search.text.trim().toLowerCase())).toList()
      ..sort((a, b) => ((b['value'] as num?)?.toInt() ?? 0).compareTo((a['value'] as num?)?.toInt() ?? 0));
    final values = {for (final item in stats) '${item['region'] ?? ''}': (item['value'] as num?)?.toDouble() ?? 0};
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Регионы России', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      const Text('Без перемещения карты: одно нажатие — выбор и приближение. «Вся Россия» возвращает общий вид.'),
      const SizedBox(height: 14),
      ClipRRect(borderRadius: BorderRadius.circular(20), child: SizedBox(height: 310,
        child: geometryLoading ? const Center(child: CircularProgressIndicator())
        : shapes.isEmpty ? Center(child: Padding(padding: const EdgeInsets.all(20), child:
            Text(geometryError ?? 'Границы недоступны', textAlign: TextAlign.center)))
        : AnimatedBuilder(animation: animation, builder: (context, _) => LayoutBuilder(builder: (context, constraints) {
          final view = _ViewRect.lerp(source, target, Curves.easeInOutCubic.transform(animation.value));
          final painter = _VectorMapPainter(shapes: shapes, values: values, selected: selected,
            view: view, background: Theme.of(context).colorScheme.surfaceContainerLow);
          return GestureDetector(behavior: HitTestBehavior.opaque, onTapDown: (details) {
            final chosen = painter.findRegion(details.localPosition, constraints.biggest);
            if (chosen != null) choose(chosen);
          }, child: CustomPaint(size: constraints.biggest, painter: painter));
        })),
      )),
      const SizedBox(height: 11),
      AnimatedSwitcher(duration: const Duration(milliseconds: 260), child: _selectedPanel()),
      const SizedBox(height: 15),
      TextField(controller: search, onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(prefixIcon: Icon(Icons.search),
          hintText: 'Найти регион', border: OutlineInputBorder())),
      if (statsLoading) const LinearProgressIndicator(),
      if (statsError != null) Text('Статистика недоступна: $statsError'),
      const SizedBox(height: 8),
      for (final item in matches) ListTile(
        dense: true, title: Text('${item['region']}'),
        subtitle: Text('${item['users'] ?? 0} учеников · ${item['activity_percent'] ?? 0}% активных'),
        trailing: Text('${item['value'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w800)),
        selected: selected == item['region'],
        onTap: () => choose('${item['region']}')),
    ]);
  }
}
