import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'look.dart';
import 'phone.dart';

class Showcase extends StatefulWidget {
  const Showcase({super.key});

  @override
  State<Showcase> createState() => _ShowcaseState();
}

class _ShowcaseState extends State<Showcase> {
  final _look = ValueNotifier(const Look());

  @override
  void dispose() {
    _look.dispose();
    super.dispose();
  }

  void _openSettings() => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Controls(look: _look),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: LayoutBuilder(builder: (context, box) {
          if (box.maxWidth < 760) {
            return ValueListenableBuilder(
              valueListenable: _look,
              builder: (_, look, _) => Phone(look: look, onSettings: _openSettings),
            );
          }
          final h = math.min(box.maxHeight - 48, 844.0);
          final w = h * 390 / 844;
          return ColoredBox(
            color: const Color(0xFFEDEEF1),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Container(
                      width: w,
                      height: h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(44),
                        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 40, offset: Offset(0, 16))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(44),
                        child: MediaQuery(
                          data: MediaQuery.of(context).copyWith(padding: const EdgeInsets.only(top: 44, bottom: 24)),
                          child: ValueListenableBuilder(
                            valueListenable: _look,
                            builder: (_, look, _) => Phone(look: look),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 340,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 48, 32, 32),
                    child: Controls(look: _look, header: true),
                  ),
                ),
              ],
            ),
          );
        }),
      );
}

class Controls extends StatelessWidget {
  const Controls({super.key, required this.look, this.header = false});

  final ValueNotifier<Look> look;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final liveSupported = ui.ImageFilter.isShaderFilterSupported;
    return ValueListenableBuilder(
      valueListenable: look,
      builder: (context, l, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header) ...[
            Text('meniscus', style: text.headlineMedium),
            const SizedBox(height: 4),
            Text('Liquid glass for Flutter. The rim bends what is behind it; the middle stays clear.',
                style: text.bodyMedium),
            const SizedBox(height: 28),
          ],
          Text('Backdrop', style: text.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final b in Backdrop.values)
                ChoiceChip(
                  label: Text(b.label),
                  selected: l.backdrop == b,
                  onSelected: (_) => look.value = l.copyWith(backdrop: b),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Corner radius  ${l.radius.round()}', style: text.labelLarge),
          Slider(min: 8, max: 32, value: l.radius, onChanged: (v) => look.value = l.copyWith(radius: v)),
          Text('Film  ${(l.film * 100).round()}%', style: text.labelLarge),
          Slider(min: 0, max: .3, value: l.film, onChanged: (v) => look.value = l.copyWith(film: v)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Read the live backdrop'),
            subtitle: Text(liveSupported
                ? 'Top bar and input bar bend whatever scrolls behind them.'
                : 'Not available on this renderer. Floating glass bends the backdrop image instead.'),
            value: l.live && liveSupported,
            onChanged: liveSupported ? (v) => look.value = l.copyWith(live: v) : null,
          ),
        ],
      ),
    );
  }
}
