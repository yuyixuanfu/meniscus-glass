import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meniscus/meniscus.dart';

Future<Uint8List> _png() async {
  final rec = ui.PictureRecorder();
  Canvas(rec).drawRect(const Rect.fromLTWH(0, 0, 2, 2), Paint()..color = const Color(0xFF6688AA));
  final img = await rec.endRecording().toImage(2, 2);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  img.dispose();
  return bytes!.buffer.asUint8List();
}

void main() {
  testWidgets('不在 GlassBackdrop 里、着色器没加载时画平膜,不报错', (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: SizedBox(width: 120, height: 48, child: LensGlass(child: Text('x')))),
    ));
    expect(find.text('x'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('GlassBackdrop 底下能拿到它,解码后有图和铺法', (tester) async {
    late GlassBackdropState? scope;
    await tester.runAsync(() async {
      final png = await _png();
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: GlassBackdrop(
          image: MemoryImage(png),
          child: Builder(builder: (context) {
            scope = GlassBackdrop.maybeOf(context);
            return const SizedBox.expand(child: LensGlass(live: true));
          }),
        ),
      ));
      for (var i = 0; i < 20 && scope?.image == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pump();
    expect(scope, isNotNull);
    expect(scope!.image, isNotNull);
    expect(scope!.cover(const Size(200, 100)), const Rect.fromLTWH(0, -50, 200, 200));
    expect(tester.takeException(), isNull);
  });
}
