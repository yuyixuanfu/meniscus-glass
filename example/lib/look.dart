import 'package:flutter/widgets.dart';

enum Backdrop {
  sea('Sea', Color(0xFF0D3F8A), Color(0xFFF4F7FB)),
  clouds('Clouds', Color(0xFFC9D2DE), Color(0xFF1F2A38)),
  reef('Reef', Color(0xFF0B2A2A), Color(0xFFF2F7F5)),
  desert('Desert', Color(0xFFB8C2D2), Color(0xFF26303C));

  const Backdrop(this.label, this.base, this.ink);

  final String label;
  final Color base;
  final Color ink;

  AssetImage get image => AssetImage('assets/$name.jpg');
}

@immutable
class Look {
  const Look({this.backdrop = Backdrop.clouds, this.radius = 20, this.film = .05, this.live = true});

  final Backdrop backdrop;
  final double radius;
  final double film;
  final bool live;

  Color get tint => Color.fromRGBO(255, 255, 255, film);

  Look copyWith({Backdrop? backdrop, double? radius, double? film, bool? live}) => Look(
        backdrop: backdrop ?? this.backdrop,
        radius: radius ?? this.radius,
        film: film ?? this.film,
        live: live ?? this.live,
      );
}
