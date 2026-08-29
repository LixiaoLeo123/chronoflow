import 'dart:math' as math;

const selectableActivityColors = <int>[
  0xFF2563EB,
  0xFF0EA5E9,
  0xFF06B6D4,
  0xFF10B981,
  0xFF22C55E,
  0xFF84CC16,
  0xFFEAB308,
  0xFFF97316,
  0xFFEF4444,
  0xFFEC4899,
  0xFFD946EF,
  0xFFA855F7,
  0xFF8B5CF6,
  0xFF6366F1,
  0xFF64748B,
  0xFF78716C,
];

int randomDistinctColor(List<int> used, {math.Random? random}) {
  final source = random ?? math.Random();
  final candidates = <int>[];
  for (var index = 0; index < 64; index++) {
    final hue = source.nextDouble() * 360;
    final saturation = 0.52 + source.nextDouble() * 0.34;
    final value = 0.62 + source.nextDouble() * 0.30;
    candidates.add(_colorFromHsv(hue, saturation, value));
  }
  if (used.isEmpty) return candidates.first;
  double distanceFrom(int color) {
    final red = (color >> 16) & 0xFF;
    final green = (color >> 8) & 0xFF;
    final blue = color & 0xFF;
    final distances = used.map((other) {
      final redDifference = ((other >> 16) & 0xFF) - red;
      final greenDifference = ((other >> 8) & 0xFF) - green;
      final blueDifference = (other & 0xFF) - blue;
      return math.sqrt(
        math.pow(redDifference, 2) +
            math.pow(greenDifference, 2) +
            math.pow(blueDifference, 2),
      );
    }).toList();
    return distances.reduce(math.min);
  }

  candidates.sort((left, right) => distanceFrom(right).compareTo(distanceFrom(left)));
  return candidates.first;
}

int _colorFromHsv(double hue, double saturation, double value) {
  final chroma = value * saturation;
  final secondary = chroma * (1 - ((hue / 60) % 2 - 1).abs());
  final match = value - chroma;
  final (red, green, blue) = switch ((hue ~/ 60) % 6) {
    0 => (chroma, secondary, 0.0),
    1 => (secondary, chroma, 0.0),
    2 => (0.0, chroma, secondary),
    3 => (0.0, secondary, chroma),
    4 => (secondary, 0.0, chroma),
    _ => (chroma, 0.0, secondary),
  };
  return 0xFF000000 |
      ((255 * (red + match)).round() << 16) |
      ((255 * (green + match)).round() << 8) |
      (255 * (blue + match)).round();
}
