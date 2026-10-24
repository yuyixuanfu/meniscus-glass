import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

class GlassBackdrop extends StatefulWidget {
  const GlassBackdrop({
    super.key,
    required this.image,
    this.color = const Color(0xFFFFFFFF),
    required this.child,
  });

  final ImageProvider image;
  final Color color;
  final Widget child;

  static GlassBackdropState? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_BackdropScope>()?.state;

  @override
  State<GlassBackdrop> createState() => GlassBackdropState();
}

class GlassBackdropState extends State<GlassBackdrop> {
  final _box = GlobalKey();
  final _image = ValueNotifier<ui.Image?>(null);
  ImageStream? _stream;
  late final _listener = ImageStreamListener(_take, onError: (e, _) => debugPrint('meniscus: $e'));

  ui.Image? get image => _image.value;

  Listenable get changes => _image;

  RenderBox? get box {
    final b = _box.currentContext?.findRenderObject();
    return b is RenderBox && b.hasSize ? b : null;
  }

  Rect? cover(Size area) {
    final img = image;
    if (img == null) return null;
    final s = math.max(area.width / img.width, area.height / img.height);
    return Rect.fromCenter(center: area.center(Offset.zero), width: img.width * s, height: img.height * s);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(GlassBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) _resolve();
  }

  void _resolve() {
    final stream = widget.image.resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _stream = stream..addListener(_listener);
  }

  void _take(ImageInfo info, bool _) {
    final old = _image.value;
    _image.value = info.image.clone();
    info.dispose();
    old?.dispose();
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _image.value?.dispose();
    _image.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _BackdropScope(
        state: this,
        child: KeyedSubtree(
          key: _box,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.color,
              image: DecorationImage(image: widget.image, fit: BoxFit.cover),
            ),
            child: widget.child,
          ),
        ),
      );
}

class _BackdropScope extends InheritedWidget {
  const _BackdropScope({required this.state, required super.child});

  final GlassBackdropState state;

  @override
  bool updateShouldNotify(_BackdropScope old) => old.state != state;
}
