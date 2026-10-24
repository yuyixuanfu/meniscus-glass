import 'package:flutter/material.dart';
import 'package:meniscus/meniscus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LensGlass.load();
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: Demo()));
}

class Demo extends StatelessWidget {
  const Demo({super.key});

  static const _ink = TextStyle(color: Color(0xFF26303C), fontSize: 16, height: 1.4);

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      body: GlassBackdrop(
        image: const AssetImage('assets/backdrop.png'),
        child: Stack(
          children: [
            ListView.builder(
              padding: EdgeInsets.fromLTRB(16, pad.top + 72, 16, pad.bottom + 96),
              itemCount: 40,
              itemBuilder: (context, i) {
                final mine = i.isOdd;
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: LensGlass(
                        radius: 20,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Text(mine ? 'Liquid glass $i' : 'The backdrop bends at the edge.', style: _ink),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              left: 16,
              top: pad.top + 12,
              child: const LensGlass(
                radius: 22,
                live: true,
                child: SizedBox(width: 44, height: 44, child: Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF26303C))),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: pad.bottom + 16,
              child: const LensGlass(
                radius: 26,
                live: true,
                child: SizedBox(
                  height: 52,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: Align(alignment: Alignment.centerLeft, child: Text('Message', style: _ink)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
