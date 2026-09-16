import 'package:flutter/material.dart';

/// Provisional spatial tokens inferred from the reference screenshots.
abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class AppRadii {
  static const small = BorderRadius.all(Radius.circular(10));
  static const medium = BorderRadius.all(Radius.circular(14));
  static const large = BorderRadius.all(Radius.circular(18));
  static const pill = BorderRadius.all(Radius.circular(999));
}

abstract final class AppShadows {
  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x120A1B3D), blurRadius: 16, offset: Offset(0, 6)),
  ];
}
