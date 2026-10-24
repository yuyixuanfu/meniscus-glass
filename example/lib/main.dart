import 'package:flutter/material.dart';
import 'package:meniscus/meniscus.dart';

import 'showcase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LensGlass.load();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'meniscus',
    theme: ThemeData(colorSchemeSeed: const Color(0xFF5B7A99), useMaterial3: true),
    home: const Showcase(),
  ));
}
