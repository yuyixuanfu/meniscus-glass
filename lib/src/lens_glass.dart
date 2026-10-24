import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'glass_backdrop.dart';

class LensGlass extends SingleChildRenderObjectWidget {
  const LensGlass({
    super.key,
    this.radius = 20,
    this.tint = const Color(0x0DFFFFFF),
    this.live = false,
    super.child,
  });

  final double radius;
  final Color tint;
  final bool live;

  static ui.FragmentProgram? _program;

  static Future<void> load() async {
    try {
      _program = await ui.FragmentProgram.fromAsset('packages/meniscus/shaders/meniscus.frag');
    } catch (e) {
      debugPrint('meniscus: $e');
    }
  }

  @override
  RenderObject createRenderObject(BuildContext context) => RenderLens(
        radius: radius,
        tint: tint,
        live: live,
        backdrop: GlassBackdrop.maybeOf(context),
      )..scroll = Scrollable.maybeOf(context)?.position;

  @override
  void updateRenderObject(BuildContext context, RenderLens renderObject) => renderObject
    ..radius = radius
    ..tint = tint
    ..live = live
    ..backdrop = GlassBackdrop.maybeOf(context)
    ..scroll = Scrollable.maybeOf(context)?.position;
}

class RenderLens extends RenderProxyBox {
  RenderLens({required this._radius, required this._tint, this._live = false, this._backdrop});

  ui.FragmentShader? _shader;
  ui.Image? _last;

  double _radius;
  set radius(double v) {
    if (v == _radius) return;
    _radius = v;
    markNeedsPaint();
  }

  Color _tint;
  set tint(Color v) {
    if (v == _tint) return;
    _tint = v;
    markNeedsPaint();
  }

  bool _live;
  set live(bool v) {
    if (v == _live) return;
    _live = v;
    markNeedsCompositingBitsUpdate();
    markNeedsPaint();
  }

