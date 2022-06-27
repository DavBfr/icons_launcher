import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:universal_io/io.dart';

import 'icon.dart';

class IconImage extends Icon {
  const IconImage(this._image);

  factory IconImage.loadBytes(Uint8List bytes) {
    final image = decodeImage(bytes);
    if (image == null) {
      throw Exception('Unable to load image');
    }

    return IconImage(image);
  }

  final Image _image;

  @override
  Future<Image> getImage() async => _image;

  @override
  bool get hasAlpha => _image.channels == Channels.rgba;

  @override
  Icon removeAlpha([int backgroundColor = 0xffffff]) {
    final result = Image.rgb(_image.width, _image.height);
    fill(result, backgroundColor);
    drawImage(result, _image);
    return IconImage(result);
  }

  @override
  IconImage copyResized(int iconSize) {
    // Note: Do not change interpolation unless you end up with better results
    // (see issue for result when using cubic interpolation)
    if (_image.width >= iconSize) {
      return IconImage(copyResize(
        _image,
        width: iconSize,
        height: iconSize,
        interpolation: Interpolation.average,
      ));
    } else {
      return IconImage(copyResize(
        _image,
        width: iconSize,
        height: iconSize,
        interpolation: Interpolation.linear,
      ));
    }
  }

  /// Save the resized image to a file
  @override
  Future<void> saveResizedPng(int iconSize, String filePath) async {
    final data = encodePng(copyResized(iconSize)._image);
    final file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsBytes(data);
  }
}
