import 'dart:async';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:dart_style/dart_style.dart';

class MainStorybookBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => const {
        r'$lib$': ['main_storybook.g.dart']
      };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    print('*** Processing ${buildStep.inputId}');

    final idMap = <String, AssetId>{};

    var i = 0;
    await for (final _assetId
        in buildStep.findAssets(Glob('stories/*.stories.g.dart'))) {
      final libraryPrefix = 's$i';
      idMap[libraryPrefix] = _assetId;
      i++;
    }

    final outputId =
        AssetId(buildStep.inputId.package, 'lib/main_storybook.g.dart');
    final output =
        _outputContents(buildStep.inputId.package, _getStoriesImports(idMap), _getStorybookDataMap(idMap));

    var formatter = DartFormatter();
    var formattedOutput = formatter.format(output);

    await buildStep.writeAsString(outputId, formattedOutput);
  }

  Iterable<String> _getStoriesImports(Map<String, AssetId> idMap) {
    return idMap.entries.map((item) {
      final libraryPrefix = item.key;
      return "import '../${item.value.path}' as $libraryPrefix;";
    });
  }

  Map<String, String> _getStorybookDataMap(Map<String, AssetId> idMap) {
    final _map = <String, String>{};
    for (var item in idMap.entries) {
      final libraryPrefix = item.key;
      final assetId = item.value;
      final key = "'${assetId.package}|${assetId.path}'";
      _map[key] = '$libraryPrefix.storiesData';
    }
    return _map;
  }

  String _outputContents(String packageName,
      Iterable<String> storiesImports, Map<String, String> storybookDataMap) {
    return '''
/// GENERATED BY TOOL - PLEASE DO NOT MODIFY
import 'package:flutter/material.dart';
import 'package:dropsource_storybook/storybook.dart';

${storiesImports.join('\n')}

void main() {
  startStorybook('$packageName', $storybookDataMap);
}

''';
  }
}