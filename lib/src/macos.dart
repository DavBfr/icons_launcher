import 'dart:convert';

import 'package:icons_launcher/constants.dart';
import 'package:icons_launcher/utils.dart';
import 'package:universal_io/io.dart';

import '../icon.dart';

/// File to handle the creation of icons for MacOS platform
class MacOSIconTemplate {
  MacOSIconTemplate({required this.size, required this.name});

  final String name;
  final int size;
}

/// List of icons to create
List<MacOSIconTemplate> macosIcons = <MacOSIconTemplate>[
  MacOSIconTemplate(name: '_16', size: 16),
  MacOSIconTemplate(name: '_32', size: 32),
  MacOSIconTemplate(name: '_64', size: 64),
  MacOSIconTemplate(name: '_128', size: 128),
  MacOSIconTemplate(name: '_256', size: 256),
  MacOSIconTemplate(name: '_512', size: 512),
  MacOSIconTemplate(name: '_1024', size: 1024),
];

/// Create the icons
void createIcons(Map<String, dynamic> config, String? flavor) {
  final String filePath = config['image_path_macos'] ?? config['image_path'];
  // decodeImageFile shows error message if null
  // so can return here if image is null
  var image = Icon.loadFile(filePath);
  if (image == null) {
    return;
  }
  if (config['remove_alpha_macos'] is bool && config['remove_alpha_macos']) {
    final color = config['background_color_macos']?.toString() ?? '#ffffff';
    image = image.removeAlpha(colorFromHex(color));
  }
  if (image.hasAlpha) {
    print(
        '\nWARNING: Icons with alpha channel are not allowed in the Apple App Store.\nSet "remove_alpha_macos: true" to remove it.\n');
  }
  String iconName;
  final dynamic macosConfig = config['macos'];
  if (flavor != null) {
    final String catalogName = 'AppIcon-$flavor';
    printStatus('Building MacOS launcher icon for $flavor');
    for (MacOSIconTemplate template in macosIcons) {
      saveNewIcons(template, image, catalogName);
    }
    iconName = macosDefaultIconName;
    changeMacOSIconLauncher(catalogName, flavor);
    modifyContentsFile(catalogName);
  } else if (macosConfig is String) {
    // If the MacOS configuration is a string then the user has specified a new icon to be created
    // and for the old icon file to be kept
    final String newIconName = macosConfig;
    printStatus('Adding new MacOS launcher icon');
    for (MacOSIconTemplate template in macosIcons) {
      saveNewIcons(template, image, newIconName);
    }
    iconName = newIconName;
    changeMacOSIconLauncher(iconName, flavor);
    modifyContentsFile(iconName);
  }
  // Otherwise the user wants the new icon to use the default icons name and
  // update config file to use it
  else {
    printStatus('Overwriting default MacOS launcher icon with new icon');
    for (MacOSIconTemplate template in macosIcons) {
      overwriteDefaultIcons(template, image);
    }
    iconName = macosDefaultIconName;
    changeMacOSIconLauncher('AppIcon', flavor);
  }
}

/// Note: Do not change interpolation unless you end up with better results (see issue for result when using cubic
/// interpolation)
void overwriteDefaultIcons(MacOSIconTemplate template, Icon image) {
  image.saveResizedPng(
    template.size,
    macosDefaultIconFolder + macosDefaultIconName + template.name + '.png',
  );
}

/// Note: Do not change interpolation unless you end up with better results (see issue for result when using cubic
/// interpolation)
void saveNewIcons(MacOSIconTemplate template, Icon image, String newIconName) {
  final String newIconFolder = macosAssetFolder + newIconName + '.appiconset/';
  image.saveResizedPng(
    template.size,
    newIconFolder + newIconName + template.name + '.png',
  );
}

