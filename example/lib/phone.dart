import 'package:flutter/material.dart';
import 'package:meniscus/meniscus.dart';

import 'look.dart';

const _messages = [
  (false, 'Look at the edge of this bubble.'),
  (true, 'The stripes behind it bend.'),
  (false, 'Only the rim is a lens. The middle stays clear, so text sits on the real backdrop.'),
  (true, 'Red and blue split a little at the very edge.'),
  (false, 'That is dispersion. A fixed 1.6 pixels, like real glass.'),
  (true, 'Short bubbles turn into a lens all the way across.'),
  (false, 'Ok'),
  (true, 'Scroll and watch the backdrop slide under the glass.'),
  (false, 'The bar at the bottom reads whatever is behind it, bubbles included.'),
  (true, 'Even the thin line around the edge picks up the colour beside it.'),
];

class Phone extends StatelessWidget {
  const Phone({super.key, required this.look, this.onSettings});

  final Look look;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final ink = TextStyle(color: look.backdrop.ink, fontSize: 16, height: 1.4);
    return GlassBackdrop(
      image: look.backdrop.image,
      color: look.backdrop.base,
      child: Stack(
        children: [
          ListView.builder(
            padding: EdgeInsets.fromLTRB(16, pad.top + 76, 16, pad.bottom + 96),
            itemCount: _messages.length * 3,
            itemBuilder: (context, i) {
              final (mine, text) = _messages[i % _messages.length];
              return Align(
                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 270),
                    child: LensGlass(
                      radius: look.radius,
                      tint: look.tint,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Text(text, style: ink),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: 16,
            right: 16,
            top: pad.top + 12,
            child: Row(
              children: [
                _Button(look: look, icon: Icons.arrow_back_ios_new),
                const Spacer(),
                LensGlass(
                  radius: 22,
                  tint: look.tint,
                  live: look.live,
                  child: SizedBox(
                    height: 44,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(child: Text('meniscus', style: ink.copyWith(fontWeight: FontWeight.w600))),
                    ),
                  ),
                ),
                const Spacer(),
                if (onSettings != null)
                  _Button(look: look, icon: Icons.tune, onTap: onSettings)
                else
                  const SizedBox(width: 44),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: pad.bottom + 16,
            child: LensGlass(
              radius: 26,
              tint: look.tint,
              live: look.live,
              child: SizedBox(
                height: 52,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text('Message', style: ink.copyWith(color: look.backdrop.ink.withValues(alpha: .55)))),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(Icons.arrow_upward, size: 20, color: look.backdrop.ink),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({required this.look, required this.icon, this.onTap});

  final Look look;
  final IconData icon;
  final VoidCallback? onTap;

  static const size = 44.0;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: LensGlass(
          radius: size / 2,
          tint: look.tint,
          live: look.live,
          child: SizedBox.square(dimension: size, child: Icon(icon, size: size * .42, color: look.backdrop.ink)),
        ),
      );
}
