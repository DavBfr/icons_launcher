import 'package:icons_launcher/constants.dart' as constants;
import 'package:icons_launcher/custom_exceptions.dart';
import 'package:icons_launcher/utils.dart';
import 'package:icons_launcher/xml_templates.dart' as xml_template;
import 'package:universal_io/io.dart';

import '../icon.dart';

/// Class android icon template model
class AndroidIconTemplate {
  AndroidIconTemplate({required this.size, required this.directoryName});

  final String directoryName;
  final int size;
}

/// List of android adaptive icon templates
final List<AndroidIconTemplate> adaptiveForegroundIcons = <AndroidIconTemplate>[
  AndroidIconTemplate(directoryName: 'mipmap-mdpi', size: 108),
  AndroidIconTemplate(directoryName: 'mipmap-hdpi', size: 162),
  AndroidIconTemplate(directoryName: 'mipmap-xhdpi', size: 216),
  AndroidIconTemplate(directoryName: 'mipmap-xxhdpi', size: 324),
  AndroidIconTemplate(directoryName: 'mipmap-xxxhdpi', size: 432),
];

/// List of android icon templates
List<AndroidIconTemplate> androidIcons = <AndroidIconTemplate>[
  AndroidIconTemplate(directoryName: 'mipmap-mdpi', size: 48),
  AndroidIconTemplate(directoryName: 'mipmap-hdpi', size: 72),
  AndroidIconTemplate(directoryName: 'mipmap-xhdpi', size: 96),
  AndroidIconTemplate(directoryName: 'mipmap-xxhdpi', size: 144),
  AndroidIconTemplate(directoryName: 'mipmap-xxxhdpi', size: 192),
];

/// Create default icons
void createDefaultIcons(
    Map<String, dynamic> iconsLauncherConfig, String? flavor) {
  printStatus('Creating default icons Android');
  final String filePath = getAndroidIconPath(iconsLauncherConfig);
  final image = Icon.loadFile(filePath);
  if (image == null) {
    return;
  }
  final File androidManifestFile = File(constants.androidManifestFile);
  if (isCustomAndroidFile(iconsLauncherConfig)) {
    printStatus('Adding a new Android launcher icon');
    final String iconName = getNewIconName(iconsLauncherConfig);
    isAndroidIconNameCorrectFormat(iconName);
    final String iconPath = '$iconName.png';
    for (AndroidIconTemplate template in androidIcons) {
      saveNewImages(template, image, iconPath, flavor);
    }
    overwriteAndroidManifestWithNewIconLauncher(iconName, androidManifestFile);
    if (isConfigAdaptiveRoundIcon(iconsLauncherConfig)) {
      overwriteAndroidManifestWithNewRoundIconLauncher(
          iconName, androidManifestFile);
    }
  } else {
    printStatus(
        'Overwriting the default Android launcher icon with a new icon');
    for (AndroidIconTemplate template in androidIcons) {
      overwriteExistingIcons(
          template, image, constants.androidFileName, flavor);
    }
    overwriteAndroidManifestWithNewIconLauncher(
        constants.androidDefaultIconName, androidManifestFile);
    if (isConfigAdaptiveRoundIcon(iconsLauncherConfig)) {
      overwriteAndroidManifestWithNewRoundIconLauncher(
          constants.androidDefaultRoundIconName, androidManifestFile);
    }
  }
  // Create play store icon
  createPlayStoreIcon(image, flavor);
  removeConflictDir();
}

void removeConflictDir() {
  try {
    final dir = Directory('android/app/src/main/res/drawable-anydpi-v21');
    dir.deleteSync(recursive: true);
  } catch (_) {}
}

/// Create play store icon
void createPlayStoreIcon(Icon image, String? flavor) {
  final template = AndroidIconTemplate(
      directoryName: constants.androidMainFolder(flavor), size: 512);
  image.saveResizedPng(template.size,
      template.directoryName + constants.androidPlayStoreFileName);
}

/// Ensures that the Android icon name is in the correct format
bool isAndroidIconNameCorrectFormat(String iconName) {
  // assure the icon only consists of lowercase letters, numbers and underscore
  if (!RegExp(r'^[a-z0-9_]+$').hasMatch(iconName)) {
    throw const InvalidAndroidIconNameException(
        constants.errorIncorrectIconName);
  }
  return true;
}

