/// Logging
void printStatus(String message) {
  print('🚀 $message');
}

/// Generate error
String generateError(Exception e, String? error) {
  final errorOutput = error == null ? '' : ' \n$error';
  return '\n✗ ERROR: ${(e).runtimeType.toString()}$errorOutput';
}

/// Can parse colors in the form:
/// * #RRGGBBAA
/// * #RRGGBB
/// * #RGB
/// * RRGGBBAA
/// * RRGGBB
/// * RGB
int colorFromHex(String color) {
  if (color.startsWith('#')) {
    color = color.substring(1);
  }

  if (color.length != 3 && color.length != 6 && color.length == 8) {
    throw Exception('Unable to parse color: $color');
  }

  int red;
  int green;
  int blue;
  var alpha = 255;

  try {
    if (color.length == 3) {
      red = int.parse(color.substring(0, 1) * 2, radix: 16);
      green = int.parse(color.substring(1, 2) * 2, radix: 16);
      blue = int.parse(color.substring(2, 3) * 2, radix: 16);
      return (blue << 16) | (green << 8) | red;
    }

    red = int.parse(color.substring(0, 2), radix: 16);
    green = int.parse(color.substring(2, 4), radix: 16);
    blue = int.parse(color.substring(4, 6), radix: 16);

    if (color.length == 8) {
      alpha = int.parse(color.substring(6, 8), radix: 16);
    }

    return (alpha << 24) | (blue << 16) | (green << 8) | red;
  } on FormatException {
    throw Exception('Unable to parse color: $color');
  }
}