  GlassBackdropState? _backdrop;
  set backdrop(GlassBackdropState? v) {
    if (v == _backdrop) return;
    if (attached) _backdrop?.changes.removeListener(markNeedsPaint);
    _backdrop = v;
    if (attached) _backdrop?.changes.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  bool get _readsBackdrop => _live && ui.ImageFilter.isShaderFilterSupported;

  @override
  bool get alwaysNeedsCompositing => _readsBackdrop;

  final _clipLayer = LayerHandle<ClipRRectLayer>();
  final _filterLayer = LayerHandle<BackdropFilterLayer>();

  @override
  void dispose() {
    _clipLayer.layer = null;
    _filterLayer.layer = null;
    super.dispose();
  }

  // 外面的 Opacity 是独立重绘区,滚动不重画,不自己监听底片会跟着面走。
  ScrollPosition? _scroll;
  set scroll(ScrollPosition? p) {
    if (p == _scroll) return;
    if (attached) _scroll?.removeListener(markNeedsPaint);
    _scroll = p;
    if (attached) _scroll?.addListener(markNeedsPaint);
  }

  // 只靠滚动监听不够:列表不滚、它被别的东西挤走时也得重画。
  static final _alive = <RenderLens>{};
  static bool _hooked = false;
  Offset? _paintedAt;

  static void _sweep(Duration _) {
    for (final r in _alive) {
      if (!r.attached || !r.hasSize || r._paintedAt == null) continue;
      if (r.localToGlobal(Offset.zero) != r._paintedAt) r.markNeedsPaint();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _backdrop?.changes.addListener(markNeedsPaint);
    _scroll?.addListener(markNeedsPaint);
    _alive.add(this);
    if (!_hooked) {
      _hooked = true;
      SchedulerBinding.instance.addPersistentFrameCallback(_sweep);
    }
  }

  @override
  void detach() {
    _alive.remove(this);
    _paintedAt = null;
    _backdrop?.changes.removeListener(markNeedsPaint);
    _scroll?.removeListener(markNeedsPaint);
    _shader?.dispose();
    _shader = null;
    _last?.dispose();
    _last = null;
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final rrect = RRect.fromRectAndRadius(offset & size, Radius.circular(_radius));
    final canvas = context.canvas;
    final dpr = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    _paintedAt = localToGlobal(Offset.zero);
    if (_readsBackdrop) {
      final live = _prepare(dpr, live: true);
      if (live != null) {
        final filter = (_filterLayer.layer ??= BackdropFilterLayer())..filter = ui.ImageFilter.shader(live);
        _clipLayer.layer = context.pushClipRRect(
            needsCompositing,
            offset,
            Offset.zero & size,
            RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(_radius)),
            (ctx, o) => ctx.pushLayer(filter, super.paint, o),
            oldLayer: _clipLayer.layer);
        return;
      }
    }
    final shader = _prepare(dpr, live: false);
    if (shader == null) {
      canvas.drawRRect(rrect, Paint()..color = _tint.withValues(alpha: (_tint.a + .2).clamp(0.0, 1.0)));
    } else {
      // FlutterFragCoord 的原点随所在图层变,必须先画到以这块面左上角为原点的小图再贴回。
      final w = (size.width * dpr).ceil(), h = (size.height * dpr).ceil();
      final rec = ui.PictureRecorder();
      Canvas(rec).drawRect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), Paint()..shader = shader);
      final pic = rec.endRecording();
      final img = pic.toImageSync(w, h);
      pic.dispose();
      canvas.drawImageRect(img, Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), offset & size,
          Paint()..filterQuality = FilterQuality.low);
      // 上屏那帧才真正画出来,马上释放会整块消失,留到下次重画再放。
      _last?.dispose();
      _last = img;
    }
    if (child == null) return;
    context.pushClipRRect(needsCompositing, offset, Offset.zero & size,
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(_radius)), super.paint);
  }

  // 外面套着 BackdropFilter 时,背后画面和 FlutterFragCoord 都以它为原点。
  Offset _passOrigin() {
    for (var n = parent; n != null; n = n.parent) {
      if (n is RenderBackdropFilter) return n.localToGlobal(Offset.zero);
    }
    return Offset.zero;
  }

  static const _ior = 1.5;
  static const _slab = 59.0;
  static const _slope = 2.7;

  // 必须跟 meniscus.frag 的 profileDisp/bend 一致,否则色散分母对不上。
  static double _hs(double t) => math.pow(math.max(0.0, 1 - math.pow(1 - t, 4)), .25).toDouble();
  static double _hc(double t) => math.sqrt(math.max(0.0, 1 - (1 - t) * (1 - t)));

  static double _profile(double d, double bevel) {
    final x = (d / bevel).clamp(0.0, 1.0);
    final x1 = math.min(1.0, x + 1e-3), x0 = math.max(0.0, x - 1e-3);
    final a = math.atan((_hs(x1) - _hs(x0)) / (x1 - x0));
    final b = a.sign * math.asin(math.min(1.0, math.sin(a.abs()) / _ior));
    return (_slab + bevel * _hc(x)) * math.tan(a - b);
  }

  static double _bend(double d, double bevel) {
    final span = math.max(bevel - d, 0.0);
    var m = _slope * span;
    for (var i = 0; i < 24; i++) {
      final s = span * i / 24;
      m = math.min(m, _profile(d + s, bevel) + _slope * s);
    }
    return m;
  }

  ui.FragmentShader? _prepare(double dpr, {required bool live}) {
    final program = LensGlass._program;
    if (program == null || size.isEmpty) return null;
    final img = _backdrop?.image;
    var local = Rect.zero;
    if (!live) {
      final box = _backdrop?.box;
      if (img == null || box == null) return null;
      final wall = _backdrop!.cover(box.size);
      if (wall == null) return null;
      local = wall.shift(-localToGlobal(Offset.zero, ancestor: box));
    }
    final origin = live ? (localToGlobal(Offset.zero) - _passOrigin()) * dpr : Offset.zero;
    final bevel = (size.shortestSide * .3).clamp(4.0, 18.0);
    final s = _shader ??= program.fragmentShader();
    var i = 0;
    void f(double v) => s.setFloat(i++, v);
    f(0);
    f(0);
    f(size.width);
    f(size.height);
    f(origin.dx);
    f(origin.dy);
    f(dpr);
    f(dpr);
    f(local.left);
    f(local.top);
    f(local.width);
    f(local.height);
    f(_radius);
    f(bevel);
    final lensBevel = math.max(1.0, math.min(37.0, (size.shortestSide / 2).floorToDouble() - 1));
    f(_ior);
    f(lensBevel);
    f(_slab);
    f(_slope);
    f(_bend(0, lensBevel));
    f(1.6);
    f(.86);
    f(_tint.r);
    f(_tint.g);
    f(_tint.b);
    f(_tint.a);
    f(1);
    f(1);
    f(-.62);
    f(.79);
    f(live ? 1 : 0);
    if (!live) s.setImageSampler(0, img!);
    return s;
  }
}