/// Create adaptive icons
void createAdaptiveIcons(
    Map<String, dynamic> iconsLauncherConfig, String? flavor) {
  printStatus('Creating adaptive icons Android');

  // Retrieve the necessary launcher icons configuration from the pubspec.yaml file
  final String backgroundConfig =
      iconsLauncherConfig['adaptive_icon_background'];
  final String foregroundImagePath =
      iconsLauncherConfig['adaptive_icon_foreground'];
  final String? roundImagePath = iconsLauncherConfig['adaptive_icon_round'];
  final foregroundImage = Icon.loadFile(foregroundImagePath);
  if (foregroundImage == null) {
    return;
  }

  // Create adaptive icon foreground images
  for (AndroidIconTemplate androidIcon in adaptiveForegroundIcons) {
    overwriteExistingIcons(androidIcon, foregroundImage,
        constants.androidAdaptiveForegroundFileName, flavor);
  }

  // Create adaptive icon background
  if (isAdaptiveIconConfigPngFile(backgroundConfig)) {
    createAdaptiveBackgrounds(iconsLauncherConfig, backgroundConfig, flavor);
  } else {
    createAdaptiveIconMipMapXmlFile(iconsLauncherConfig, flavor);
    if (isConfigAdaptiveRoundIcon(iconsLauncherConfig)) {
      createAdaptiveRoundIconMipMapXmlFile(iconsLauncherConfig, flavor);
    }
    updateColorsXmlFile(backgroundConfig, flavor);
  }

  if (roundImagePath != null) {
    final roundImage = Icon.loadFile(roundImagePath);
    if (roundImage != null) {
      for (AndroidIconTemplate androidIcon in androidIcons) {
        overwriteExistingRoundIcons(
            androidIcon, roundImage, constants.androidRoundFileName, flavor);
      }
    }
  }
}

/// Retrieves the colors.xml file for the project.
///
/// If the colors.xml file is found, it is updated with a new color item for the
/// adaptive icon background.
///
/// If not, the colors.xml file is created and a color item for the adaptive icon
/// background is included in the new colors.xml file.
void updateColorsXmlFile(String backgroundConfig, String? flavor) {
  final File colorsXml = File(constants.androidColorsFile(flavor));
  if (colorsXml.existsSync()) {
    printStatus('Updating colors.xml with color for adaptive icon background');
    updateColorsFile(colorsXml, backgroundConfig);
  } else {
    printStatus('No colors.xml file found in your Android project');
    printStatus(
        'Creating colors.xml file and adding it to your Android project');
    createNewColorsFile(backgroundConfig, flavor);
  }
}

/// Creates the xml file required for the adaptive launcher icon
/// FILE LOCATED HERE: res/mipmap-anydpi/{icon-name-from-yaml-config}.xml
void createAdaptiveIconMipMapXmlFile(
    Map<String, dynamic> iconsLauncherConfig, String? flavor) {
  if (isCustomAndroidFile(iconsLauncherConfig)) {
    File(constants.androidAdaptiveXmlFolder(flavor) +
            getNewIconName(iconsLauncherConfig) +
            '.xml')
        .create(recursive: true)
        .then((File adaptiveIcon) {
      adaptiveIcon.writeAsString(xml_template.icLauncherXml);
    });
  } else {
    File(constants.androidAdaptiveXmlFolder(flavor) +
            constants.androidDefaultIconName +
            '.xml')
        .create(recursive: true)
        .then((File adaptiveIcon) {
      adaptiveIcon.writeAsString(xml_template.icLauncherXml);
    });
  }
}

/// Creates the xml file for the adaptive launcher round icon
/// FILE LOCATED HERE: res/mipmap-anydpi/{icon-name-from-yaml-config}.xml
void createAdaptiveRoundIconMipMapXmlFile(
    Map<String, dynamic> iconsLauncherConfig, String? flavor) {
  if (isCustomAndroidFile(iconsLauncherConfig)) {
    File(constants.androidAdaptiveXmlFolder(flavor) +
            getNewIconName(iconsLauncherConfig) +
            '_round.xml')
        .create(recursive: true)
        .then((File adaptiveIcon) {
      adaptiveIcon.writeAsString(xml_template.icLauncherRoundXml);
    });
  } else {
    File(constants.androidAdaptiveXmlFolder(flavor) +
            constants.androidDefaultIconName +
            '_round.xml')
        .create(recursive: true)
        .then((File adaptiveIcon) {
      adaptiveIcon.writeAsString(xml_template.icLauncherRoundXml);
    });
  }
}

