import 'package:icons_launcher/icon_image.dart';
import 'package:image/image.dart';
import 'package:universal_io/io.dart';

import 'icon_svg.dart';

abstract class Icon {
  const Icon();

  static Icon? loadFile(String filePath) {
    if (filePath.toLowerCase().endsWith('.svg') ||
        filePath.toLowerCase().endsWith('.svgz')) {
      try {
        return IconSvg(filePath);
      } catch (e) {
        return null;
      }
    }
    try {
      return IconImage.loadBytes(File(filePath).readAsBytesSync());
    } catch (e) {
      return null;
    }
  }

  bool get hasAlpha;

  Future<Image> getImage();

  Icon removeAlpha([int backgroundColor = 0xffffff]);

  /// Create a resized copy of this Icon
  Icon copyResized(int iconSize);

  /// Save the resized image to a file
  Future<void> saveResizedPng(int iconSize, String filePath);

  /// Save a list of images to a Windows ico file
  static Future<void> saveIco(List<Icon> icons, String filePath) async {
    final images = <Image>[];
    for (final icon in icons) {
      images.add(await icon.getImage());
    }
    final data = encodeIcoImages(images);
    final file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsBytes(data);
  }
}
