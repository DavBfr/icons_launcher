import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:universal_io/io.dart';

import 'icon.dart';
import 'icon_image.dart';

class IconSvg extends Icon {
  const IconSvg(
    this._filePath, {
    int iconSize = 256,
    bool alpha = true,
    int backgroundColor = 0xffffff,
  })  : _iconSize = iconSize,
        _alpha = alpha,
        _backgroundColor = backgroundColor;

  final String _filePath;

  final int _iconSize;

  final bool _alpha;

  final int _backgroundColor;

  @override
  Future<Image> getImage() async {
    final bytes = await _makePng(_iconSize);
    final image = decodeImage(bytes);
    if (image == null) {
      throw Exception('Unable to load the image');
    }
    return image;
  }

  @override
  bool get hasAlpha => _alpha;

  @override
  IconSvg copyResized(int iconSize) {
    return IconSvg(
      _filePath,
      iconSize: iconSize,
      alpha: hasAlpha,
      backgroundColor: _backgroundColor,
    );
  }

  @override
  Icon removeAlpha([int backgroundColor = 0xffffff]) {
    return IconSvg(
      _filePath,
      iconSize: _iconSize,
      alpha: false,
      backgroundColor: backgroundColor,
    );
  }

  /// Generate a PNG image
  Future<Uint8List> _makePng(int iconSize) async {
    try {
      final process = await Process.start(
        'rsvg-convert',
        [
          '--format',
          'png',
          '--keep-aspect-ratio',
          '--width',
          iconSize.toString(),
          '--height',
          iconSize.toString(),
          _filePath
        ],
      );

      process.stderr.forEach((element) {
        print('STDERR: ${utf8.decode(element)}');
      });

      final code = Completer<int>();
      process.exitCode.then((value) => code.complete(value));

      final data = <int>[];
      await process.stdout.forEach(data.addAll);

      final result = await code.future;

      if (result != 0) {
        throw Exception('Unable to load SVG');
      }

      if (_alpha) {
        return Uint8List.fromList(data);
      }

      final icon = IconImage.loadBytes(Uint8List.fromList(data));
      final alphaIcon = icon.removeAlpha(_backgroundColor);
      return Uint8List.fromList(encodePng(await alphaIcon.getImage()));
    } on ProcessException {
      print(
          '\nUnable to find rsvg-convert.\nSee package documentation on how to install it.\n');
      exit(1);
    }
  }

  /// Save the resized image to a file
  @override
  Future<void> saveResizedPng(int iconSize, String filePath) async {
    final data = await _makePng(iconSize);
    final file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsBytes(data);
  }
}