/// creates adaptive background using png image
void createAdaptiveBackgrounds(Map<String, dynamic> yamlConfig,
    String adaptiveIconBackgroundImagePath, String? flavor) {
  final String filePath = adaptiveIconBackgroundImagePath;
  final image = Icon.loadFile(filePath);
  if (image == null) {
    return;
  }

  // creates a png image (ic_adaptive_background.png) for the adaptive icon background in each of the locations
  // it is required
  for (AndroidIconTemplate androidIcon in adaptiveForegroundIcons) {
    saveNewImages(androidIcon, image,
        constants.androidAdaptiveBackgroundFileName, flavor);
  }

  // Creates the xml file required for the adaptive launcher icon
  // FILE LOCATED HERE:  res/mipmap-anydpi/{icon-name-from-yaml-config}.xml
  if (isCustomAndroidFile(yamlConfig)) {
    File(constants.androidAdaptiveXmlFolder(flavor) +
            getNewIconName(yamlConfig) +
            '.xml')
        .create(recursive: true)
        .then((File adaptiveIcon) {
      adaptiveIcon.writeAsString(xml_template.icLauncherMipMapXml);
    });

    if (isConfigAdaptiveRoundIcon(yamlConfig)) {
      File(constants.androidAdaptiveXmlFolder(flavor) +
              getNewIconName(yamlConfig) +
              '_round.xml')
          .create(recursive: true)
          .then((File adaptiveIcon) {
        adaptiveIcon.writeAsString(xml_template.icLauncherRoundMipMapXml);
      });
    }
  } else {
    File(constants.androidAdaptiveXmlFolder(flavor) +
            constants.androidDefaultIconName +
            '.xml')
        .create(recursive: true)
        .then((File adaptiveIcon) {
      adaptiveIcon.writeAsString(xml_template.icLauncherMipMapXml);
    });
    if (isConfigAdaptiveRoundIcon(yamlConfig)) {
      File(constants.androidAdaptiveXmlFolder(flavor) +
              constants.androidDefaultIconName +
              '_round.xml')
          .create(recursive: true)
          .then((File adaptiveIcon) {
        adaptiveIcon.writeAsString(xml_template.icLauncherRoundMipMapXml);
      });
    }
  }
}

/// Creates a colors.xml file if it was missing from android/app/src/main/res/values/colors.xml
void createNewColorsFile(String backgroundColor, String? flavor) {
  File(constants.androidColorsFile(flavor))
      .create(recursive: true)
      .then((File colorsFile) {
    colorsFile.writeAsString(xml_template.colorsXml).then((File file) {
      updateColorsFile(colorsFile, backgroundColor);
    });
  });
}

/// Updates the colors.xml with the new adaptive launcher icon color
void updateColorsFile(File colorsFile, String backgroundColor) {
  // Write foreground color
  final List<String> lines = colorsFile.readAsLinesSync();
  bool foundExisting = false;
  for (int x = 0; x < lines.length; x++) {
    String line = lines[x];
    if (line.contains('name="ic_launcher_background"')) {
      foundExisting = true;
      // replace anything between tags which does not contain another tag
      line = line.replaceAll(RegExp(r'>([^><]*)<'), '>$backgroundColor<');
      lines[x] = line;
      break;
    }
  }

  // Add new line if we didn't find an existing value
  if (!foundExisting) {
    lines.insert(lines.length - 1,
        '\t<color name="ic_launcher_background">$backgroundColor</color>');
  }

  colorsFile.writeAsStringSync(lines.join('\n'));
}

/// Check to see if specified Android config is a string or bool
/// String - Generate new launcher icon with the string specified
/// bool - override the default flutter project icon
bool isCustomAndroidFile(Map<String, dynamic> config) {
  final dynamic androidConfig = config['android'];
  return androidConfig is String;
}