/// Change the launcher icon
Future<void> changeMacOSIconLauncher(String iconName, String? flavor) async {
  final File macOSConfigFile = File(macosConfigFile);
  final List<String> lines = await macOSConfigFile.readAsLines();

  bool onConfigurationSection = false;
  String? currentConfig;

  for (int x = 0; x < lines.length; x++) {
    final String line = lines[x];
    if (line.contains('/* Begin XCBuildConfiguration section */')) {
      onConfigurationSection = true;
    }
    if (line.contains('/* End XCBuildConfiguration section */')) {
      onConfigurationSection = false;
    }
    if (onConfigurationSection) {
      final match = RegExp('.*/\\* (.*)\.xcconfig \\*/;').firstMatch(line);
      if (match != null) {
        currentConfig = match.group(1);
      }

      if (currentConfig != null &&
          (flavor == null || currentConfig.contains('-$flavor')) &&
          line.contains('ASSETCATALOG')) {
        lines[x] = line.replaceAll(RegExp('\=(.*);'), '= $iconName;');
      }
    }
  }

  final String entireFile = lines.join('\n');
  await macOSConfigFile.writeAsString(entireFile);
}

/// Create the Contents.json file
void modifyContentsFile(String newIconName) {
  final String newIconFolder =
      macosAssetFolder + newIconName + '.appiconset/Contents.json';
  File(newIconFolder).create(recursive: true).then((File contentsJsonFile) {
    final String contentsFileContent =
        generateContentsFileAsString(newIconName);
    contentsJsonFile.writeAsString(contentsFileContent);
  });
}

/// Generate the Contents.json file
String generateContentsFileAsString(String newIconName) {
  final Map<String, dynamic> contentJson = <String, dynamic>{
    'images': createImageList(newIconName),
    'info': ContentsInfoObject(version: 1, author: 'xcode').toJson()
  };
  return json.encode(contentJson);
}

class ContentsImageObject {
  ContentsImageObject({
    required this.size,
    required this.idiom,
    required this.filename,
    required this.scale,
  });

  final String size;
  final String idiom;
  final String filename;
  final String scale;

  Map<String, String> toJson() {
    return <String, String>{
      'size': size,
      'idiom': idiom,
      'filename': filename,
      'scale': scale
    };
  }
}

class ContentsInfoObject {
  ContentsInfoObject({required this.version, required this.author});

  final int version;
  final String author;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'author': author,
    };
  }
}

/// Create the image list
List<Map<String, String>> createImageList(String fileNamePrefix) {
  final List<Map<String, String>> imageList = <Map<String, String>>[
    ContentsImageObject(
            size: '16x16',
            idiom: 'mac',
            filename: '${fileNamePrefix}_16.png',
            scale: '1x')
        .toJson(),
    ContentsImageObject(
            size: '16x16',
            idiom: 'mac',
            filename: '${fileNamePrefix}_32.png',
            scale: '2x')
        .toJson(),
    ContentsImageObject(
            size: '32x32',
            idiom: 'mac',
            filename: '${fileNamePrefix}_32.png',
            scale: '1x')
        .toJson(),
    ContentsImageObject(
            size: '32x32',
            idiom: 'mac',
            filename: '${fileNamePrefix}_64.png',
            scale: '2x')
        .toJson(),
    ContentsImageObject(
            size: '128x128',
            idiom: 'mac',
            filename: '${fileNamePrefix}_128.png',
            scale: '1x')
        .toJson(),
    ContentsImageObject(
            size: '128x128',
            idiom: 'mac',
            filename: '${fileNamePrefix}_256.png',
            scale: '2x')
        .toJson(),
    ContentsImageObject(
            size: '256x256',
            idiom: 'mac',
            filename: '${fileNamePrefix}_256.png',
            scale: '1x')
        .toJson(),
    ContentsImageObject(
            size: '256x256',
            idiom: 'mac',
            filename: '${fileNamePrefix}_512.png',
            scale: '2x')
        .toJson(),
    ContentsImageObject(
            size: '512x512',
            idiom: 'mac',
            filename: '${fileNamePrefix}_512.png',
            scale: '1x')
        .toJson(),
    ContentsImageObject(
            size: '512x512',
            idiom: 'mac',
            filename: '${fileNamePrefix}_1024.png',
            scale: '2x')
        .toJson(),
  ];
  return imageList;
}