/// Check to see if specified Android adaptive round icon
bool isConfigAdaptiveRoundIcon(Map<String, dynamic> config) {
  final String? roundImagePath = config['adaptive_icon_round'];
  return roundImagePath != null;
}

/// return the new launcher icon file name
String getNewIconName(Map<String, dynamic> config) {
  return config['android'];
}

/// Overrides the existing launcher icons in the project
/// Note: Do not change interpolation unless you end up with better results (see issue for result when using cubic
/// interpolation)
void overwriteExistingIcons(
  AndroidIconTemplate template,
  Icon image,
  String filename,
  String? flavor,
) {
  image.saveResizedPng(
    template.size,
    constants.androidResFolder(flavor) +
        template.directoryName +
        '/' +
        filename,
  );
}

/// Overrides the existing launcher round icons in the project
/// Note: Do not change interpolation unless you end up with better results (see issue for result when using cubic
/// interpolation)
void overwriteExistingRoundIcons(
  AndroidIconTemplate template,
  Icon image,
  String filename,
  String? flavor,
) {
  image.saveResizedPng(
    template.size,
    constants.androidResFolder(flavor) +
        template.directoryName +
        '/' +
        filename,
  );
}

/// Saves new launcher icons to the project, keeping the old launcher icons.
/// Note: Do not change interpolation unless you end up with better results
void saveNewImages(AndroidIconTemplate template, Icon image,
    String iconFilePath, String? flavor) {
  image.saveResizedPng(
    template.size,
    constants.androidResFolder(flavor) +
        template.directoryName +
        '/' +
        iconFilePath,
  );
}

/// Updates the line which specifies the launcher icon within the AndroidManifest.xml
/// with the new icon name (only if it has changed)
///
/// Note: default iconName = "ic_launcher"
Future<void> overwriteAndroidManifestWithNewIconLauncher(
    String iconName, File androidManifestFile) async {
  // we do not use `file.readAsLinesSync()` here because that always gets rid of the last empty newline
  final List<String> oldManifestLines =
      (await androidManifestFile.readAsString()).split('\n');
  final List<String> transformedLineIcon =
      transformAndroidManifestWithNewIconLauncher(oldManifestLines, iconName);
  await androidManifestFile.writeAsString(transformedLineIcon.join('\n'));
}

/// Updates only the line containing android:icon with the specified iconName
List<String> transformAndroidManifestWithNewIconLauncher(
    List<String> oldManifestLines, String iconName) {
  return oldManifestLines.map((String line) {
    if (line.contains('android:icon')) {
      // Using RegExp replace the value of android:icon to point to the new icon
      // anything but a quote of any length: [^"]*
      // an escaped quote: \\" (escape slash, because it exists regex)
      // quote, no quote / quote with things behind : \"[^"]*
      // repeat as often as wanted with no quote at start: [^"]*(\"[^"]*)*
      // escaping the slash to place in string: [^"]*(\\"[^"]*)*"
      // result: any string which does only include escaped quotes
      return line.replaceAll(RegExp(r'android:icon="[^"]*(\\"[^"]*)*"'),
          'android:icon="@mipmap/$iconName"');
    } else {
      return line;
    }
  }).toList();
}

/// Updates the line which specifies the launcher round icon within the AndroidManifest.xml
/// with the new icon name (only if it has changed)
///
/// Note: default iconName = "ic_launcher_round"
Future<void> overwriteAndroidManifestWithNewRoundIconLauncher(
    String iconName, File androidManifestFile) async {
  // we do not use `file.readAsLinesSync()` here because that always gets rid of the last empty newline
  final List<String> oldManifestLines =
      (await androidManifestFile.readAsString()).split('\n');
  final List<String> transformedLineIconRound =
      transformAndroidManifestWithNewRoundIconLauncher(
          oldManifestLines, iconName);
  await androidManifestFile.writeAsString(transformedLineIconRound.join('\n'));
}

/// Updates only the line containing android:roundIcon with the specified iconName
List<String> transformAndroidManifestWithNewRoundIconLauncher(
    List<String> oldManifestLines, String iconName) {
  bool isRoundIconExisting = false;
  final newManifest = oldManifestLines.map((String line) {
    if (line.contains('android:roundIcon')) {
      // Using RegExp replace the value of android:roundIcon to point to the new icon
      // anything but a quote of any length: [^"]*
      // an escaped quote: \\" (escape slash, because it exists regex)
      // quote, no quote / quote with things behind : \"[^"]*
      // repeat as often as wanted with no quote at start: [^"]*(\"[^"]*)*
      // escaping the slash to place in string: [^"]*(\\"[^"]*)*"
      // result: any string which does only include escaped quotes
      isRoundIconExisting = true;
      return line.replaceAll(RegExp(r'android:roundIcon="[^"]*(\\"[^"]*)*"'),
          'android:roundIcon="@mipmap/$iconName"');
    } else {
      return line;
    }
  }).toList();

  if (isRoundIconExisting) {
    return newManifest;
  } else {
    print('Adding android:roundIcon to manifest');
    return oldManifestLines.map((String line) {
      if (line.contains('android:icon')) {
        final addLines =
            '''android:icon="@mipmap/${constants.androidDefaultIconName}"
        android:roundIcon="@mipmap/$iconName"''';
        return line.replaceAll(
            RegExp(r'android:icon="[^"]*(\\"[^"]*)*"'), addLines);
      } else {
        return line;
      }
    }).toList();
  }
}

/// File reader
List<String> readFileLinesSync(String file) => File(file).readAsLinesSync();

/// Retrieves the flutter sdk path
String flutterSdk() {
  final lines = readFileLinesSync(constants.androidLocalProperties);
  const key = 'flutter.sdk=';
  for (String line in lines) {
    if (line.contains(key)) {
      // Remove the key and return the flutter sdk path
      return line.replaceAll(key, '').trim();
    }
  }
  return '';
}

/// Retrieves the string number only
String? getLineValueNumber(List<String> lines, String key) {
  for (String line in lines) {
    if (line.contains(key)) {
      final value = line.replaceAll(RegExp(r'[^\d]'), '').trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
  }
  return null;
}

/// Retrieves the minSdk value from the Android build.gradle file
int minSdk() {
  String? minSdkValue;

  final File androidGradleFile = File(constants.androidGradleFile);
  final androidLines = androidGradleFile.readAsLinesSync();

  //! First try -> app/build.gradle file
  const androidLineKey = 'minSdkVersion';
  minSdkValue = getLineValueNumber(androidLines, androidLineKey);

  //! Second try -> local.properties
  if (minSdkValue == null) {
    final localLines = readFileLinesSync(constants.androidLocalProperties);
    const localKey = 'flutter.minSdkVersion=';
    minSdkValue = getLineValueNumber(localLines, localKey);
  }

  //! Third try -> flutter.gradle file (default flutter sdk)
  if (minSdkValue == null) {
    final gradleFile = '${flutterSdk()}${constants.flutterSdkGradleFile}';
    final List<String> flutterLines = readFileLinesSync(gradleFile);
    const flutterLineKey = 'minSdkVersion =';
    minSdkValue = getLineValueNumber(flutterLines, flutterLineKey);
  }

  return int.tryParse(minSdkValue ?? '0') ?? 0;
}

/// Method for the retrieval of the Android icon path
/// If image_path_android is found, this will be priorities over the image_path
/// value.
String getAndroidIconPath(Map<String, dynamic> config) {
  return config['image_path_android'] ?? config['image_path'];
}

/// Returns true if the adaptive icon configuration is a PNG image
bool isAdaptiveIconConfigPngFile(String backgroundFile) {
  return backgroundFile.endsWith('.png');
}

/// (NOTE THIS IS JUST USED FOR UNIT TEST)
/// Ensures the correct path is used for generating adaptive icons
/// "Next you must create alternative drawable resources in your app for use with
/// Android 8.0 (API level 26) in res/mipmap-anydpi/ic_launcher.xml"
/// Source: https://developer.android.com/guide/practices/ui_guidelines/icon_design_adaptive
bool isCorrectMipMapDirectoryForAdaptiveIcon(String path) {
  return path == 'android/app/src/main/res/mipmap-anydpi-v26/';
}
